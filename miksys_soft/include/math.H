/*
Параметры и возвращаемые значения передаются через стек.
Указатель стека -- r15. Растет вверх.
[r15] -- первый параметр (и первое возвращаемое значение)
[r15+1] -- второй параметр и т.д.
*/

/* Деление с остатком
* (делимое, делитель) -> (остаток, частное)
*/
divide_func:
#define _(x) divide_func_##x
#define ARGS_COUNT 12
        MOV [r15+ARGS_COUNT+2], r8
        MOV [r15+ARGS_COUNT+3], r9
        MOV [r15+ARGS_COUNT+4], r10
        MOV [r15+ARGS_COUNT+5], r11
        MOVS r9, [r15+1]
        JEQ ret_r8_11
            CCMOVEQ [r15+1], 0xffff
            MOV r8, [r15]
            MOV r10, 1
_(s):       SHL r9, 1
        ADDPL r10, r10, r10
        MOVPLS r9, SHIFT_RESULT
        DJPL _(s)
        MOV r11, 0
_(c):   SHR r10, 1
        CMP r8, r9
        ADDCS r11, r11, r10
        SUBCS r8, r8, r9
        MOVS r10, SHIFT_RESULT
        JNE _(c)
            SHR r9, 1
            MOV [r15], r8
            MOV r9, SHIFT_RESULT
            MOV [r15+1], r11
ret_r8_11:
        RET
            MOV r8, [r15+ARGS_COUNT+2]
            MOV r9, [r15+ARGS_COUNT+3]
            MOV r10, [r15+ARGS_COUNT+4]
            MOV r11, [r15+ARGS_COUNT+5]
#undef _
#undef ARGS_COUNT

