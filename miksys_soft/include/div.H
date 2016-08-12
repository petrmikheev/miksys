
/* Деление с остатком
* (r0=делимое, r1=делитель) -> (r0=остаток, r1=частное)
* Используются регистры r2, r3
*/
divide_func:
#define _(x) divide_func_##x
        MOVS r3, r1
        RETEQ
            CMOVEQ r1, 0xffff
            MOV r2, 1
_(s):       SUBS r1, r0, r3
            CMPCS r1, r3
        JCS _(s)
            ADDCS r2, r2, r2
            ADDCS r3, r3, r3
            MOV r1, 0
_(c):       CMP r0, r3
        ADDCS r1, r1, r2
        SUBCS r0, r0, r3
        CMP r2, 1
        RETEQ
        JNE _(c)
            SHR r3, 1
            SHR r2, 1
            MOV r3, SHIFT_RESULT
            MOV r2, SHIFT_RESULT
#undef _

