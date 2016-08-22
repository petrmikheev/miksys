#define WATCH_MAX_COUNT 16

.code

C_ps2k_readcode:
        CMOV r1, _keyboard_data
_rl:    INS DEV_PS2_0, r0
        RETMI
            CMOVMI r0, 0
            MOV r2, [r1]
            AND r3, r2, 0xff
            ADD r3, r3, r1
        CMP r0, 0xe0
        JCS _rl
            OREQ r2, r2, 0x4000
            CMP r0, 0xf0
            OREQ r2, r2, 0x8000
            MOV [r1], r2
        TST r2, 0x4000
        ORNE r0, r0, 0x100
_tl:    CMP r3, r1
        JNE _check
            XOR r4, r0, [r3]
            TST r4, 0x1ff
            SUB r3, r3, 1
            CMOV r5, 0xff
        TST r2, 0x8000
        AND [r1], r2, r5
        DJNE _rl
        DRET

_check:
        DJNE _tl
        TST r2, 0x8000
        ANDNE r4, r4, 0x7fff
        J _tl
            TSTEQ r4, 0x8000
            XOREQ r4, r4, 0x4000
            OREQ r4, r4, 0x8000
            OR [r3+1], r4, r0

C_ps2k_readchar:
        MOV [r15], MEM_ADDR_LO
        MOV [r15+1], MEM_ADDR_HI
        DCALL C_ps2k_readcode
        MOV MEM_ADDR_LO, [r15]
        MOV MEM_ADDR_HI, [r15+1]
        CMP r0, 0
        RETEQ
            CMOV r1, _shift_key
            ADD r0, r0, _keymap
            MOVEQ r0, 0xffff
            MOVS r1, [r1]
        RET
            MOV r0, [r0]
            SHR r0, 8
            ANDPL r0, r0, 0xff
            MOVMI r0, SHIFT_RESULT

C_ps2k_unwatch_all:
        CMOV r0, _keyboard_data
        RET
            CMOV r1, 0xff00
            AND r1, r1, [r0]
            ADD r1, r1, 1
            MOV [r0], r1

C_ps2k_watch:
        CMOV r1, _keyboard_data
        MOV r2, [r15]
        CMOV r4, 1
        MOV r3, [r1]
        AND r0, r3, 0xff
        CMP r0, WATCH_MAX_COUNT-1
        RET
            ADD r0, r0, r1
            NOP
            ADDNE [r1], r3, r4
            MOVNE [r0], r2

.data
_keyboard_data:
    .const 1
_shift_key: .const 0x12
    .words WATCH_MAX_COUNT
_keymap:
#include <keymap.H>

