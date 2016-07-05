        MOV r8, 0
        MOV r2, 0
        MOV r14, 0
l:      //wait 72-17
        ADD r8, r8, 1
        ANDS r8, r8, 511
        CALLEQ send1
            CMP r8, 50
            CALLEQ send2
            NOP
            NOP
            NOP
            NOP
        NOP //INS DEV_USB0, r15
        NOP //MOVPL OUT_LEDS, 15
        NOP
        IN 3, r15
        SHR r15, 2
        NOP
        AND r15, SHIFT_RESULT, 7
        OR r15, r15, r14
        MOV OUT_LEDS, r15
        MOV r3, 72-17-1-12 // = 42 = 6 * 6
m:      SUBS r3, r3, 6
        JNE m
            INS DEV_USB0, r15
            MOVPL r14, 8
            NOP
            NOP

        SHL r1, 2
        IN 3, r0
        MOV r1, SHIFT_RESULT
        AND r0, r0, 3 //SHR r0, 2
        ADD r2, r2, 1
        OR r1, r1, r0 // SHIFT_RESULT
        TST r2, 3
        JEQ wr
            NOP
            NOP
            NOP
            NOP
        J l
            NOP
            NOP
            NOP
            NOP

wr:     J l
            OUT DEV_SERIAL, r1
            NOP
            NOP
            NOP

send1:
        OUTS DEV_USB0, 4
        JMI send1
            NOP
            NOP
            NOP
            NOP
        RET
            OUT DEV_USB0, 0x80
            OUT DEV_USB0, 0x2d
            OUT DEV_USB0, 0x00
            OUT DEV_USB0, 0x10

send2:
        OUTS DEV_USB0, 12
        JMI send2
            NOP
            NOP
            NOP
            NOP
        OUT DEV_USB0, 0x80
        OUT DEV_USB0, 0xc3
        OUT DEV_USB0, 0x80
        OUT DEV_USB0, 0x06
        OUT DEV_USB0, 0x00
        OUT DEV_USB0, 0x01
        OUT DEV_USB0, 0x00
        OUT DEV_USB0, 0x00
        RET
            OUT DEV_USB0, 0x40
            OUT DEV_USB0, 0x00
            OUT DEV_USB0, 0xdd
            OUT DEV_USB0, 0x94

