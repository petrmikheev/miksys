#define DATA_MEM_OFFSET 512
#define BUF_OFFSET 2048

        CMOV r0, 0
        CMOV r15, BUF_OFFSET
        CMOV MEM_ADDR_LO, LO(0x100000 + DATA_MEM_OFFSET)
        CMOV MEM_ADDR_HI, HI(0x100000 + DATA_MEM_OFFSET)
        READ r0, data_size
        MOV OUT_LEDS, 9
wm:     TST IN_FLAGS, MEM_FLAG
        JNE wm
            NOP
            NOP
            NOP
            NOP
        
init:   OUTS DEV_USB0, 0
        JMI init
            NOP
            NOP
            NOP
            NOP
        
i2:     OUTS DEV_USB0, 4
        JMI i2
            NOP
            NOP
            NOP
            NOP
        OUT DEV_USB0, 0x80
        OUT DEV_USB0, 0xa5
        OUT DEV_USB0, 0x00
        OUT DEV_USB0, 0x10
        
loop:   CMP r0, data_size
        JCS get_result
            NOP
            MOV r1, [r0]
            MOVCS OUT_LEDS, 15
            CMP r1, 'S'
        ADD r0, r0, 1
        CALLEQ send
            CMP r1, 'D'
            CALLEQ delay
            CMP r1, 'R'
            CALLEQ receive
            NOP
            NOP
            NOP
            NOP
        J loop
            NOP
            NOP
            NOP
            NOP

get_result:
        MOV r0, BUF_OFFSET
grl:    CMP r0, r15
        JEQ grl
            NOP
            NOP
            NOP
            NOP
grs:    OUTS DEV_SERIAL, [r0]
        JMI grs
        JPL grl
            NOP
            NOP
            NOP
            ADD r0, r0, 1

delay:
        MOV r1, [r0]
dl:     IN 3, r2
        MOV [r15], r2
        ADD r15, r15, 1
        CMP r1, 0
        JNE dl
            RETEQ
            SUB r1, r1, 1
            NOP
            NOP
            ADDEQ r0, r0, 1

send:
        NOP
        NOP
        MOV r1, [r0]
        OUTS DEV_USB0, r1
        JMI send
            ADDPL r0, r0, 1
            IN 3, r2
            MOV [r15], r2
            ADD r15, r15, 1
sl:     CMP r1, 0
        RETEQ
            NOP
            NOP
            NOP
            NOP
        OUT DEV_USB0, [r0]
        J sl
            ADD r0, r0, 1
            SUB r1, r1, 1
            NOP
            NOP

receive:
        INS DEV_USB0, r1
        JMI receive
            NOP
            NOP
            NOP
            NOP
        MOV [r15], r1
        ADD r15, r15, 1
rl:     CMP r1, 0
        RETEQ
            NOP
            NOP
            NOP
            NOP
        J rl
            IN DEV_USB0, r2
            MOV [r15], r2
            ADD r15, r15, 1
            SUB r1, r1, 1

.data 0 DATA_MEM_OFFSET

//    .const 'S', 4, 0x80, 0xa5, 0x00, 0x10
//    .const 'D', 17991
//    .const 'S', 4, 0x80, 0xa5, 0x00, 0x10

    .const 'D', 100
    //.const 'S', 4, 0x80, 0xa5, 0x00, 0x10
    .const 'S', 4, 0x80, 0x2d, 0x00, 0x10
    .const 'S', 12, 0x80, 0xc3, 0x80, 0x06, 0x00, 0x01, 0x00, 0x00, 0x40, 0x00, 0xdd, 0x94
    .const 'D', 200
    
    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'D', 4000
    
//    .const 'S', 2, 0x80, 0xd2
    
//    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
//    .const 'R'
//    .const 'S', 2, 0x80, 0xd2
//    
//    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
//    .const 'R'
//    .const 'S', 2, 0x80, 0xd2
data_size:

