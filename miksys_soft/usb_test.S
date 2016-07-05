#define DATA_MEM_OFFSET 320
//#define DEV_USB DEV_SERIAL
//#define DEBUG_USB

#define ENDPOINT_IN 1
#define ENDPOINT_OUT 2

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
            NOP

        CALL usb_request_func
            CCMOV [r15], 0x2000 | (128*ENDPOINT_OUT) | 1 // addr
            CCMOV [r15+1], usbms_read
            CCMOV [r15+4], 0 // usb data parity
            NOP

l:      J l
            NOP
            NOP
            NOP
            NOP

#include "include/usb.H"

.data 0 DATA_MEM_OFFSET
usbms_read: .const 31, 0x5355, 0x4342, 0x0000, 0x0000
            .const     0x1000, 0x0000, 0x0080, 0x280a
            .const     0x0000, 0x0000, 0x0000, 0x0800
            .const     0x0000, 0x0000, 0x0000,   0x00
data_size:

