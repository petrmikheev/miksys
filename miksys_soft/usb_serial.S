#define DATA_MEM_OFFSET 512
#define BUF_OFFSET 8192

        CMOV r0, 0
        CMOV r15, BUF_OFFSET
        CMOV MEM_ADDR_LO, LO(0x100000 + DATA_MEM_OFFSET)
        CMOV MEM_ADDR_HI, HI(0x100000 + DATA_MEM_OFFSET)
        READ r0, data_size
        MOV OUT_LEDS, 9
wm:     TST IN_FLAGS, MEM_FLAG
        JNE wm
loop:       CMP r0, data_size
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
dl:     CMP r1, 0
        JNE dl
            RETEQ
            SUB r1, r1, 1
            NOP
            NOP
            ADDEQ r0, r0, 1

send:
        MOV r1, [r0]
        OUTS DEV_USB0, r1
        JMI send
            ADDPL r0, r0, 1
            NOP
            NOP
            NOP
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

    .const 'S', 0
    .const 'S', 3, 0xa5, 0x00, 0x10
    //.const 'D', 17992
    //.const 'S', 4, 0x80, 0xa5, 0x01, 0xe8
    //.const 'D', 17992
    //.const 'S', 4, 0x80, 0xa5, 0x02, 0xa8
    
    .const 'S', 3, 0x2d, 0x00, 0x10
    .const 'S', 11, 0xc3, 0x80, 0x06, 0x00, 0x01, 0x00, 0x00, 0x40, 0x00, 0xdd, 0x94
    .const 'R'

    .const 'S', 3, 0x69, 0x00, 0x10
    .const 'R'
/*    .const 'D', 32000
    
    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000
    
    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000
    
    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000
    
    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000 */
/*
    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000
    
    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000
    
    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000

    .const 'S', 4, 0x80, 0x69, 0x00, 0x10
    .const 'R'
    .const 'D', 32000
*/    
data_size:

