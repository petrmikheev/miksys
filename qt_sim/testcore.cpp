#include "testcore.h"
#include <cstdio>
#include <QDir>
#include <ctime>
#include <assert.h>

enum opcodes {
    NOP = 0x0,
    JUMP = 0x1,
    CMOV = 0x2,
    CCMOV = 0x3,

    MUL = 0xe,
    RW = 0xf,
    OR = 0x10,
    XOR = 0x11,
    AND = 0x12,
    TST = 0x13,
    MOV = 0x14,
    WMOV = 0x15,

    ADD = 0x18,
    RSB = 0x19,
    SUB = 0x1a,
    CMP = 0x1b,
    ADC = 0x1c,
    RSC = 0x1d,
    SBC = 0x1e
};

TestCore::TestCore(MIKSYS* system, char* filename) {
    this->system = system;
    FILE* p = fopen(filename, "rb");
    assert(fread(prog, 4, PROG_SIZE, p) == 1);
    fclose(p);
    reset();
}

void TestCore::reset() {
    ip = 0;
    opcode = cond = next_command = command = a = waddr = raddr = 0;
    jmp = jmp_ret = jmp_call = jmp_reg = wr_reg = wr_cache = wr_sreg = set_flags = rd_cache = false;
    p2 = 0;
    system->vga_control_index = 0;
    memset(system->vga_control, 0, 8);
    system->vga_control[5] = 128;
    system->vga_control[2] = 128;
}

bool TestCore::check_cond(unsigned int cond) {
    bool N = in_flags & 1;
    bool Z = in_flags & 2;
    bool V = in_flags & 4;
    bool C = in_flags & 8;
    switch (cond) {
        case 0: return true;
        case 1: return Z;
        case 2: return !Z;
        case 3: return C;
        case 4: return !C;
        case 5: return N;
        case 6: return !N;
        case 7: return V;
        case 8: return !V;
        case 9: return C && !Z;
        case 10: return !C || Z;
        case 11: return N == V;
        case 12: return N != V;
        case 13: return !Z && N == V;
        case 14: return Z && N != V;
        case 15: return false;
    }
    return false;
}

