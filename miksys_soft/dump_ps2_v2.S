l:      //wait 108*2-6
        NOP
        NOP
        NOP
        NOP
        NOP
        MOV r3, 32 * 6
m:      SUBS r3, r3, 6
        JNE m
            NOP
            NOP
            NOP
            NOP

        IN 7, r0
        J l
            NOP
            NOP
            NOP
            OUT DEV_SERIAL, r0

