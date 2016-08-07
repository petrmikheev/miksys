#ifdef USB_READ_DEBUG
#define USB_STATUS OUT DEV_SERIAL, [SP+3]
#else
#define USB_STATUS
#endif
#define BUF8 r12
        DCALL big_pause
        CMOV BUF, 0x400
        MOV [ALL SP], ZERO // addr
        MOV [SP+1], BUF // command buf
        //MOV [SP+2], ZERO // data buf
        //MOV [SP+3], ZERO // do not read data
        
        CCMOV [BUF], 8
        CCMOV [BUF+1], 0x0500 // set address
        CCMOV [BUF+2], 1 // new address
        DCALL usb_request_func
        USB_STATUS
        
        CALL usb_request_func
            CCMOV [SP], 1 // addr
            CCMOV [SP+3], 0 // do not read data
            CCMOV [BUF+1], 0x0900 // set configuration
            CCMOV [BUF+7], 0x80
        USB_STATUS
        
        CALL usb_request_func
            CCMOV [BUF+1], 0x0680
            CCMOV [BUF+2], 0x0200
            CCMOV [BUF+4], 0x0040
            CCMOV [SP+3], 0x0040
        USB_STATUS
        MOV [BUF+4], ZERO
        MOV r11, [ZERO+10]
        
        CALL usb_request_func
            CCMOV [SP+3], 0 // do not read data
            CCMOV [BUF+1], 0xff21 // usbms_reset
            CCMOV [BUF+2], 0
            ADD r12, BUF, 8
        USB_STATUS
        
        TST r11, 0x80
        CALL usb_request_func
            CCMOV [SP+3], 0 // do not read data
            CCMOV [BUF+1], 0x0102 // clear halt
            CCMOVNE [BUF+3], 0x81
            CCMOVEQ [BUF+3], 0x82
        USB_STATUS
        CCMOV [r12], 0x280a
        
        CCMOV [SP+3], 0 // do not read data
        TST r11, 0x80
        CCMOVNE [BUF+3], 2
        CCMOVNE [BUF+3], 1
        DCALL usb_request_func
        USB_STATUS
        
        DCALL big_pause
        CCMOV [BUF], 31 // for usbms_read
        CCMOV [BUF+1], 0x5355
        CCMOV [BUF+2], 0x4342
        CCMOV [BUF+6], 0x60 // data size hi (for usbms_read) [BUF+5], 0x8000 //
        CCMOV [BUF8+2], 0x0800 // addr/512  0x2233
        CCMOV [BUF8+4], 0x30 // size/512 <<< 8 (for usbms_read) 0x4000 //
        TST r11, 0x80
        CCMOVNE [SP], 0x2000 | (128*2) | 1 // addr
        CCMOVEQ [SP], 0x2000 | (128*1) | 1 // addr
        CCMOV [SP+4], 0 // usb data parity
        DCALL usb_request_func // scsi read 6M
        USB_STATUS
        
        TST r11, 0x80
        CCMOVNE [SP], 0x4000 | (128*1) | 1 // addr
        CCMOVEQ [SP], 0x4000 | (128*2) | 1 // addr
        CCMOV [SP+4], 0 // usb data parity

        MOV r7, 0
        MOV r9, USB_DATA_SIZE/1024
        MOV r11, HI(MEM_OFFSET-512)
        MOV r10, LO(MEM_OFFSET-512)
usb_loop:
        CALL usb_request_func
            CCMOV [SP+2], 0
            CCMOV [SP+3], 1024 // data size
            ADD r10, r10, 512
            ADC r11, r11, 0
        MOV MEM_ADDR_LO, r10
        MOV MEM_ADDR_HI, r11
        WRITE ZERO, 512
        MOV r8, 0x100
        wait_mem
        ADD r7, r7, 1
        
        ADD SP, SP, 8
        CCMOV [r8], ('u'<<8)|'%'
        CCMOV [r8+1], ('%'<<8)|'/'
        CCMOV [r8+2], ('K'<<8)|'u'
        CCMOV [r8+3], 0
        MOV [SP+3], r7
        CALL printf_func
            CCMOV [SP+4], USB_DATA_SIZE/1024
            CCMOV [SP], 0        // buf
            MOV [SP+1], r8    // str
            CCMOV [SP+2], 0xff00 // color|flags
        MOV MEM_ADDR_LO, 18
        MOV MEM_ADDR_HI, 0
        WRITE ZERO, [SP]
        SUB SP, SP, 8
        wait_mem
        SUBS r9, r9, 1
        DJNE usb_loop

