#include "../include/std.H"
#define DATA_CACHE_OFFSET 0x3000
#define DATA_MEM_OFFSET 1200
#define USB_BUF_OFFSET 0x2000

#define TEXT_FIELD_BEGIN 0x78b
#define TEXT_FIELD_END 0x800

.code 0x100000 0x0
        OUT DEV_PS2_1, 0xF4 // mouse turn on
        MOV r0, 0
mp:     SUBS r0, r0, 1
        DJNE mp
        IN DEV_PS2_1, r0
        
        CMOV r0, DATA_CACHE_OFFSET
        CMOV MEM_ADDR_LO, LO(0x100000 + DATA_MEM_OFFSET)
        CMOV MEM_ADDR_HI, HI(0x100000 + DATA_MEM_OFFSET)
        READ r0, DATA_END - DATA_CACHE_OFFSET

        MOV r15, 16384 - 256 // stack pointer
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0x6
        OUT DEV_VGA, 0x10
        OUT DEV_VGA, 0
        MOV r0, 0
        MOV r1, 0
        MOV r4, 0

l:      TST IN_FLAGS, MEM_FLAG
        JNE l
            SHR IN_TIME_MS4, 10
            AND r2, r1, 63
            CMP r2, SHIFT_RESULT
            ADDNE r1, r1, 1
        
        CALL printf_func
            AND r1, r1, 2047
            CCMOV [r15], 0        // buf
            CCMOV [r15+1], hello  // str
            CCMOV [r15+2], 0xff01 // color|flags
        
        MOV [r15+3], r1
        MOV [r15+4], r1
        MOV [r15+5], r1
                
        CALL printf_func
            SHR IN_TIME_MS4, 11
            CCMOV [r15+1], multiline_str  // str
            CCMOV [r15+2], 0x0000 // color|flags
            MOV OUT_LEDS, SHIFT_RESULT

/*CMOV MEM_ADDR_LO, 128
CMOV MEM_ADDR_HI, 0
WRITE r0, TEXT_FIELD_END
DJ l*/

        XOR r5, r4, IN_TIME_MS4
        TST r5, 0x400
        JEQ end_usb
            XORNES r4, r4, 0x400
            JNE usb_reset
            MOV r2, USB_BUF_OFFSET
            CMOV r6, usb_get_descriptor
            CCMOV [r15], 0 // addr
            CCMOV [r6+2], 0x0100 // device descriptor
        CALL usb_request_func
            CCMOV [r6+4], 0x0012 // descriptor size
            CCMOV [r15+1], usb_get_descriptor
            CCMOV [r15+3], 18 // data size
            CCMOV [r15+2], USB_BUF_OFFSET // data buf
        
        MOVS r8, [r15+3]
        CCMOV [r15], 640        // buf
        CCMOVEQ [r15+1], usb_not_connected  // str
        CCMOVNE [r15+1], usb_status  // str
        CCMOV [r15+2], 0x0300 // color|flags
        MOV r3, [r2+4]
        MOV [r15+3], r3
        CALL printf_func
            MOV r3, [r2+5]
            MOV [r15+4], r3
            MOV r3, [r2+6]
            MOV [r15+5], r3
        CMP r8, 0
        MOV r10, r2
        JEQ end_usb
            CALLNE show_usb_string_func
            NOP
            MOV r9, [r2+7]
            AND r9, r9, 0xff
            CMOV r8, 128 * 5 + 22
        CALL show_usb_string_func
            MOV r9, [r10+7]
            SHR r9, 8
            CMOV r8, 128 * 6 + 22
            MOV r9, SHIFT_RESULT
        CALL show_usb_string_func
            MOV r9, [r10+8]
            AND r9, r9, 0xff
            CMOV r8, 128 * 7 + 22
            NOP
end_usb:
/* Mouse */
        CMOV r14, mouse_settings
        INS DEV_PS2_1, r8
        DJMI mouse_show_text
mouse2: INS DEV_PS2_1, r9
        DJMI mouse2
mouse3: INS DEV_PS2_1, r10
        DJMI mouse3
        TST r8, 16
        ORNE r9, r9, 0xff00
        TST r8, 32
        ORNE r10, r10, 0xff00
        ADD r9, r9, [r14+1]
        ADD r10, r10, [r14+2]
        AND r8, r8, 7
        MOV [r14], r8
        MOV [r14+1], r9
        MOV [r14+2], r10
