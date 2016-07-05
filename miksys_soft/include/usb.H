//#define DEBUG_USB

#define _(x) usb_H_##x

/* Отправка запроса usb
* (addr, data_out, data_in, size_in, parity) -> (NULL, NULL, data_buf, ok, parity) 
* addr = type | usb_endpoint<<7 | usb_address
* data_out -> size_out, bytes10, bytes32, ...
* type = 0x0000       : send request (with setup token) and receive answer
* type = 0x2000       : send data (with data_out token)
* type = 0x4000       : receive data
* type = 0xa000       : send empty data
*/
usb_request_func:

#define addr [r15]
#define data_out [r15+1]
#define data_in [r15+2]
#define size_in [r15+3]
#define parity [r15+4]
#define USB_TOKEN_SETUP 0x2d
#define USB_TOKEN_OUT 0xe1
#define USB_TOKEN_IN 0x69
#define USB_DATA0 0xc3
#define USB_DATA1 0x4b
#define USB_ACK 0xd2
#define USB_NAK 0x5a

        MOV [r15+5], r8
        MOV [r15+6], r9
        MOV [r15+7], r10
        MOV [r15+8], r11
        MOV [r15+9], r12
        MOV [r15+10], r7
        
        MOV r7, addr
        MOV r12, 0 // errors counter
_(send_data):
        CMP r12, 0x8000
        JCS _(ret)
            CCMOVCS size_in, 0 // return error (no ACK or not connected)
            MOV r10, data_out
            MOV r8, 0
            MOV r9, USB_TOKEN_SETUP
        OUTS DEV_USB, 3 // send token
        ADDMI r12, r12, 1
        JMI _(send_data)
            TST r7, 0x2000
            MOVNE r9, USB_TOKEN_OUT
            TST r7, 0x4000
            MOVNE r9, USB_TOKEN_IN
        JNE _(receive_data)
            SHR r7, 8
            OUT DEV_USB, r9
            OUT DEV_USB, r7
            OUT DEV_USB, SHIFT_RESULT
        TST r7, 0xe000
        MOVEQ r9, 0
        MOVNE r9, parity
        XOR r9, r9, 1
        MOVS parity, r9
        MOVNE r9, USB_DATA0
        MOVEQ r9, USB_DATA1
        MOV r11, 0
//OUT DEV_SERIAL, 0x44
_(sd):  CMP r11, 0x8000
        JCS _(ret)
            CCMOVCS size_in, 0 // return error (not connected)
            TST r7, 0x8000
            MOVEQ r8, [r10]
            ADD r8, r8, 1
        OUTS DEV_USB, r8 // send data
        JMI _(sd)
            SUB r8, r8, 1
            ADDMI r11, r11, 1
            ADDPL r10, r10, 1
            CMPPL r8, 0
        JEQ _(skip_send_loop)
            OUT DEV_USB, r9
_(send):    MOV r9, [r10]
            SUBS r8, r8, 2
        JHI _(send)
            ADD r10, r10, 1
            SHR r9, 8
            OUT DEV_USB, r9
            OUT DEV_USB, SHIFT_RESULT
            
_(skip_send_loop):
        MOV r9, 0x8000 // max attempts to receive ACK is 32768
_(rack):
        INS DEV_USB, r8
        ADDMIS r9, r9, 1
        JMI _(rack)
#ifdef DEBUG_USB
            MOVEQ r0, data_in
            CMOVEQ r1, 0xffdd
            ADDEQ r0, r0, 1
            MOVEQ [r0], r1
            MOVEQ data_in, r0
#endif
            JEQ _(send_data)
            ADDEQ r12, r12, 1024 // go to next send data attempt (no answer)
            AND r10, r7, 0x2000
            NOP
        IN DEV_USB, r8
        CMP r8, USB_ACK
        JNE _(send_data) 
            ADDNE r12, r12, 1024 // go to next send data attempt (answer is not ACK)
            CMPEQ r10, 0x2000
        JEQ _(ret)
            CCMOVEQ size_in, 1 // return success (send data)
            MOV r12, 0

_(send_in_token):
            MOVS r11, 0x100 // pause
_(rp):      SUBS r11, r11, 1
        DJNE _(rp)
_(send_in_token_without_pause):
        MOV r10, 0x8000
        SHR r7, 8
_(ot):  OUTS DEV_USB, 3
        ADDMIS r10, r10, 1
        JMI _(ot)
            MOVEQ r12, 0x8000
            CMPPL r12, 0x8000
        JPL _(ret)
            CCMOVPL size_in, 0 // return error (32 invalid packages in a row)
            OUT DEV_USB, USB_TOKEN_IN
            OUT DEV_USB, r7
            OUT DEV_USB, SHIFT_RESULT
_(receive_data):
        MOV r9, 0x8000 // max attempts to receive data is 32768
_(rdata):
        INS DEV_USB, r8
        ADDMIS r9, r9, 1
        JMI _(rdata)
#ifdef DEBUG_USB
            MOVEQ r0, data_in
            CMOVEQ r1, 0xdddd
            ADDEQ r0, r0, 1
            MOVEQ [r0], r1
            MOVEQ data_in, r0
#endif
            JEQ _(send_in_token)
            ADDEQ r12, r12, 1024 // go to next attempt (no answer)
            MOV r10, parity
            XORS r10, r10, 1
            MOVNE r9, USB_DATA0
        MOVEQ r9, USB_DATA1
        IN DEV_USB, r11
#ifdef DEBUG_USB
        MOV r0, data_in
        MOV r1, 0xff00
        MOV r2, 0xee00
        OR [r0], r1, r8
        OR [r0+1], r2, r11
        ADD r0, r0, 2
        MOV data_in, r0
#endif
        CMP r11, r9
//        CMP r11, USB_DATA0
//        CMPNE r11, USB_DATA1
        TSTEQ r8, 0x80
        JNE _(send_in_token)
            MOVEQ parity, r10
            CMP r11, USB_NAK
            ADDEQ r12, r12, 1 // NAK
            ADDNE r12, r12, 1024 // STALL, parity error, or checksum error
//        OUT DEV_SERIAL, r11
        SUBS r8, r8, 1
        RSB r12, r8, size_in
        JEQ _(ret)
            CCMOVEQ size_in, 0
            CMPEQ r12, 0
            CCMOVEQ size_in, 1
            MOV r9, data_in
        MOV size_in, r12
_(rloop):
        IN DEV_USB, r11
        IN DEV_USB, r12
        SUBS r8, r8, 2
        JHI _(rloop)
            SHL r12, 8
            ADD r9, r9, 1
            OR r11, r11, SHIFT_RESULT
            MOV [r9], r11
        MOV r12, 0
        CMP r12, size_in
        JLT _(send_in_token_without_pause)
            MOV data_in, r9
            CCMOVGE size_in, 1
            TSTGE r7, 0xe000
        JEQ _(send_data) // send empty data to finish request
            AND r7, r7, 0x1fff
            OR r7, r7, 0xa000
            CCMOVEQ parity, 1
_(ret):     MOV r8, [r15+5]
        MOV r9, [r15+6]
        RET
            MOV r12, [r15+9]
            MOV r7, [r15+10]
            MOV r10, [r15+7]
            MOV r11, [r15+8]

#undef USB_TOKEN_SETUP
#undef USB_TOKEN_OUT
#undef USB_TOKEN_IN
#undef USB_DATA0
#undef USB_DATA1
#undef USB_ACK
#undef USB_NAK
#undef request
#undef parity
#undef data_buf
#undef addr
#undef size_in
#undef _

