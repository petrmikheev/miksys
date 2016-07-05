#define MEM_OFFSET 0x100000
#define ENDPOINT_IN 1
#define ENDPOINT_OUT 2
#define USB_DATA_SIZE 0x800*1024 //0x1800*1024

//#define USB_READ_DEBUG

// 0 - 0x100      write buf
// 0x100 - 0x200  str_buf
// 0x200 - 0x300  stack
#define BUF r13
#define ZERO r14
#define SP r15
.macro wait_mem
$(m):   TST IN_FLAGS, MEM_FLAG
        DJNE $(m)
.endmacro
.code 0 0
        MOV OUT_LEDS, 1
        CMOV ZERO, 0
        CMOV BUF, 0x3000
        CMOV SP, 0x2000
clear_cache_loop:
        CCMOV [ZERO], 0
        SUBS ZERO, ZERO, 1
        DJNE clear_cache_loop
        
        CCMOV [BUF], ('B'<<8)|'['
        CCMOV [BUF+1], ('o'<<8)|'o'
        CCMOV [BUF+2], (' '<<8)|'t'
        CCMOV [BUF+3], ('o'<<8)|'l'
        CCMOV [BUF+4], ('d'<<8)|'a'
        CCMOV [BUF+5], ('r'<<8)|'e'
        CCMOV [BUF+6], ']'
        MOV [SP+1], BUF    // str
        CCMOV [SP+2], 0xff01 // color|flags
        DCALL printf_func
        CMOV MEM_ADDR_LO, 0
        CMOV MEM_ADDR_HI, 0
        WRITE ZERO, 40*128 // clear text buffer
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0x80
        wait_mem
        
main_loop:
        INS DEV_SERIAL, r1
        DJPL boot_from_serial
        TST IN_FLAGS, SOFTKEY_FLAG
        DJNE main_loop
        OUTS DEV_USB, 0
        DJPL boot_from_usb
        DJ main_loop

boot_from_serial:
        CCMOV [BUF], ('S'<<8)|' '
        CCMOV [BUF+1], ('r'<<8)|'e'
        CCMOV [BUF+2], ('a'<<8)|'i'
        CCMOV [BUF+3], 'l'
        CCMOV [BUF+4], 0
        DCALL printf_func
        CMOV MEM_ADDR_LO, 0
        CMOV MEM_ADDR_HI, 0
        WRITE ZERO, [SP]
        DCALL serial_read_word2
        ADD r5, r1, LO(MEM_OFFSET)
        DCALL serial_read_word
        ADD r6, r1, HI(MEM_OFFSET)
        
        CMOV r3, LO(MEM_OFFSET)
        CMOV r4, HI(MEM_OFFSET)
        CMOV r10, 0
serial_read_loop:
        DCALL serial_read_word
        MOV [ZERO], r1
        ADD r10, r10, r1
        MOV MEM_ADDR_LO, r3
        MOV MEM_ADDR_HI, r4
        WRITE ZERO, 1
        ADD r3, r3, 1
        ADC r4, r4, 0
        wait_mem
        CMP r3, r5
        CMPEQ r4, r6
        DJNE serial_read_loop
        DCALL serial_read_word
        CMP r10, r1
        DJNE checksum_failed
        DJ checkmem

boot_from_usb:
        CCMOV [BUF], ('U'<<8)|' '
        CCMOV [BUF+1], ('B'<<8)|'S'
        CCMOV [BUF+2], 0
        DCALL printf_func
        CMOV MEM_ADDR_LO, 0
        CMOV MEM_ADDR_HI, 0
        WRITE ZERO, [SP]
#include "usb_read.S"
        MOV r5, LO(MEM_OFFSET+USB_DATA_SIZE/2)
        MOV r6, HI(MEM_OFFSET+USB_DATA_SIZE/2)
        CMOV r10, 0xaa55
        DJ checkmem

serial_read_word:
        INS DEV_SERIAL, r1
        DJMI serial_read_word
serial_read_word2:
        INS DEV_SERIAL, r2
        SHL r2, 8
        DJMI serial_read_word2
        OR r1, r1, SHIFT_RESULT
        DRET

checksum_failed:
        CCMOV [BUF], ('h'<<8)|'C'
        CCMOV [BUF+1], ('c'<<8)|'e'
        CCMOV [BUF+2], ('s'<<8)|'k'
        CCMOV [BUF+3], ('m'<<8)|'u'
        CCMOV [BUF+4], ('f'<<8)|' '
        CCMOV [BUF+5], ('i'<<8)|'a'
        CCMOV [BUF+6], ('e'<<8)|'l'
        CCMOV [BUF+7], ('!'<<8)|'d'

        CALL printf_func
            MOV [BUF+8], ZERO
            CCMOV [SP], 0        // buf
            MOV [SP+1], BUF    // str
            CCMOV [SP+2], 0xff01 // color|flags

        CMOV MEM_ADDR_LO, 128
        CMOV MEM_ADDR_HI, 0
        WRITE ZERO, [SP]
end:    DJ end

big_pause:
        MOV r11, 0xffff
        MOV r9, 256
big_pause_loop:
        SUBS r11, r11, 1
        SUBEQS r9, r9, 1
        DJNE big_pause_loop
        DRET

//r6:r5 - end, r10 - checksum
checkmem:
        CMOV r0, LO(MEM_OFFSET)
        CMOV r1, HI(MEM_OFFSET)
checkmem_loop:
        MOV MEM_ADDR_LO, r0
        MOV MEM_ADDR_HI, r1
        ANDS r2, r0, 0xff
        READEQ r2, 0x100
        ADD r0, r0, 1
        ADC r1, r1, 0
        wait_mem
        SUB r10, r10, [r2]
        CMP r0, r5
        CMPEQ r1, r6
        DJNE checkmem_loop
        CMP r10, 0
        DJNE checksum_failed
        
        MOV OUT_LEDS, 0
        MOV MEM_ADDR_LO, LO(MEM_OFFSET)
        MOV MEM_ADDR_HI, HI(MEM_OFFSET)
        DRET
        
        /*CCMOV [BUF], ('K'<<8)|'O'
        CALL printf_func
            CCMOV [BUF+1], 0
            CCMOV [SP], 0        // buf
            MOV [SP+1], BUF    // str
            CCMOV [SP+2], 0xff01 // color|flags

        CMOV MEM_ADDR_LO, 128
        CMOV MEM_ADDR_HI, 0
        WRITE ZERO, [SP]
        DJ end*/

#include "../include/usb.H"
#include "../include/math.H"
#include "../include/string.H"

