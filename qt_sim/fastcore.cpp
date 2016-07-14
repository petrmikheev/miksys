#include "fastcore.h"
#include <cstdio>
#include <QDir>
#include <ctime>
#include <assert.h>
#include <string.h>

enum opcodes {
    NOP = 0x0,
    JUMP = 0x1,
    CMOV = 0x2,
    CCMOV = 0x3,
    DJUMP = 0x5,

    SHL = 0xc,
    SHR = 0xd,
    MUL = 0xe,
    RW = 0xf,
    OR = 0x10,
    XOR = 0x11,
    AND = 0x12,
    TST = 0x13,
    MOV = 0x14,

    RGBADD = 0x16,
    RGBSHR = 0x17,
    ADD = 0x18,
    RSB = 0x19,
    SUB = 0x1a,
    CMP = 0x1b,
    ADC = 0x1c,
    RSC = 0x1d,
    SBC = 0x1e
};

FastCore::FastCore(MIKSYS* system, char* filename) {
    this->system = system;
    FILE* p = fopen(filename, "rb");
    if (p) {
        int c = fread(prog, 4, PROG_SIZE, p);
        printf("Commands count: %d\n", c);
        fclose(p);
    } else {
        printf("warning: can't open '%s'\n", filename);
    }
    reset();
}

void FastCore::reset() {
    ip = 0;
    for (int i=0; i<PU_COUNT; ++i)
        pu[i].in_flags = i;
    st2_command = 0;
    st3_command = 0;
    st4_command = 0;
    st5_command = 0;
    system->vga_control_index = 0;
    memset(system->vga_control, 0, 8);
    system->vga_control[5] = 128;
    system->vga_control[2] = 128;
    system->keyboard_queue_begin = system->keyboard_queue_end = 0;
    drop_mode = false;
}

bool FastCore::check_cond(const PU& u, unsigned int cond) {
    bool N = u.in_flags & 16;
    bool Z = u.in_flags & 32;
    bool V = u.in_flags & 64;
    bool C = u.in_flags & 128;
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
        case 14: return Z || N != V;
        case 15: return false;
    default: return false;
    }
}

void FastCore::update() {
    {
        struct timespec ts;
        clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
        pu[0].in_time_ms4 = ts.tv_sec * 4096 + ts.tv_nsec / 250000;
    }
    for (int i = 0; i < PU_COUNT; ++i) {
        if (system->buttonState)
            pu[i].in_flags |= 1 << 2;
        else
            pu[i].in_flags &= ~(1 << 2);
    }
}

