#define DATA_MEM_OFFSET 1024
//#define DEV_USB DEV_SERIAL
#define DEBUG_USB

#define ENDPOINT_IN 1
#define ENDPOINT_OUT 2

.macro pause val
        MOVS r9, 0xffff
        MOVS r10, val
$(m):
        JNE $(m)
            SUBS r9, r9, 1
            SUBEQS r10, r10, 1
            NOP
            NOP
.endmacro

        CMOV r0, 0
        CMOV MEM_ADDR_LO, LO(0x100000 + DATA_MEM_OFFSET)
        CMOV MEM_ADDR_HI, HI(0x100000 + DATA_MEM_OFFSET)
        READ r0, data_size
        CMOV r15, 16384 - 256 // stack pointer
wm:     TST IN_FLAGS, MEM_FLAG
        JNE wm
            NOP
            NOP
            NOP
            CCMOV [r15+2], 8192 // data buf
        //OUT DEV_USB, 0
//        CALL usb_request_func
//            CCMOV [r15], 0 // addr
//            CCMOV [r15+1], set_address
//            CCMOV [r15+3], 0 // data size
//            NOP

//        CALL usb_request_func
//            CCMOV [r15], 1 // addr
//            CCMOV [r15+1], set_configuration
//            CCMOV [r15+3], 0 // data size
//            NOP

        CALL usb_request_func
            CCMOV [r15], 0 // addr
            CCMOV [r15+1], get_descriptor
            CCMOV [r15+3], 18 // data size
            NOP

//        CALL usb_request_func
//            CCMOV [r15], 1 // addr
//            CCMOV [r15+1], get_conf_descr
//            CCMOV [r15+3], 32 // data size
//            NOP
//pause 512
        CALL usb_request_func
            CCMOV [r15], 1 // addr
            CCMOV [r15+1], usbms_reset
            CCMOV [r15+3], 0 // data size
            NOP
//pause 512
//        CALL usb_request_func
//            CCMOV [r15], 0x4000 | 128 | 1 // addr
//            CCMOV [r15+1], 0
//            CCMOV [r15+3], 1 // data size
//            NOP
//        CALL usb_request_func
//            CCMOV [r15], 1 // addr
//            CCMOV [r15+1], clear_halt_in
//            CCMOV [r15+3], 0 // data size
//            NOP

//        CALL usb_request_func
//            CCMOV [r15], 1 // addr
//            CCMOV [r15+1], clear_halt_out
//            CCMOV [r15+3], 0 // data size
//            NOP
//pause 512
//        CALL usb_request_func
//            CCMOV [r15], 0x2000 | (128*ENDPOINT_OUT) | 1 // addr
//            CCMOV [r15+1], usbms_read
//            CCMOV [r15+4], 0 // usb data parity
//            NOP
////pause 256
//        CALL usb_request_func
//            CCMOV [r15], 0x4000 | (128*ENDPOINT_IN) | 1 // addr
//            CCMOV [r15+1], 0
//            CCMOV [r15+3], 1 // data size
//            CCMOV [r15+4], 0 // usb data parity

//        CALL usb_request_func
//            CCMOV [r15], 1 // addr
//            CCMOV [r15+1], clear_halt_in
//            CCMOV [r15+3], 0 // data size
//            NOP

//        CALL usb_request_func
//            CCMOV [r15], 0x4000 | (128*ENDPOINT_IN) | 1 // addr
//            CCMOV [r15+1], 0
//            CCMOV [r15+3], 1 // data size
//            CCMOV [r15+4], 0 // usb data parity

        MOVS r10, [r15+3]
        MOVEQ OUT_LEDS, 6
        MOVNE OUT_LEDS, 15

        MOV r9, [r15+2]
        TST r9, 0x8000
        AND r9, r9, 0x7fff
        ADDNE r9, r9, 1
        CMOV r8, 8192
out_l:  CMP r8, r9
        JEQ out_l
            NOP
            NOP
            NOP
            NOP
out_w1: OUTS DEV_SERIAL, [r8]
        JMI out_w1
            MOV r10, [r8]
            SHR r10, 8
            NOP
            NOP
out_w2: OUTS DEV_SERIAL, SHIFT_RESULT
        JMI out_w2
            JPL out_l
            NOP
            NOP
            NOP
            ADD r8, r8, 1

#include "include/usb.H"

.data 0 DATA_MEM_OFFSET
set_address:    .const 8, 0x0500, 0x0001, 0x0000, 0x0000
get_descriptor: .const 8, 0x0680, 0x0100, 0x0000, 0x0012
get_conf_descr: .const 8, 0x0680, 0x0200, 0x0000, 0x0040
//usbms_get_max_lun: .const 8, 0xfea1, 0x0000, 0x0000, 0x0001
set_configuration: .const 8, 0x0900, 0x0001, 0x0000, 0x0000
//set_interface: .const 8, 0x0b01, 0x0000, 0x0000, 0x0000
usbms_reset: .const 8, 0xff21, 0x0000, 0x0000, 0x0000
clear_halt_in: .const 8, 0x0102, 0x0000, 0x0080 | ENDPOINT_IN, 0x0000
clear_halt_out: .const 8, 0x0102, 0x0000, ENDPOINT_OUT, 0x0000

usbms_read: .const 31, 0x5355, 0x4342, 0x0000, 0x0000
            .const     0x1000, 0x0000, 0x0080, 0x280a
            .const     0x0000, 0x0000, 0x0000, 0x0800
            .const     0x0000, 0x0000, 0x0000,   0x00

data_size:

