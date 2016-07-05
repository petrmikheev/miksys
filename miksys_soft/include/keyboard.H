/* Чтение и обратка кода нажатой клавиши
* (буфер параметров, bool read_code) -> (, code)
*/
read_key_func:
#define _(x) read_key_func_##x
        MOV [r15+2], r14
        MOV [r15+3], r8
        MOV [r15+4], r9
        MOV r14, [r15]
        MOV [r15+5], r10
        MOV [r15+6], r11
        MOV r9, [r14]
_(rl):  INS DEV_PS2_0, r8
        JMI _(ret)
            CCMOVMI [r15+1], 0
            CMPPL r8, 0xe0
            JCS _(rl)
            OREQ r9, r9, 0x4000
            CMP r8, 0xf0
            OREQ r9, r9, 0x8000
            TST r9, 0x4000
        ORNE r8, r8, 0x100
        AND r10, r9, 0xff
        ADD r10, r10, r14
_(tl):  CMP r10, r14
        JNE _(check)
            XOR r11, r8, [r10]
            TST r11, 0x1ff
            SUB r10, r10, 1
            NOP
        MOVS r11, [r15+1]
        RSBNES r11, r9, 0x8000
        JLS _(rl)
            AND r9, r9, 0xff
            MOVHI [r15+1], r8
_(ret):     MOV [r14], r9
            MOV r11, [r15+6]
        RET
            MOV r14, [r15+2]
            MOV r8, [r15+3]
            MOV r9, [r15+4]
            MOV r10, [r15+5]

_(check):
        DJNE _(tl)
        TST r9, 0x8000
        ANDNE r11, r11, 0x7fff
        J _(tl)
            TSTEQ r11, 0x8000
            XOREQ r11, r11, 0x4000
            OREQ r11, r11, 0x8000
            OR [r10+1], r11, r8
#undef _