void TestCore::handleNext() {
    in_time = (int)time(NULL) * 1000;
    if (system->buttonState)
        in_flags |= 1 << 4;
    else
        in_flags &= ~(1 << 4);
    if (ram_count > 0)
        in_flags |= 1 << 5;
    else
        in_flags &= ~(1 << 5);

    if (ram_count > 0) {
        if (ram_write)
            system->memory[ram_addr] = cache[ram_cache_addr];
        else
            cache[ram_cache_addr] = system->memory[ram_addr];
        ram_addr = (ram_addr + 1) % MIKSYS::MEM_SIZE;
        ram_cache_addr = (ram_cache_addr + 1) % CACHE_SIZE;
        ram_count--;
    }

    // Temporary variables
    unsigned int st2_opcode;
    unsigned int st2_a;
    unsigned int st2_r;
    unsigned int st2_c;
    unsigned int st2_rr;
    bool st2_jump, st2_mov;

    unsigned int st3_opcode;
    bool st3_inv1, st3_inv2, st3_jump, st3_mov, st3_cmov, st3_ccmov, st3_test;
    bool st3_jmp_call, st3_jmp_reg;
    unsigned int st3_a;
    unsigned int st3_b;
    unsigned int st3_c;
    unsigned int st3_p2 = 0;
    unsigned int st3_rb;

    unsigned int st4_arg1, st4_arg2;
    unsigned int st4_res;
    bool st4_carry;
    bool new_cond;

    unsigned int _ip;

    // stage 4
    new_cond = check_cond(cond);
    st4_arg1 = p1;
    st4_arg2 = inv2 ? (~p2)&0xffff : p2&0xffff;
    switch (opcode) {
        case AND:
        case TST: { st4_carry = 0; st4_res = st4_arg1 & st4_arg2; } break;
        case OR: { st4_carry = 0; st4_res = st4_arg1 | st4_arg2; } break;
        case XOR: { st4_carry = 0; st4_res = st4_arg1 ^ st4_arg2; } break;
        case 0x18:case 0x19:case 0x1a:case 0x1b:case 0x1c:case 0x1d:case 0x1e:case 0x1f:
            { st4_res = st4_arg1 + st4_arg2 + add_carry; st4_carry = st4_res&0x10000; st4_res&=0xffff; } break;
        default: { st4_carry = 0; st4_res = st4_arg2; } break;
    }
    if (new_cond) {
        bool p_ok = last_rd_peripheral && last_rd_peripheral_ok;
        if (wr_peripheral) {
            p_ok = system->peripheral_write(st4_arg2&0xff);
        }
        if (opcode == MUL) {
            in_mul = p1 * p2;
            in_mul_hi = in_mul>>16;
        }
        if (set_flags) {
            bool flagZ = st4_res == 0;
            bool flagC = st4_carry;
            bool flagV = ((st4_res^st4_arg1^st4_arg2)>>15)^st4_carry;
            bool flagN = st4_res & 0x8000;
            if (last_rd_peripheral | wr_peripheral)
                flagN = !p_ok;
            in_flags = (in_flags&~15)|(flagC<<3)|(flagV<<2)|(flagZ<<1)|flagN;
        }
        if (wr_reg) {
            if (wide) {
                regs[a&~1] = p2&0xffff;
                regs[a|1] = p2>>16;
            } else regs[a] = st4_res;
        } else if (jmp_ret) regs[15] += 2;
        else if (jmp_call) regs[15] -= 2;
        if (wr_sreg) sreg_out[a] = p2;
        if (wr_cache) {
            unsigned int data;
            if (jmp_call)
                data = ip + 1;
            else data = wide ? p2 : (((unsigned int)st4_res)<<16)|st4_res;
            cache[waddr] = data&0xffff;
            if (wide) cache[waddr|1] = data >> 16;
        }
    }
    if (jmp && new_cond) {
        if (jmp_ret) _ip = p2;
        else if (jmp_reg) _ip = ra32>>1;
        else _ip = ip + p2;
    } else _ip = ip + 1;
    if (opcode == RW && new_cond) {
        ram_count = (st4_arg2&0xffff);
        ram_cache_addr = (p1%CACHE_SIZE);
        ram_addr = ra32;
        ram_write = rw_write;
    }

    // stage 3
    st3_opcode = (command>>23) & 0x1f;
    cond = command >> 28;
    opcode = st3_opcode;
    st3_inv1 = (st3_opcode&0x1b) == 0x19;
    st3_inv2 = (st3_opcode&0x1a) == 0x1a;
    inv2 = st3_inv2 != ((st3_opcode&0x10) && ((command>>20)&3) == 3 && ((command>>7)&1));
    add_carry = (st3_opcode&0x1c)==0x1c ? st4_carry : (st3_inv1 || st3_inv2);
    st3_jump = st3_opcode == JUMP;
    st3_mov = (st3_opcode>>1) == 0xa;
    st3_cmov = st3_opcode == CMOV;
    st3_ccmov = st3_opcode == CCMOV;
    st3_test = (st3_opcode&0x17) == 0x13;
    st3_jmp_reg = st3_jump && !((command>>21)&1);
    st3_jmp_call = st3_jump && ((command>>22)&1);
    jmp_reg = st3_jmp_reg;
    st3_a = (command>>16)&15;
    a = st3_a;
    ra32 = (((unsigned int)regs[st3_a|1])<<16)|(regs[st3_a&~1]);
    st3_b = (command>>12)&15;
    st3_rb = regs[st3_b];
    p1 = st3_inv1 ? ~st3_rb : st3_rb;
    rw_write = (command>>22)&1;
    st3_c = command&255;
    wr_cache = ((st3_opcode&0x10) && ((command>>20)&3)==0) || st3_jmp_call || st3_ccmov;
    wide = st3_opcode == WMOV || st3_jump;
    if (st3_jmp_call) waddr = regs[15] - 2;
    else if (st3_ccmov) waddr = reg_r + ((command>>20)&7);
    else waddr = reg_r + st3_c;
    waddr = waddr % CACHE_SIZE;
    last_rd_peripheral = rd_peripheral;
    unsigned char rd_peripheral_data = 0;
    if (rd_peripheral)
        last_rd_peripheral_ok = system->peripheral_read(rd_peripheral_data);
    switch (p2type) {
        case 0:
        case 1: st3_p2 = rd_peripheral_data; break;
        case 2: st3_p2 = command & 0xfffff; break;
        case 3: st3_p2 = ((command>>4)&0xff00) | (command&0xff); break;
        case 4:case 5: case 6: case 7:
            st3_p2 = (((unsigned int)cache[raddr|1])<<16)|cache[raddr]; break;
        case 8: st3_p2 = command&0x3ff; break;
        case 9: st3_p2 = (command&0x3ff)<<6; break;
        case 10: st3_p2 = 0xfffffc00 | (command&0x3ff); break;
        case 11: st3_p2 = 0xffff003f | ((command&0x3ff)<<6); break;
        case 12: st3_p2 = (((unsigned int)regs[reg_num|1])<<16)|regs[reg_num]; break;
        case 13: st3_p2 = sreg_in[reg_num]; break;
        case 14: st3_p2 = reg_r << (command&15); break;
        case 15: st3_p2 = reg_r >> (command&15); break;
    }
    p2 = st3_p2;
    jmp = st3_jump;
    set_flags = (st3_opcode&0x10) && (command>>22)&1;
    jmp_call = st3_jmp_call;
    jmp_ret = st3_jump && st3_jmp_reg && (command>>20)&1;

    if ((st3_opcode&0x10) && !st3_test && ((command>>20)&3)!=0) {
        wr_sreg = st3_mov && ((command>>12)&3) == 1;
        wr_peripheral = st3_mov && ((command>>12)&3) == 3;
        wr_reg = !st3_mov || !(command&(1<<12));
    } else if (st3_cmov) {
        wr_reg = ((command>>20)&3) == 0;
        wr_sreg = command & (1<<20);
        wr_peripheral = command & (1<<21);
    } else {
        wr_reg = 0;
        wr_sreg = 0;
        wr_peripheral = 0;
    }

    // stage 2
    command = next_command;
    st2_opcode = (next_command>>23)&0x1f;
    st2_a = (next_command>>16)&15;
    st2_r = (next_command>>8)&15;
    st2_c = next_command&255;
    st2_jump = st2_opcode == JUMP;
    st2_mov = (st2_opcode>>1) == 0xa;
    rd_cache = (st2_jump||(st2_opcode&0x18)) && ((next_command>>20)&3) == 1;
    st2_rr = regs[st2_r];
    raddr = (st2_rr + st2_c) % CACHE_SIZE;
    rd_peripheral = st2_mov && ((next_command>>12)&3) == 2;
    if (st2_mov && (next_command&(1<<13)))
        system->peripheralAddr = ((next_command & ((1<<21)|(1<<20)|(1<<12))) == ((1<<21)|(1<<20))) ? st2_r : st2_a;
    else if (st2_opcode == CMOV && (next_command&(1<<21)))
        system->peripheralAddr = st2_a;
    reg_r = st2_rr;
    reg_num = ((next_command>>20)&3)==0 ? st2_a : st2_r;
    if (st2_mov && ((next_command>>12)&3)==2) p2type = 0;
    else if (st2_opcode >> 3) {
        switch ((next_command>>20)&3) {
              case 0:
                    if (st2_mov && (next_command&(1<<12))) p2type = 13;
                    else p2type = 12;
                    break;
              case 1: p2type = 4; break;
              case 2: p2type = 8 + ((next_command>>10)&3); break;
              case 3: p2type = 12 + ((next_command>>4)&3); break;
        }
    } else if (st2_opcode == CCMOV) p2type = 3;
    else if (st2_jump && ((next_command>>20)&3) == 1) p2type = 4;
    else p2type = 2;

    // stage 1
    next_command = (prog[ip]<<16)|(prog[ip]>>16);

    ip = _ip % PROG_SIZE;

    system->LEDstate = out_LEDs;
}

