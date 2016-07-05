        OUT DEV_USB0, 4
        OUT DEV_USB0, 0x80
        OUT DEV_USB0, 0x2d
        OUT DEV_USB0, 0x00
        OUT DEV_USB0, 0x10
p:      OUTS DEV_USB0, 12
        JMI p
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
        OUT DEV_USB0, 0x40
        OUT DEV_USB0, 0x00
        OUT DEV_USB0, 0xdd
        OUT DEV_USB0, 0x94

        MOV r2, 0
l:      //wait 72-17
        MOV r3, 72-17-1 // = 54 = 6 * 9
m:      SUBS r3, r3, 6
        JNE m
            NOP
            NOP
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

