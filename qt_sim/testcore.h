#ifndef TESTCORE_H
#define TESTCORE_H

#include "core.h"
#include "miksys.h"

class TestCore : public Core
{
public:
    static const size_t CACHE_SIZE = 16384;
    static const size_t PROG_SIZE = 1024;
    TestCore(MIKSYS* system, char* filename);
    void reset();
    void handleNext();
    QString getStateInfo();
    unsigned short regs[16];
    unsigned int sreg_in[16];
    unsigned int sreg_out[16];
    #define in_flags sreg_in[0]
    #define in_time sreg_in[1]
    #define in_mul sreg_in[2]
    #define in_mul_hi sreg_in[3]
    #define out_LEDs sreg_out[0]
    unsigned short cache[CACHE_SIZE];
    unsigned int ip;
    unsigned int prog[PROG_SIZE];


    // Stage 1 -> Stage 2
    unsigned int next_command;

    // Stage 2 -> Stage 3
    unsigned int command, raddr, reg_r, reg_num, p2type;
    bool rd_cache, rd_peripheral;

    // Stage 3 -> Stage 4
    int opcode, cond, a;
    bool jmp, jmp_ret, jmp_call, jmp_reg, wr_reg, wr_cache, wr_sreg, wr_peripheral, set_flags;
    bool inv2, add_carry, rw_write, last_rd_peripheral, last_rd_peripheral_ok, wide;
    unsigned int p1, p2, waddr, ra32;

    // read/write ram
    unsigned int ram_addr;
    unsigned int ram_cache_addr;
    unsigned int ram_count;
    bool ram_write;
private:
    bool check_cond(unsigned int cond);
};

#endif // TESTCORE_H
