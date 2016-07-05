#define zero r8
#define char_counter r9
#define size_hi [zero+127]
#define size_lo [zero+126]
#define checksum1 [zero+125]
#define checksum2 [zero+124]
.macro print4 c1, c2, c3, c4
        CALL print4_func
            CCMOV [zero], 0xff00 | c1
            CCMOV [zero+1], 0xff00 | c2
            CCMOV [zero+2], 0xff00 | c3
            CCMOV [zero+3], 0xff00 | c4
.endmacro

.macro clear_screen
        CMOV r0, 0
        CMOV zero, 0
        CMOV MEM_ADDR_HI, 0
$(m):   CMP r0, 40*128
        JNE $(m)
            MOV [ALL r0], zero
            MOV [ALL r0 + 4], zero
            ADD r0, r0, 8
            CMOV MEM_ADDR_LO, 0
        WRITE zero, 40*128
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0
        OUT DEV_VGA, 0x04
        OUT DEV_VGA, 0x21
        OUT DEV_VGA, 0x80
$(m)_wm:
        TST IN_FLAGS, MEM_FLAG
        JNE $(m)_wm
            CMOV char_counter, 0
            MOV OUT_LEDS, 0
            NOP
            NOP
.endmacro

.macro read_data
        CALL read_word_func     // size_lo = read_word();
            CMOV r3, 0
            CMOV r4, 0x10
            MOV checksum1, zero // checksum1 = 0;
            NOP
        CALL read_word_func     // size_hi = read_word();
            MOV size_lo, r1
            NOP
            AND r14, r4, 3
            MOV r15, 7
        MOV size_hi, r1         // r1 = read_word();
        print4 '.', '.', '.', '.'
$(m)_loop:
        CALL read_word_func     // do {
            NOP                 //      shift_result = 7 >> (r4 & 3);
            SHR r15, r14        //      out_leds = ~shift_result;
            NOP
            MOV OUT_LEDS, NOT SHIFT_RESULT
        MOV [zero], r1
        MOV MEM_ADDR_LO, r3
        MOV MEM_ADDR_HI, r4
        WRITE zero, 1           //      write(r4:r3, r1, 1);
        AND r14, r4, 3
$(m)_srl_wm:
        TST IN_FLAGS, MEM_FLAG  //      wait_mem();
        JNE $(m)_srl_wm
            ADD r5, r3, 1       
            ADC r6, r4, -0x10
            CMP r5, size_lo
            CMPEQ r6, size_hi
        JNE $(m)_loop                //      r4:r3 ++;
            ADD r3, r3, 1       //      checksum1 += r1
            ADC r4, r4, 0
            MOV r10, checksum1  // } while (r4:r3 - 0x100000 != size_hi:size_lo);
            ADD checksum1, r10, r1
.endmacro

.macro check
        CALL read_word_func     // r1 = read_word(); // checksum
            CMOV r0, 0
            CMOV r3, 0
            CMOV r5, 0x10
            NOP
$(m):   MOV MEM_ADDR_LO, r0
        MOV MEM_ADDR_HI, r5
        ANDS r2, r0, 0xff
        OR r2, r2, 0x100
        READEQ r2, 0x100
        NOP
$(m)_wm:
        TST IN_FLAGS, MEM_FLAG
        JNE $(m)_wm
            ADDEQ r0, r0, 1
            ADCEQ r4, r5, -0x10
            CMP r0, size_lo
            CMPEQ r4, size_hi
        JNE $(m)
            ADD r3, r3, [r2]
            ADD r5, r4, 0x10
            MOV MEM_ADDR_LO, 0
            MOV MEM_ADDR_HI, 0x10
.endmacro

.code 0 0
        clear_screen
        print4 'B', 'o', 'o', 't'
        print4 ' ', 'f', 'r', 'o'
        print4 'm', ' ', 's', 'e'
        print4 'r', 'i', 'a', 'l'
        read_data
        check
        CMP r3, r1
        RETEQ // if (checksum == correct_checksum) goto 0x10:0000
            MOV checksum2, r1
            MOV OUT_LEDS, 0
            CMOV char_counter, 128
            NOP
        print4 'C', 'h', 'e', 'c'
        print4 'k', 's', 'u', 'm'
        print4 ' ', 'f', 'a', 'i'
        print4 'l', 'e', 'd', '!'
end:    J end
            MOV r1, checksum1
            CMP r1, checksum2
            MOVEQ OUT_LEDS, 6
            MOVNE OUT_LEDS, 15

print4_func:
        MOVS r10, MEM_ADDR_LO
        MOV r11, MEM_ADDR_HI
        MOV MEM_ADDR_LO, char_counter
        MOV MEM_ADDR_HI, 0
        WRITE zero, 4
p4f_wm: JNE p4f_wm
            MOV MEM_ADDR_LO, r10
            MOV MEM_ADDR_HI, r11
            RETEQ
            TST IN_FLAGS, MEM_FLAG
            ADD char_counter, char_counter, 4
            NOP
            NOP

read_word_func:
        INS DEV_SERIAL, r1
        JMI read_word_func
            NOP
            NOP
            NOP
            NOP
rwf:    INS DEV_SERIAL, r2
        JMI rwf
            RETPL
            SHL r2, 8
            NOP
            ORPL r1, r1, SHIFT_RESULT
            NOP

