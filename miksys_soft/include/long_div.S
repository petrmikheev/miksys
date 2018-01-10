
/* Деление с остатком
* (r0=делимое, r1=делитель) -> (r0=остаток, r1=частное)
* Используются регистры r2, r3

* (r1:r0=делимое, r3:r2=делитель) -> (r1:r0=остаток, r3:r2=частное)
* Используются регистры r4, r5, r12, r13
*/
r1 -> r2
r2 -> r4
r3 -> r12
long_divide_func:
#define _(x) long_divide_func_##x
        MOV r13, r3
        MOVS r12, r2
        CMPEQ r13, 0
        RETEQ
            CMOVEQ r2, 0xffff
            CMOVEQ r3, 0xffff
            MOV r4, 1
            MOV r5, 0
        //TODO
_(s):   SUBS r2, r0, r12
        CMPCS r2, r12
        JCS _(s)
            ADDCS r4, r4, r4
            ADDCS r12, r12, r12
            MOV r2, 0
_(c):       CMP r0, r12
        ADDCS r2, r2, r4
        SUBCS r0, r0, r12
        CMP r4, 1
        RETEQ
        JNE _(c)
            SHR r12, 1
            SHR r4, 1
            MOV r12, SHIFT_RESULT
            MOV r4, SHIFT_RESULT
#undef _

