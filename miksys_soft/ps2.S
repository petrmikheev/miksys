s1:     OUTS DEV_PS2_1, 0xF4 //0xED
        DJMI s1
//w1:     INS DEV_PS2_0, r0
//        DJMI w1
//        OUT DEV_SERIAL, r0
//        DJ s2
//s2:     OUTS DEV_PS2_0, 5
//        DJMI s2
        
l:      INS DEV_PS2_1, r0
        DJMI l
        OUT DEV_SERIAL, r0
        DJ l

