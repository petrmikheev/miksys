#define OK 0x1c00 | '+'
#define FAIL 0xe000 | 'X'

.macro test_cmp1
        CMOV r3, 17
        CMOV r2, FAIL
        CMP r3, 5
        CMOVHI r2, OK
        CMOVEQ r2, FAIL
        CMOVCC r2, FAIL
        CALL print_r2
            CMOVMI r2, FAIL
            CMOVVS r2, FAIL
            CMOVLS r2, FAIL
            CMOVLE r2, FAIL
.endmacro

.macro test_cmp2
        CMOV r3, -4
        CMOV r2, 0
        CMP r3, 3
        ADDMI r2, r2, 1
        ADDLT r2, r2, 1
        ADDHI r2, r2, 1
        CMOVEQ r2, 0
        CMOVPL r2, 0
        CALL print_r2
            CMOVLE r2, 0
            CMP r2, 3
            CMOVEQ r2, OK
            CMOVNE r2, FAIL
.endmacro

.macro test_wadd
        CMOV r4, 0x8100
        CMOV r5, 0x0021
        CMOV r2, 0x8800
        CMOV r3, 0x0012
        ADD r6, r2, r4
        ADCS r7, r3, r5
        CMOV r2, OK
        CMOVCS r2, FAIL
        CALL print_r2
            CMP r6, 0x0900
            CMOVVS r2, FAIL
            CMPEQ r7, 0x34
            CMOVNE r2, FAIL
.endmacro

.macro test_wsub
        CMOV r4, 0x8100
        CMOV r5, 0x0021
        CMOV r2, 0x8800
        CMOV r3, 0x0012
        SUB r6, r2, r4
        SBCS r7, r3, r5 // r7:r6 = fff1 0700
        CMOV r2, OK
        CMOVPL r2, FAIL
        CALL print_r2
            CMOVCS r2, FAIL
            CMP r6, 0x0700
            CMPEQ r7, 0xfff1
            CMOVNE r2, FAIL
.endmacro

.macro test_rsb
        CMOV r3, 0x5555
        CMOV r2, 0x1234
        RSB r2, r2, r3
        CALL print_r2
            CMOV r3, 0x4321
            CMP r3, r2
            CMOVEQ r2, OK
            CMOVNE r2, FAIL
.endmacro

.macro test_and
        CMOV r3, 0xff00
        CMOV r2, 0x1234
        CALL print_r2
            AND r2, r2, NOT r3
            CMP r2, 0x34
            CMOVEQ r2, OK
            CMOVNE r2, FAIL
.endmacro

.macro test_or
        CMOV r2, 1
        CALL print_r2
            OR r2, r2, 4
            CMP r2, 5
            CMOVEQ r2, OK
            CMOVNE r2, FAIL
.endmacro

.macro test_xor
        CMOV r3, 0x7
        CMOV r2, 0xfe
        CALL print_r2
            XOR r2, r2, r3
            CMP r2, 0xf9
            CMOVEQ r2, OK
            CMOVNE r2, FAIL
.endmacro

.macro test_cache
        CMOV r3, 0x100
        CMOV r2, FAIL
        ADD r3, r3, 1
        CCMOV [r3+2], 5
        ADD [r3+1], r3, r3
        MOV r0, 5
        CALL print_r2
            CMOV r1, 0x202
            CMP r1, [r3]
            CMPEQ r0, [r3+1]
            CMOVEQ r2, OK
.endmacro

.macro test_shift
        CMOV r3, 10
        SHL r3, 5
        CALL print_r2
            SHR SHIFT_RESULT, 1
            CMOV r2, FAIL
            CMP SHIFT_RESULT, 160
            CMOVEQ r2, OK
.endmacro

.macro test_mul
        CMOV r3, 1001
        CMOV r4, 502
        CMOV r2, FAIL
        MUL r3, r4
        CALL print_r2
            CMOV r6, 43750
            CMP r6, MUL_RESULT_LO
            CMPEQ MUL_RESULT_HI, 7
            CMOVEQ r2, OK
.endmacro

.macro test_simd
        MOV r15, 0
        CMOV r2, OK
        AND r0, IN_FLAGS, 3
        MOV [ALL r15], r0
        NOP
        NOP
        NOP
        ADD r1, r15, [r15]
        ADD r1, r1, [r15+1]
        CALL print_r2
            ADD r1, r1, [r15+2]
            ADD r1, r1, [r15+3]
            CMP r1, 6
            CMOVNE r2, FAIL
.endmacro

.macro test_ram
        CMOV r3, 0x100
        CMOV MEM_ADDR_LO, 0xfe
        CMOV MEM_ADDR_HI, 1
        CCMOV [r3 + 0], 1
$(m)_1: TST IN_FLAGS, MEM_FLAG
        JNE $(m)_1
            CCMOV [r3 + 1], 2
            CCMOV [r3 + 2], 3
            CCMOV [r3 + 3], 4
            CCMOV [r3 + 4], 5
        WRITE r3, 5
        MOVS MEM_ADDR_LO, 0xff
$(m)_2: JNE $(m)_2
            TST IN_FLAGS, MEM_FLAG
            NOP
            NOP
            NOP
        READ r3, 3
        CMOV r2, FAIL
$(m)_3: TST IN_FLAGS, MEM_FLAG
        JNE $(m)_3
            MOV r4, [r3]
            MOV r5, [r3 + 1]
            MOV r6, [r3 + 2]
            MOV r7, [r3 + 3]
        MOV r0, [r3 + 4]
        CMP r4, 2
        CMPEQ r5, 3
        CALL print_r2
            CMPEQ r6, 4
            CMPEQ r7, 4
            CMPEQ r0, 5
            CMOVEQ r2, OK
.endmacro

.macro read_serial_loop
        #define odd r2
        #define new_byte r3
        #define val r4
        #define addr r5
        CMOV r1, 1
        CMOV r0, 0
        CMOV odd, 0
        CMOV addr, 0
$(m):
        INS DEV_SERIAL, new_byte
        JMI $(m)
            SHR IN_TIME_MS4, 11
            XORPLS odd, odd, 1
            MOV OUT_LEDS, SHIFT_RESULT
            SHL new_byte, 8
        JNE $(m)
            MOVNE val, new_byte
            OREQ val, val, SHIFT_RESULT
            CMPEQ addr, 15
            MOV MEM_ADDR_LO, r0
        JNE $(m)
            MOV [addr], val
            CMOVEQ addr, 0
            ADDNE addr, addr, 1
$(m)_wait_ram:
            TST IN_FLAGS, MEM_FLAG
        JNE $(m)_wait_ram
            JEQ $(m)
            MOV MEM_ADDR_HI, r1
            WRITEEQ addr, 16
            ADDEQ r0, r0, 16
            ADCEQ r1, r1, 0
.endmacro

// ****************************

#define text_pos r8

.macro init_vga
        TST IN_FLAGS, SOFTKEY_FLAG
        JEQ $(m)_0
            OUT DEV_VGA, 0
            OUT DEV_VGA, 0
            OUT DEV_VGA, 0
            NOP
        J $(m)_end
            NOP
            OUT DEV_VGA, 0
            OUT DEV_VGA, 1
            OUT DEV_VGA, 0
$(m)_0:
        OUT DEV_VGA, 0x04
        OUT DEV_VGA, 0x21
        OUT DEV_VGA, 0x80
$(m)_end:
.endmacro

.macro clear_text
        CMOV r0, 0
        CMOV r1, 0
        CMOV MEM_ADDR_HI, 0
$(m):   CMP r0, 40*128
        JNE $(m)
            MOV [ALL r0], r1
            MOV [ALL r0 + 4], r1
            ADD r0, r0, 8
            CMOV MEM_ADDR_LO, 0
        CMOV text_pos, 0
        WRITE text_pos, 40*128
.endmacro

//.code 0x0
        init_vga
        clear_text
        CALL print_r2
            CMOV r2, 0xff00 | '['
            NOP
            NOP
            NOP
        test_cmp1   // 1
        test_cmp2   // 2
        test_wadd   // 3
        test_wsub   // 4
        test_rsb    // 5
        test_and    // 6
        test_or     // 7
        test_xor    // 8
        test_shift  // 9
        test_mul    // 10
        test_cache  // 11
        test_simd   // 12 
        test_ram    // 13
        CALL print_r2
            CMOV r2, 0xff00 | ']'
            NOP
            NOP
            NOP
        read_serial_loop

print_r2:
        OUTS DEV_SERIAL, r2
        JMI print_r2
            NOP
            NOP
            MOV [text_pos], r2
print_wait_ram:
            TST IN_FLAGS, MEM_FLAG
        JNE print_wait_ram
            RETEQ
            MOVEQ MEM_ADDR_HI, 0
            MOVEQ MEM_ADDR_LO, text_pos
            WRITEEQ text_pos, 1
            ADD text_pos, text_pos, 1