QString TestCore::getStateInfo() {
    QString info = QString("ip: 0x%1\n").arg(ip, 6, 16, QChar('0'));
    info += QString("flags: 0b%1\n").arg(in_flags, 5, 2, QChar('0'));
    for (int r=0; r<16; r+=2) {
        info += QString("r%1: 0x%2  r%3: 0x%4\n").arg(r, 2, 10, QChar('0')).arg(regs[r], 4, 16, QChar('0'))
                                               .arg(r+1, 2, 10, QChar('0')).arg(regs[r+1], 4, 16, QChar('0'));
    }
    info += QString("\nnext_command: 0x%1\n").arg(next_command, 8, 16, QChar('0'));
    info += QString("command: 0x%1\n").arg(command, 8, 16, QChar('0'));
    info += QString("p2type: %1\n").arg(p2type);
    info += QString("raddr: 0x%1  rd_cache: %2\n").arg(raddr, 4, 16, QChar('0')).arg(rd_cache);
    QString opcode_string;
    switch(opcode) {
        case NOP: opcode_string = "NOP"; break;
        case JUMP: opcode_string = "JUMP"; break;
        case CMOV: opcode_string = "CMOV"; break;
        case CCMOV: opcode_string = "CCMOV"; break;
        case RW: opcode_string = "RW"; break;
        case SUB: opcode_string = "SUB"; break;
        case RSB: opcode_string = "RSB"; break;
        case ADD: opcode_string = "ADD"; break;
        case XOR: opcode_string = "XOR"; break;
        case AND: opcode_string = "AND"; break;
        case OR: opcode_string = "OR"; break;
        case MUL: opcode_string = "MUL"; break;
        case CMP: opcode_string = "CMP"; break;
        case ADC: opcode_string = "ADC"; break;
        case TST: opcode_string = "TST"; break;
        case SBC: opcode_string = "SBC"; break;
        case RSC: opcode_string = "RSC"; break;
        case MOV: opcode_string = "MOV"; break;
        case WMOV: opcode_string = "WMOV"; break;
    }

    info += QString("\nopcode: ") + opcode_string + QString("  cond: %1  sf: %2\n").arg(cond).arg(set_flags);
    info += QString("wr: %1  wc %2  wsr %3 wp %4\n").arg(wr_reg).arg(wr_cache).arg(wr_sreg).arg(wr_peripheral);
    info += QString("j: %1 ret: %2  call %3  reg %4\n").arg(jmp).arg(jmp_ret).arg(jmp_call).arg(jmp_reg);
    info += QString("p1: %1\n").arg(p1, 8, 16, QChar('0'));
    info += QString("p2: %1\n").arg(p2, 8, 16, QChar('0'));
    info += QString("waddr: 0x%1  a: %2").arg(waddr, 4, 16, QChar('0')).arg(a);

    return info;
}
