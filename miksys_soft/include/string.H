/* Перевод числа в текст
* (буфер, число, флаги|основание, цвет) -> (смещенный буфер) 
* флаг 0x100 = 0 -> буфер указывает на первый символ
* флаг 0x100 = 1 -> буфер указывает на последний символ
* флаг 0x200     -> отображать знак для отрицательных
*/
set_number_base_func:
#define _(x) set_number_base_func_##x
#define buf r8
#define num r1
#define base r2
#define color r9
#define sign r3
#define ARGS_COUNT 12
        MOV [r15+ARGS_COUNT+2], r8
        MOV [r15+ARGS_COUNT+3], r9
        MOV [r15+ARGS_COUNT+4], r2
        MOV [r15+ARGS_COUNT+5], r3
        MOV [r15+4], MEM_ADDR_LO
        MOV [r15+5], MEM_ADDR_HI
        //MOV [r15+6], r0
        MOV [r15+7], r1
        
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
            RSBS r0, MUL_RESULT_HI, 0
        
        MOV [r15+1], sign
        MOV [r15+2], base
_(loop):
        CALL divide_func
            SUB buf, buf, 1
            MOV r0, num
            MOV r1, [r15+2]
            NOP
        CMP num, 0
        JNE _(loop)
            CMP r0, 10
            ADDCC r0, r0, '0'
            ADDCS r0, r0, 'A'-10
            OR [buf], r0, color
        SUB buf, buf, 1
        MOV sign, [r15+1]
        TST sign, 1
        ORNE sign, color, '-'
        MOVNE [buf], sign
        MOV MEM_ADDR_LO, [r15+4]
        MOV MEM_ADDR_HI, [r15+5]
        MOV r1, [r15+7]
        MOV r0, [r15] //[r15+6]
set_number_base_func_ret_r2389:
        RET
            MOV r8, [r15+ARGS_COUNT+2]
            MOV r9, [r15+ARGS_COUNT+3]
            MOV r2, [r15+ARGS_COUNT+4]
            MOV r3, [r15+ARGS_COUNT+5]
#undef _
#undef buf
#undef num
#undef base
#undef color
#undef sign

/* Форматирование текста для вывода на экран
* (буфер, строка, цвет|флаги, [число1], ..., [число9]) -> (смещенный буфер) 
* r0 = смещенный буфер
* флаг 0x0001 = 0 -> Форматирование включено
* флаг 0x0001 = 1 -> Форматирование выключено
*/
printf_func:
#define _(x) printf_func_##x
#define buf r0
#define str r9
#define next_num r2
#define state [r15+ARGS_COUNT+7]
#define STACK_FRAME_SIZE ARGS_COUNT + 10
        MOV [r15+ARGS_COUNT+2], r8
        MOV [r15+ARGS_COUNT+3], r9
        MOV [r15+ARGS_COUNT+4], r2
        MOV [r15+ARGS_COUNT+5], r3
//        MOV [r15+ARGS_COUNT+6], r0
        MOV buf, [r15]
        MOV str, [r15+1]
        MOV [r15+ARGS_COUNT], MEM_ADDR_LO
        MOV [r15+ARGS_COUNT+1], MEM_ADDR_HI
        XOR state, r8, r8
        ADD next_num, r15, 3
_(loop):
        MOVS r3, [str]
        JEQ set_number_base_func_ret_r2389
            MOVEQ [r15], buf
            MOVEQ MEM_ADDR_LO, [r15+ARGS_COUNT]
            MOVEQ MEM_ADDR_HI, [r15+ARGS_COUNT+1]
            //MOVEQ r0, buf //[r15+ARGS_COUNT+6]
            AND r3, r3, 0xff
        DCALL _(handle_char)
        CALL _(handle_char)
            MOV r3, [str]
            SHR r3, 8
            ADD str, str, 1
            MOV r3, SHIFT_RESULT

        DJ _(loop)

_(handle_char):
        MOVS r8, state
        MOV r8, 1
        JNE _(handle_special)
            CMPEQ r3, '%'
            TSTEQ r8, [r15+2]
            RETEQ
            MOVEQ state, r8
            MOV r8, [r15+2]
            AND r8, r8, 0xff00
            CMP r3, '\n'
        RETNE
            ORHI [buf], r8, r3
            ADDHI buf, buf, 1
_(new_line):
            AND r3, buf, 0x7f
            CMP r3, 0x7f
        CCMOV [buf], 0
        ADD buf, buf, 1
        DJNE _(new_line)
        DRET

_(handle_special):
        MOV r8, [r15+2]
        CMP r3, '%'
        RETEQ
            AND r8, r8, 0xff00
            XOR state, r8, r8
            OREQ [buf], r3, r8
            ADDEQ buf, buf, 1
        MOV [r15+STACK_FRAME_SIZE+3], r8 // number color
        
        CMOV r8, 10
        CMP r3, 'U'
        CMOVEQ r8, 0x100|10
        CMP r3, 'd'
        CMOVEQ r8, 0x200|10
        CMP r3, 'D'
        CMOVEQ r8, 0x300|10
        CMP r3, 'x'
        CMOVEQ r8, 16
        CMP r3, 'X'
        CMOVEQ r8, 0x100|16
        CMP r3, 'b'
        CMOVEQ r8, 2
        CMP r3, 'B'
        CMOVEQ r8, 0x100|2
        MOV [r15+STACK_FRAME_SIZE+2], r8
        
        MOV [r15+ARGS_COUNT+8], MEM_ADDR_LO
        MOV [r15+ARGS_COUNT+9], MEM_ADDR_HI
        MOV r8, [next_num]
        CALL set_number_base_func
            ADD r15, r15, STACK_FRAME_SIZE
            ADD next_num, next_num, 1
            MOV [r15+STACK_FRAME_SIZE+1], r8 // number
            MOV [r15], buf      // buf
        SUB r15, r15, STACK_FRAME_SIZE
        NOP //MOV buf, [r15]
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

