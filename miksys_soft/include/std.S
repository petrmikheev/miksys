#ifndef BASE_ADDRESS
#define BASE_ADDRESS 0x100000
#endif
.code BASE_ADDRESS 0
.data 0 code_end
.virtual data_end 0

#include "std.H"
.code
        CMOV MEM_ADDR_LO, LO(code_end)
        CMOV MEM_ADDR_HI, HI(code_end)
        CMOV r0, 0
        READ r0, data_end
        CMOV r15, virtual_end
_LC1:   TST IN_FLAGS, MEM_FLAG
        DJNE _LC1
        DCALL C_main
_LC2:   DJ _LC2

C_set_leds:
        MOV r0, [r15]
        MOV OUT_LEDS, r0
        DRET

C_get_time_ms4:
        MOV r0, IN_TIME_MS4
        DRET

C_get_clocks:
        MOV r0, IN_CLOCK
        DRET

C_is_button_pressed:
        RET
        TST IN_FLAGS, SOFTKEY_FLAG
        CMOVEQ r0, 1
        CMOVNE r0, 0
        NOP

C_getc:
        MOVS r0, [r15]
        DJEQ _LC3
        CMP r0, 1
        DJEQ _LC4
        INS DEV_SERIAL, r0
        MOVMI r0, -1
        DRET
_LC3:   INS DEV_PS2_0, r0
        MOVMI r0, -1
        DRET
_LC4:   INS DEV_PS2_1, r0
        MOVMI r0, -1
        DRET

C_putc:
        MOV r0, 0
        MOVS r1, [r15]
        DJEQ _LC3
        CMP r1, 1
        DJEQ _LC4
        OUTS DEV_SERIAL, [r15+1]
        MOVMI r0, 1
        DRET
_LC3:   OUTS DEV_SERIAL, [r15+1]
        MOVMI r0, 1
        DRET
_LC4:   OUTS DEV_SERIAL, [r15+1]
        MOVMI r0, 1
        DRET

C_sdram_stats:
        MOV r0, [r15]
        MOV r1, [r15+1]
        RET
        IN DEV_SDRAM, [r0]
        IN DEV_SDRAM, [r1]
        NOP
        NOP

C_sdram:
        MOV [r15+5], MEM_ADDR_LO
        MOV [r15+6], MEM_ADDR_HI
        MOV MEM_ADDR_LO, [r15+3]
        MOV MEM_ADDR_HI, [r15+4]
        MOV r0, [r15+1]
        MOVS r1, [r15]
        READEQ r0, [r15+2]
        WRITENE r0, [r15+2]
        MOV MEM_ADDR_LO, [r15+5]
        MOV MEM_ADDR_HI, [r15+6]
_LC5:   TST IN_FLAGS, MEM_FLAG
        DJNE _LC5
        DRET

C_set_display:
        DRET

C_usb_request:
        CALL usb_request_func
            MOV r1, [r15+4]
            NOP
            NOP
            MOV [r15+4], r1
        MOV r2, [r15+4]
        MOV [r1], r2
        MOV r0, [r15+3]
        DRET
