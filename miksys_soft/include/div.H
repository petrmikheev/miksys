
/* Деление с остатком
* (r12=делимое, r13=делитель) -> (r12=остаток, r13=частное)
* Используются регистры r10, r11
*/
divide_func:
#define _(x) divide_func_##x
        MOVS r11, r13
        RETEQ
            MOVEQ r13, 0xffff
            MOV r10, 1
_(s):       SHL r11, 1
            ADDPL r10, r10, r10
        MOVPLS r11, SHIFT_RESULT
        DJPL _(s)
        MOV r13, 0
_(c):   CMP r12, r11
        ADDCS r13, r13, r10
        SUBCS r12, r12, r11
        CMP r10, 1
        RETEQ
        JNE _(c)
            SHR r11, 1
            SHR r10, 1
            MOV r11, SHIFT_RESULT
            MOV r10, SHIFT_RESULT
#undef _

