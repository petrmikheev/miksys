
#define ENDPOINT_IN 1
#define ENDPOINT_OUT 2
#define COMMAND_BUF 4096-1
#define DATA_BUF 8192
#define MEM_OFFSET 0x200000

        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0x20
        OUT DEV_VGA, 0

        CMOV r15, 16384 - 256 // stack pointer
        CMOV r14, COMMAND_BUF
        CMOV r0, 0 // rm
        CCMOV [r15+2], DATA_BUF // rm

        MOV [ALL r14 + 1], r0
        MOV [ALL r14 + 5], r0
        MOV [ALL r14 + 9], r0
        MOV [ALL r14 + 13], r0

        MOV [r15+1], r14
        CCMOV [r14], 8

        CALL usb_request_func
            CCMOV [r15], 0 // addr
            CCMOV [r15+3], 0 // do not read data
            CCMOV [r14+1], 0x0500 // set address
            CCMOV [r14+2], 1 // new address
OUT DEV_SERIAL, [r15+3]
        CALL usb_request_func
            CCMOV [r15], 1 // addr
            CCMOV [r15+3], 0 // do not read data
            CCMOV [r14+1], 0x0900 // set configuration
            CCMOV [r14+7], 0x80
OUT DEV_SERIAL, [r15+3]
//        MOVS r11, 0xffff
//        MOVS r12, 512
//usb_setconf_pause:
//        JNE usb_setconf_pause
//            SUBS r11, r11, 1
//            SUBEQS r12, r12, 1
//            NOP
//            NOP
        CALL usb_request_func
            CCMOV [r15+3], 0 // do not read data
            CCMOV [r14+1], 0xff21 // usbms_reset
            CCMOV [r14+2], 0
            ADD r13, r14, 8
OUT DEV_SERIAL, [r15+3]
        CALL usb_request_func
            CCMOV [r15+3], 0 // do not read data
            CCMOV [r14+1], 0xff21 // usbms_reset
            CCMOV [r14+2], 0
            ADD r13, r14, 8
OUT DEV_SERIAL, [r15+3]
        CALL usb_request_func
            CCMOV [r15+3], 0 // do not read data
            CCMOV [r14+1], 0x0102 // clear halt
            CCMOV [r14+3], 0x80 | ENDPOINT_IN
            CCMOV [r13], 0x280a
OUT DEV_SERIAL, [r15+3]
        CALL usb_request_func
            CCMOV [r15+3], 0 // do not read data
            CCMOV [r14+3], ENDPOINT_OUT
            CCMOV [r14+6], 0x60 // data size hi (for usbms_read) [r14+5], 0x8000 //
            CCMOV [r13+4], 0x30 // size/512 <<< 8 (for usbms_read) 0x4000 //
OUT DEV_SERIAL, [r15+3]
        MOVS r11, 0xffff
        MOVS r12, 256
usb_reset_pause:
        JNE usb_reset_pause
            SUBS r11, r11, 1
            SUBEQS r12, r12, 1
            CCMOV [r14], 31 // for usbms_read
            CCMOV [r13+2], 0x0800 // addr/512  0x2233

        CALL usb_request_func // scsi read 6M
            CCMOV [r15], 0x2000 | (128*ENDPOINT_OUT) | 1 // addr
            CCMOV [r15+4], 0 // usb data parity
            CCMOV [r14+1], 0x5355
            CCMOV [r14+2], 0x4342
OUT DEV_SERIAL, [r15+3]
        CCMOV [r15], 0x4000 | (128*ENDPOINT_IN) | 1 // addr
        CCMOV [r15+4], 0 // usb data parity

        MOV r13, DATA_BUF
        MOV r12, 0x1000 //0x3000
        MOV r11, HI(MEM_OFFSET-256)
        MOV r10, LO(MEM_OFFSET-256)
usb_loop:
        CALL usb_request_func
            CCMOV [r15+2], DATA_BUF
            CCMOV [r15+3], 512 // data size
            ADD r10, r10, 256
            ADC r11, r11, 0
wm:     TST IN_FLAGS, MEM_FLAG
        DJNE wm
        
        SUBS r12, r12, 1
        JNE usb_loop
            MOV MEM_ADDR_LO, r10
            MOV MEM_ADDR_HI, r11
            NOP
            WRITE r13, 256

        MOV OUT_LEDS, 15
end:    DJ end

#include "include/usb.H"
#include "include/math.H"
#include "include/string.H"