void FastCore::handleNext() {
    pu[0].in_clock++;
    pu[0].in_mem_addr_hi = pu[0].mem_addr_hi;
    pu[0].in_mem_addr_lo = pu[0].mem_addr_lo;
    if (ram_count > 0) {
        if (ram_write)
            system->memory[ram_addr] = cache[ram_cache_addr];
        else
            cache[ram_cache_addr] = system->memory[ram_addr];
        ram_addr = (ram_addr + 1) & (MIKSYS::MEM_SIZE-1);
        ram_cache_addr = (ram_cache_addr + 1) & (CACHE_SIZE-1);
        ram_count--;
    }
    for (int i = 0; i < PU_COUNT; ++i) {
        if (ram_count > 0)
            pu[i].in_flags |= 1 << 3;
        else
            pu[i].in_flags &= ~(1 << 3);
        if (pu[i].st7_mul) {
            pu[i].result_lo = pu[i].st7_mul_result_lo;
            pu[i].result_hi = pu[i].st7_mul_result_hi;
        } else if (pu[i].st6_shift)
            pu[i].result_lo = pu[i].st6_shift_result;
        if (i) for (int j=8; j<16; ++j) pu[i].regs[j] = pu[0].regs[j]; //memcpy(pu[i].regs + 8, pu[0].regs + 8, 8 * 2);
        // stage 6
        if (st6_wr_reg[i]) pu[i].regs[st6_reg] = st6_data[i];
        st6_wr_reg[i] = false;
        pu[i].st7_mul_result_lo = pu[i].st6_mul_result_lo;
        pu[i].st7_mul_result_hi = pu[i].st6_mul_result_hi;
        if (pu[i].st6_wmul) {
            pu[i].st6_mul_result_lo = (pu[i].st6_mul_result_hi + (unsigned int)pu[i].p1_st6 * pu[i].result_hi)&0xffff;
        }
        pu[i].st7_mul = pu[i].st6_mul;
        pu[i].st6_mul = pu[i].st6_wmul;
        pu[i].st6_wmul = false;
        pu[i].st6_shift = false;
    }

    // stage 5
    unsigned int _ip = ip + 1;
    {
        int cond = (st5_command >> 28) & 15;
        int opcode = (st5_command >> 23) & 31;
        bool inv2 = (opcode&0x10) && (((opcode&0xa)==0xa) != ((st5_command&0x300080)==0x300080));
        bool inv1 = st5_mov_arg1 ? inv2 : (opcode&0x1b)==0x19;
        for (int i = 0; i < PU_COUNT; ++i) {
            pu[i].cond_met = check_cond(pu[i], cond);
            if (inv1) pu[i].p1 = ~pu[i].p1;
            if (inv2) pu[i].p2 = ~pu[i].p2;
        }
        switch (opcode) {
        case JUMP:
        case DJUMP:
            if (pu[0].cond_met) {
                if (st5_command & 0x200000) {
                    _ip = ip + (st5_command & 0x1fffff);
                    if (opcode == DJUMP) _ip++;
                } else
                    _ip = ((unsigned int)pu[0].mem_addr_hi << 15) | (pu[0].mem_addr_lo >> 1);
                if (st5_command & 0x400000) {
                    pu[0].mem_addr_lo = ((ip+1)<<1) & 0xffff;
                    pu[0].mem_addr_hi = ((ip+1)>>15) & 0xffff;
                }
            }
            break;
        case RW:
            if (pu[0].cond_met) {
                ram_count = pu[0].p2;
                ram_cache_addr = pu[0].p1 & (CACHE_SIZE-1);
                ram_addr = (((unsigned int)pu[0].mem_addr_hi << 16) | pu[0].mem_addr_lo) & (system->MEM_SIZE-1);
                ram_write = (st5_command>>22) & 1;
            }
            break;
        case CMOV: {
            int a = (st5_command >> 16) & 15;
            bool special = st5_command & (1<<20);
            for (int i = 0; i < PU_COUNT; ++i) {
                if (!pu[i].cond_met) continue;
                if (special)
                    pu[i].sreg_out[a] = pu[0].p2;
                else
                    pu[i].regs[a] = pu[0].p2;
            }
        } break;
        case CCMOV:
            if (pu[0].cond_met) {
                cache[(st5_reg_r + ((st5_command>>20)&7)) % CACHE_SIZE] = pu[0].p2;
            } break;
        case SHL:
            for (int i = 0; i < PU_COUNT; ++i) {
                if (pu[i].cond_met) {
                    pu[i].st6_shift_result = pu[i].p1 << pu[i].p2;
                    pu[i].st6_shift = true;
                }
            } break;
        case SHR:
            for (int i = 0; i < PU_COUNT; ++i) {
                if (pu[i].cond_met) {
                    pu[i].st6_shift_result = pu[i].p1 >> pu[i].p2;
                    pu[i].st6_shift = true;
                }
            } break;
        case MUL:
            for (int i = 0; i < PU_COUNT; ++i) {
                if (pu[i].cond_met) {
                    if (st5_command & (1<<17)) pu[i].st6_wmul = true;
                    pu[i].p1_st6 = pu[i].p1;
                    unsigned int v;
                    if (st5_command & (1<<16)) {
                        short p1 = (short)pu[i].p1;
                        short p2 = (short)pu[i].p2;
                        v = (unsigned int)((int)p1 * (int)p2);
                    } else
                        v = (unsigned int)pu[i].p1 * pu[i].p2;
                    pu[i].st6_mul_result_lo = v & 0xffff;
                    pu[i].st6_mul_result_hi = v >> 16;
                    pu[i].st6_mul = true;
                }
            } break;
        default: break;
        }
        if (opcode & 0x10) {
            bool wr_cache = ((st5_command>>20)&3) == 0;
            bool wr_flags = st5_command&(1<<22);
            bool wr_reg = false;
            bool wr_sreg = false;
            bool wr_peripheral = false;
            if (!wr_cache && (opcode&7) != 3) {
                if (opcode == MOV) {
                    wr_reg = !(st5_command&(1<<12));
                    wr_sreg = ((st5_command>>12)&3) == 1;
                } else {
                    wr_reg = ((st5_command>>20)&3) != 3 || ((st5_command>>5)&1) == 0;
                    wr_sreg = !wr_reg;
                }
                wr_peripheral = opcode == MOV && ((st5_command>>12)&3) == 3;
            }
            for (int i = 0; i < PU_COUNT; ++i) if (pu[i].cond_met) {
                unsigned int res;
                int add_carry = 0;
                switch (opcode) {
                case AND:
                case TST: { pu[i].st5_carry = 0; res = pu[i].p1 & pu[i].p2; } break;
                case OR: { pu[i].st5_carry = 0; res = pu[i].p1 | pu[i].p2; } break;
                case XOR: { pu[i].st5_carry = 0; res = pu[i].p1 ^ pu[i].p2; } break;
                case RGBSHR: {
                    pu[i].st5_carry = 0;
                    int arg = st5_mov_arg1 ? pu[i].p1 : pu[i].p2;
                    int r = (arg>>11)&0x1f;
                    int g = (arg>>5)&0x3f;
                    int b = arg&0x1f;
                    r /= 2; g /= 2; b /= 2;
                    res = (r << 11) | (g << 5) | b;
                } break;
                case RGBADD: {
                    pu[i].st5_carry = 0;
                    int r1 = (pu[i].p1>>11)&0x1f;
                    int g1 = (pu[i].p1>>5)&0x3f;
                    int b1 = pu[i].p1&0x1f;
                    int r2 = (pu[i].p2>>11)&0x1f;
                    int g2 = (pu[i].p2>>5)&0x3f;
                    int b2 = pu[i].p2&0x1f;
                    int r = (r1+r2)&0x1f;
                    int g = (g1+g2)&0x3f;
                    int b = (b1+b2)&0x1f;
                    res = (r << 11) | (g << 5) | b;
                } break;
                case ADD:case RSB:case SUB:case CMP:case ADC:case SBC:case RSC:case 0x1f: {
                        if (opcode & 4) add_carry = pu[i].st5_carry;
                        else add_carry = opcode != ADD;
                        res = (unsigned int)pu[i].p1 + pu[i].p2 + add_carry;
                        pu[i].st5_carry = res&0x10000;
                        res&=0xffff;
                    } break;
                default: { pu[i].st5_carry = 0; res = st5_mov_arg1 ? pu[i].p1 : pu[i].p2; } break;
                }
                st6_data[i] = res;
                st6_wr_reg[i] = wr_reg;
                int a = (st5_command >> 16) & 15;
                st6_reg = a;
                if (wr_sreg) pu[i].sreg_out[a] = res;
                bool p_ok = false;
                if (wr_peripheral && i == 0) p_ok = system->peripheral_write(res&0xff);
                if (wr_cache) {
                    bool all = st5_command & 128;
                    if ((all || i == 0) && pu[i].cond_met) {
                        unsigned short addr = (st5_reg_r + (st5_command & 127)) & (CACHE_SIZE-1);
                        unsigned short addr_base = addr & ~3;
                        unsigned short addr_shift = addr & 3;
                        cache[addr_base + ((addr_shift+i)&3)] = res;
                    }
                }
                if (wr_flags) {
                    bool flagZ = res == 0;
                    bool flagC = pu[i].st5_carry;
                    bool flagV = ((res^pu[i].p1^pu[i].p2)>>15)^flagC;
                    bool flagN = res & 0x8000;
                    if (p2type == 0 || wr_peripheral) {
                        if (wr_peripheral)
                            flagN = !p_ok;
                        else
                            flagN = !st5_rd_peripheral_ok;
                        flagZ = flagC = flagV = 0;
                    }
                    pu[i].in_flags = (pu[i].in_flags&~(15<<4))|(flagC<<7)|(flagV<<6)|(flagZ<<5)|(flagN<<4);
                }
            }
        }
    }

    // stage 4
    {
        unsigned short c_const = 0;
        st5_command = st4_command;
        st5_reg_r = st4_reg_r;
        int opcode = (st4_command >> 23) & 31;
        st5_mov_arg1 = opcode == MOV && ((st4_command>>21)&1) == ((st4_command>>20)&1) && ((st4_command>>12)&3) != 2;
        if (opcode == MOV && ((st4_command>>12)&3) == 2) p2type = 0;
        else if (opcode&0x18) {
            switch ((st4_command>>20)&3) {
            case 0:
                if (opcode == MOV && ((st4_command>>12)&1))
                    p2type = 2;
                else
                    p2type = 1;
                break;
            case 1: p2type = 4; break;
            case 2:
                p2type = 3;
                switch ((st4_command>>10)&3) {
                case 0: c_const = st4_command & 0x1ff; break;
                case 1: c_const = (st4_command & 0x1ff) << 7; break;
                case 2: c_const = (st4_command & 0x1ff) + 0xfe00; break;
                case 3: c_const = ((st4_command & 0x1ff) << 7) + 0x7f; break;
                }
                break;
            case 3:
                if ((st4_command>>4)&1)
                    p2type = 2;
                else
                    p2type = 1;
                break;
            default: break;
            }
        } else {
            p2type = 3;
            if (opcode == CCMOV)
                c_const = ((st4_command>>4)&0xff00) + (st4_command&0xff);
            else
                c_const = st4_command & 0xffff;
        }
        int b;
        int a = (st4_command >> 16) & 15;
        int r = (st4_command >> 8) & 15;
        int d = ((st4_command>>20)&3)==3 ? r : a;
        if (opcode == MOV && ((st4_command>>12)&2) == 2)
            system->peripheralAddr = ((st4_command&0x301000) == 0x300000) ? r&7 : a&7;
        if (p2type == 0) {
            unsigned char c;
            st5_rd_peripheral_ok = system->peripheral_read(c);
            pu[0].p2 = c;
        }
        bool bsreg;
        if (st5_mov_arg1) {
            b = d;
            bsreg = p2type == 2;
        } else {
            b = (st4_command >> 12) & 15;
            bsreg = ((st4_command>>20)&3) == 2 && (st4_command&(1<<9));
        }
        for (int i = 0; i < PU_COUNT; ++i) {
            if (bsreg) pu[i].p1 = pu[i].sreg_in[b];
            else if (st6_wr_reg[i] && st6_reg == b)
                pu[i].p1 = st6_data[i];
            else
                pu[i].p1 = pu[i].regs[b];
            switch (p2type) {
            case 0: break;
            case 1: pu[i].p2 = pu[i].regs[d]; break;
            case 2: pu[i].p2 = pu[i].sreg_in[d]; break;
            case 3: pu[i].p2 = c_const; break;
            case 4: pu[i].p2 = pu[i].st4_from_cache; break;
            }
        }
    }

    // stage 3
    st4_command = st3_command;
    st4_reg_r = st3_reg_r;
    // stage 2
    st3_command = st2_command;
    int r = (st2_command >> 8) & 15;
    if (st6_wr_reg[0] && st6_reg == r)
        st3_reg_r = st6_data[0];
    else
        st3_reg_r = pu[0].regs[r];
    unsigned short addr = (st3_reg_r + (st2_command & 127)) & (CACHE_SIZE-1);
    unsigned short addr_base = addr & ~3;
    unsigned short addr_shift = addr & 3;

    int all = st2_command&128 ? 1 : 0;

    for (int i = 0; i < 4; ++i) {
        // stage 3
        pu[i].st4_from_cache = pu[i].st3_from_cache;
        // stage 2
        pu[i].st3_from_cache = cache[addr_base + ((addr_shift+i*all)&3)];
    }

    // stage 1
    if (drop_mode > 0) {
        st2_command = 0;
        drop_mode--;
    } else {
        if (ip < PROG_SIZE)
            st2_command = prog[ip];
        else
            st2_command = ((unsigned int)system->memory[ip*2+1]<<16) | system->memory[ip*2];
        int opcode = (st2_command >> 23) & 31;
        if (opcode == DJUMP) drop_mode = 4;
    }
    if (drop_mode == 0) ip = _ip & (system->MEM_SIZE/2-1);
    system->LEDstate = pu[0].out_LEDs;
}

QString FastCore::commandToString(unsigned int command) {
    QString opcode_string;
    switch((command>>23)&0x1f) {
        case NOP: opcode_string = "NOP"; break;
        case JUMP: opcode_string = "JUMP"; break;
        case DJUMP: opcode_string = "DJUMP"; break;
        case CMOV: opcode_string = "CMOV"; break;
        case CCMOV: opcode_string = "CCMOV"; break;
        case MUL: opcode_string = "MUL"; break;
        case SHL: opcode_string = "SHL"; break;
        case SHR: opcode_string = "SHR"; break;
        case RW: opcode_string = "RW"; break;
        case RGBADD: opcode_string = "RGBADD"; break;
        case RGBSHR: opcode_string = "RGBSHR"; break;
        case SUB: opcode_string = "SUB"; break;
        case RSB: opcode_string = "RSB"; break;
        case ADD: opcode_string = "ADD"; break;
        case XOR: opcode_string = "XOR"; break;
        case AND: opcode_string = "AND"; break;
        case OR: opcode_string = "OR"; break;
        case CMP: opcode_string = "CMP"; break;
        case ADC: opcode_string = "ADC"; break;
        case TST: opcode_string = "TST"; break;
        case SBC: opcode_string = "SBC"; break;
        case RSC: opcode_string = "RSC"; break;
        case MOV: opcode_string = "MOV"; break;
    }
    return opcode_string;
}

QString FastCore::getStateInfo() {
    QString info = QString("ip: 0x%1\n").arg(ip, 6, 16, QChar('0'));
    info += QString("st2_com: 0x%1   %2\n").arg(st2_command, 8, 16, QChar('0')).arg(commandToString(st2_command));
    info += QString("st3_com: 0x%1   %2\n").arg(st3_command, 8, 16, QChar('0')).arg(commandToString(st3_command));
    info += QString("st4_com: 0x%1   %2\n").arg(st4_command, 8, 16, QChar('0')).arg(commandToString(st4_command));
    info += QString("st5_com: 0x%1   %2\n").arg(st5_command, 8, 16, QChar('0')).arg(commandToString(st5_command));
    info += QString("flags: 0x%1 0x%2 0x%3 0x%4\n").arg(pu[0].in_flags, 4, 16, QChar('0'))
                                                   .arg(pu[1].in_flags, 4, 16, QChar('0'))
                                                   .arg(pu[2].in_flags, 4, 16, QChar('0'))
                                                   .arg(pu[3].in_flags, 4, 16, QChar('0'));
    for (int r=0; r<8; r++) {
        QString s = QString("r%1: 0x%2 0x%3 0x%4 0x%5\n").arg(r, 2, 10, QChar('0'));
        for (int i=0; i<4; ++i)
            s = s.arg(pu[i].regs[r], 4, 16, QChar('0'));
        info += s;
    }
    for (int r=8; r<16; r+=2) {
        QString s = QString("r%1: 0x%3   r%2: 0x%4\n").arg(r, 2, 10, QChar('0')).arg(r+1, 2, 10, QChar('0'));
        info += s.arg(pu[0].regs[r], 4, 16, QChar('0')).arg(pu[0].regs[r+1], 4, 16, QChar('0'));
    }
    {
        QString s = QString("p1: 0x%1 0x%2 0x%3 0x%4\n");
        for (int i=0; i<4; ++i)
            s = s.arg(pu[i].p1, 4, 16, QChar('0'));
        info += s;
    }
    {
        QString s = QString("p2: 0x%1 0x%2 0x%3 0x%4\n");
        for (int i=0; i<4; ++i)
            s = s.arg(pu[i].p2, 4, 16, QChar('0'));
        info += s;
    }
    {
        QString s = QString("st6_data: 0x%1 0x%2 0x%3 0x%4\n");
        for (int i=0; i<4; ++i)
            s = s.arg(st6_data[i], 4, 16, QChar('0'));
        info += s;
    }
    info += QString("st6_reg %1  wr %2 %3 %4 %5\n").arg(st6_reg).arg(st6_wr_reg[0]).arg(st6_wr_reg[1]).arg(st6_wr_reg[2]).arg(st6_wr_reg[3]);
    info += QString("mem_addr: 0x%1 : 0x%2\n").arg(pu[0].mem_addr_hi, 4, 16, QChar('0')).
                                               arg(pu[0].mem_addr_lo, 4, 16, QChar('0'));
    /*
    info += QString("p2type: %1\n").arg(p2type);
    info += QString("raddr: 0x%1  rd_cache: %2\n").arg(raddr, 4, 16, QChar('0')).arg(rd_cache);

    info += QString("\nopcode: ") + opcode_string + QString("  cond: %1  sf: %2\n").arg(cond).arg(set_flags);
    info += QString("wr: %1  wc %2  wsr %3 wp %4\n").arg(wr_reg).arg(wr_cache).arg(wr_sreg).arg(wr_peripheral);
    info += QString("j: %1 ret: %2  call %3  reg %4\n").arg(jmp).arg(jmp_ret).arg(jmp_call).arg(jmp_reg);
    info += QString("p1: %1\n").arg(p1, 8, 16, QChar('0'));
    info += QString("p2: %1\n").arg(p2, 8, 16, QChar('0'));
    info += QString("waddr: 0x%1  a: %2").arg(waddr, 4, 16, QChar('0')).arg(a);
*/
    return info;
}
