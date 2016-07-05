/* Перевод числа в текст
* (буфер, число, флаги|основание, цвет) -> (смещенный буфер) 
* флаг 0x100 = 0 -> буфер указывает на первый символ
* флаг 0x100 = 1 -> буфер указывает на последний символ
* флаг 0x200     -> отображать знак для отрицательных
*/
set_number_base_func:
#define _(x) set_number_base_func_##x
#define buf r8
#define num r9
#define base r10
#define color r12
#define sign r13
#define STACK_FRAME_SIZE 12
        MOV [r15+4], r8
        MOV [r15+5], r9
        MOV [r15+6], r10
        MOV [r15+7], r11
        MOV [r15+8], MEM_ADDR_LO
        MOV [r15+9], MEM_ADDR_HI
        MOV [r15+10], r12
        MOV [r15+11], r13
        
        MOV base, [r15+2]
        MOV sign, 0
        MOV num, [r15+1]
        TST num, 0x8000
        TSTNE base, 0x200
        MOVNE sign, 1
        RSBNE num, num, 0
        TST base, 0x100
        JNE _(skip_sh)
            AND base, base, 0xff
            MUL base, 1
            MOV color, [r15+3]
            MOV buf, [r15]
        ADD buf, buf, sign
_(sh):  CMPEQ num, MUL_RESULT_LO
        JCS _(sh)
            MUL base, MUL_RESULT_LO
_(skip_sh): ADD buf, buf, 1
            MOV [r15], buf
            RSBS r11, MUL_RESULT_HI, 0
_(loop):
        CALL divide_func
            SUB buf, buf, 1
            ADD r15, r15, STACK_FRAME_SIZE
            MOV [r15+STACK_FRAME_SIZE], num
            MOV [r15+STACK_FRAME_SIZE+1], base
        SUB r15, r15, STACK_FRAME_SIZE
            MOV r11, [r15]
            MOVS num, [r15+1]
        JNE _(loop)
            CMP r11, 10
            ADDCC r11, r11, '0'
            ADDCS r11, r11, 'A'-10
            OR [buf], r11, color
        SUB buf, buf, 1
        TST sign, 1
        ORNE sign, color, '-'
        MOVNE [buf], sign
        MOV MEM_ADDR_LO, [r15+8]
        MOV MEM_ADDR_HI, [r15+9]
        MOV r13, [r15+11]
        MOV r12, [r15+10]
        RET
            MOV r8, [r15+4]
            MOV r9, [r15+5]
            MOV r10, [r15+6]
            MOV r11, [r15+7]
#undef _
#undef buf
#undef num
#undef base
#undef color
#undef sign
#undef STACK_FRAME_SIZE

/* Форматирование текста для вывода на экран
* (буфер, строка, цвет|флаги, [число1], ..., [число9]) -> (смещенный буфер) 
* флаг 0x0001 = 0 -> Форматирование включено
* флаг 0x0001 = 1 -> Форматирование выключено
*/
printf_func:
#define _(x) printf_func_##x
#define ARGS_COUNT 12
#define buf r8
#define str r9
#define next_num r10
#define state [r15+ARGS_COUNT+7]
#define STACK_FRAME_SIZE ARGS_COUNT + 10
        MOV [r15+ARGS_COUNT+2], r8
        MOV [r15+ARGS_COUNT+3], r9
        MOV [r15+ARGS_COUNT+4], r10
        MOV [r15+ARGS_COUNT+5], r11
        MOV [r15+ARGS_COUNT+6], r12
        MOV buf, [r15]
        MOV str, [r15+1]
        MOV [r15+ARGS_COUNT], MEM_ADDR_LO
        MOV [r15+ARGS_COUNT+1], MEM_ADDR_HI
        XOR state, r8, r8
        ADD next_num, r15, 3
_(loop):
        MOVS r11, [str]
        JEQ _(end)
            MOVEQ [r15], buf
            MOVEQ MEM_ADDR_LO, [r15+ARGS_COUNT]
            MOVEQ MEM_ADDR_HI, [r15+ARGS_COUNT+1]
            MOVEQ r12, [r15+ARGS_COUNT+6]
        AND r11, r11, 0xff
        DCALL _(handle_char)
        CALL _(handle_char)
            MOV r11, [str]
            SHR r11, 8
            ADD str, str, 1
            MOV r11, SHIFT_RESULT

        DJ _(loop)

_(end): 
        RET
            MOV r8, [r15+ARGS_COUNT+2]
            MOV r9, [r15+ARGS_COUNT+3]
            MOV r10, [r15+ARGS_COUNT+4]
            MOV r11, [r15+ARGS_COUNT+5]

_(handle_char):
        MOVS r12, state
        MOV r12, 1
        JNE _(handle_special)
            CMPEQ r11, '%'
            TSTEQ r12, [r15+2]
            RETEQ
            MOVEQ state, r12
            MOV r12, [r15+2]
            AND r12, r12, 0xff00
            CMP r11, '\n'
        RETNE
            ORHI [buf], r12, r11
            ADDHI buf, buf, 1
_(new_line):
            AND r11, buf, 0x7f
            CMP r11, 0x7f
        CCMOV [buf], 0
        ADD buf, buf, 1
        DJNE _(new_line)
        DRET

_(handle_special):
        MOV r12, [r15+2]
        CMP r11, '%'
        RETEQ
            AND r12, r12, 0xff00
            XOR state, r8, r8
            OREQ [buf], r11, r12
            ADDEQ buf, buf, 1
        MOV [r15+STACK_FRAME_SIZE+3], r12 // number color
        
        CMOV r12, 10
        CMP r11, 'U'
        CMOVEQ r12, 0x100|10
        CMP r11, 'd'
        CMOVEQ r12, 0x200|10
        CMP r11, 'D'
        CMOVEQ r12, 0x300|10
        CMP r11, 'x'
        CMOVEQ r12, 16
        CMP r11, 'X'
        CMOVEQ r12, 0x100|16
        CMP r11, 'b'
        CMOVEQ r12, 2
        CMP r11, 'B'
        CMOVEQ r12, 0x100|2
        MOV [r15+STACK_FRAME_SIZE+2], r12
        
        MOV [r15+ARGS_COUNT+8], MEM_ADDR_LO
        MOV [r15+ARGS_COUNT+9], MEM_ADDR_HI
        MOV r12, [next_num]
        CALL set_number_base_func
            ADD r15, r15, STACK_FRAME_SIZE
            ADD next_num, next_num, 1
            MOV [r15+STACK_FRAME_SIZE+1], r12 // number
            MOV [r15], buf      // buf
        SUB r15, r15, STACK_FRAME_SIZE
        MOV buf, [r15]
        NOP
        MOV MEM_ADDR_LO, [r15+ARGS_COUNT+8]
        MOV MEM_ADDR_HI, [r15+ARGS_COUNT+9]
        DRET
#undef _
#undef buf
#undef str
#undef state
#undef ARGS_COUNT
#undef next_num
#undef STACK_FRAME_SIZE