mouse_show_text:
        CCMOV [r15], 1152
        CCMOV [r15+1], mouse_str  // str
        MOV r8, [r14]
        MOV r9, [r14+1]
        MOV r10, [r14+2]
        CALL printf_func
            CCMOV [r15+2], 0x6000 // color|flags
            MOV [r15+3], r9
            MOV [r15+4], r10
            MOV [r15+5], r8

keyboard:
        CALL read_key_func
            CCMOV [r15], keyboard_settings
            CCMOV [r15+1], 1
            CMOV r9, keymap
            CMOV r5, keyboard_settings
        MOV r14, [r5 + (text_pointer - keyboard_settings)]
        MOVS r8, [r15+1]
        ADD r9, r8, r9
        JEQ l
            CMOVEQ MEM_ADDR_LO, 128
            CMOVEQ MEM_ADDR_HI, 0
            WRITEEQ r0, TEXT_FIELD_END
            CMP r8, 0x66
        CMOV r6, TEXT_FIELD_BEGIN
        SUBEQ r14, r14, 1
        CMP r14, r6
        MOVCC r14, r6
        MOV [r5 + (text_pointer - keyboard_settings)], r14
        MOV r5, [r5+1]
        CCMOV [r14], 0
        MOVS r9, [r9]
        RSBNES r8, r8, 0x5e
        DJLE keyboard
        SHR r9, 8
        TST r5, 0x8000
        MOVNE r9, SHIFT_RESULT
        CMOV r5, text_pointer
        AND r9, r9, 0xff
        J keyboard
            MOV [r14], r9
            ADD r14, r14, 1
            CMP r14, TEXT_FIELD_END
            MOVNE [r5], r14

usb_reset:
        OUT DEV_USB, 0
        DJ end_usb

// r8 - cursor position
// r9 - str num
show_usb_string_func:
        ADD r15, r15, 2
        MOV [r15], MEM_ADDR_LO
        MOV [r15+1], MEM_ADDR_HI
        OR r9, r9, 0x0300
        CMOV r2, USB_BUF_OFFSET
        CMOV r6, usb_get_descriptor
        CCMOV [r15+1], usb_get_descriptor
        CCMOV [r15], 0 // addr
        CALL usb_request_func
            MOV [r6+2], r9 // string num
            CCMOV [r6+4], 2 // data size
            CCMOV [r15+3], 2 // data size
            CCMOV [r15+2], USB_BUF_OFFSET+0x10 // data buf
        MOV r5, [r2+0x10]
        CALL usb_request_func
            AND r5, r5, 0xff
            MOV [r6+4], r5 // data size
            MOV [r15+3], r5  // data size
            CCMOV [r15+2], USB_BUF_OFFSET+0x10 // data buf
        MOVS r7, [r15+3]
        JEQ us_ret
        SUB r15, r15, 2
        ADD r2, r2, 0x11
        SUB r5, r5, 2
t:      
        SUBS r5, r5, 2
        MOV r7, [r2]
        JHI t
            ADD r2, r2, 1
            AND r7, r7, 0xff
            MOV [r8], r7
            ADD r8, r8, 1

us_ret: MOV MEM_ADDR_LO, [r15]
        MOV MEM_ADDR_HI, [r15+1]
        DRET

//#include "../include/div.H"
//#include "../include/string.H"
//#include "../include/usb.H"
#include "../include/keyboard.H"

.data DATA_CACHE_OFFSET DATA_MEM_OFFSET
hello:  .ascii "Hello, World!\n"
multiline_str:
        .ascii "Timer  Decimal: %u\n       Hex: 0x%x\n       Binary: %b\n"
mouse_str:
        .ascii "[Sound] Press key on the board\n         to play demo sound\n\n[Mouse] X: %d  Y: %d\n        Buttons: 00%B\n\n[Keyboard] "

mouse_settings: .const 0 // buttons
        .const 0 // X
        .const 0 // Y

usb_not_connected: .ascii "[USB] Not connected\n\n\n"
usb_status: .ascii "[USB] Vendor:  0x000%X\n      Product: 0x000%X\n      Device:  0x000%X\n"
usb_get_descriptor: .const 8, 0x0680, 0x0100, 0x0000, 0x0012

keyboard_settings: .const 1
shift_key: .const 0x12
text_pointer: .const TEXT_FIELD_BEGIN

keymap:
#include "../include/keymap.H"

DATA_END:

.data 0 1536 // дополнение нулями до нужного размера

