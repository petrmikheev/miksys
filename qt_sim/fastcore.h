#ifndef FASTCORE_H
#define FASTCORE_H

#include "core.h"
#include "miksys.h"

class FastCore : public Core
{
public:
    FastCore();
    static const size_t CACHE_SIZE = 16384;
    static const size_t PROG_SIZE = 512;
    static const int PU_COUNT = 4;
    FastCore(MIKSYS* system, char* filename);
    void reset();
    void handleNext();
    void update();
    QString getStateInfo();
    struct PU {
        unsigned short regs[16];
        unsigned short sreg_in[16];
        unsigned short sreg_out[16];
        unsigned short p1, p2, p1_st6, st3_from_cache, st4_from_cache;
        bool cond_met, st5_carry;
        bool st6_shift, st6_mul, st6_wmul;
        bool st7_mul;
        unsigned short st6_mul_result_lo, st6_mul_result_hi, st6_shift_result;
        unsigned short st7_mul_result_lo, st7_mul_result_hi;
    };
    PU pu[PU_COUNT];
    #define in_flags sreg_in[0]
    #define in_mem_addr_lo sreg_in[1]
    #define in_mem_addr_hi sreg_in[2]
    #define in_clock sreg_in[3]
    #define in_time_ms4 sreg_in[4]
    #define result_lo sreg_in[5]
    #define result_hi sreg_in[6]
    #define fp_result sreg_in[7]
    #define out_LEDs sreg_out[0]
    #define mem_addr_lo sreg_out[1]
    #define mem_addr_hi sreg_out[2]
    unsigned short cache[CACHE_SIZE];
    unsigned int ip;
    unsigned int prog[PROG_SIZE];

    unsigned int st2_command;
    unsigned int st3_command;
    unsigned int st4_command;
    unsigned int st5_command;
    unsigned short st3_reg_r, st4_reg_r, st5_reg_r;
    bool st5_rd_peripheral_ok;
    bool st5_mov_arg1;
    int st6_reg;
    bool st6_wr_reg[PU_COUNT];
    unsigned short st6_data[PU_COUNT];
    int p2type;

    // read/write ram
    unsigned int ram_addr;
    unsigned int ram_cache_addr;
    unsigned int ram_count;
    bool ram_write;
    int drop_mode;
private:
    bool check_cond(const PU& pu, unsigned int cond);
    QString commandToString(unsigned int command);
};

#endif // FASTCORE_H
