.code 0x0
        #define odd r2
        #define new_byte r3
        #define val r4
        #define addr r5
        CMOV r1, 0
        CMOV r0, 0
        CMOV odd, 0
        CMOV addr, 0
$(m):   CMP r0, LO(640*480)
        CMPEQ r1, HI(640*480)
        JEQ write
            CMOVEQ r1, 0
            CMOVEQ r0, 0
            NOP
            NOP
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
wait_mem:
            TST IN_FLAGS, MEM_FLAG
        JNE wait_mem
            JEQ $(m)
            MOV MEM_ADDR_HI, r1
            WRITEEQ addr, 16
            ADDEQ r0, r0, 16
            ADCEQ r1, r1, 0

write:
        #define WBLOCK_SIZE 1024
        TST IN_FLAGS, MEM_FLAG
        JNE write
            MOV MEM_ADDR_LO, r0
            MOV MEM_ADDR_HI, r1
            CMOV r2, 0
            READEQ r2, WBLOCK_SIZE
        
        MOVS r3, 1
wait_mem2:
        JNE wait_mem2
            ADDEQ r0, r0, WBLOCK_SIZE
            ADCEQ r1, r1, 0
            TST IN_FLAGS, MEM_FLAG
            NOP
        
wloop:  OUTS DEV_SERIAL, [r2]
        JMI wloop
            MOV r3, [r2]
            SHR r3, 8
            NOP
            NOP
            NOP
wloop2: OUTS DEV_SERIAL, SHIFT_RESULT
        JMI wloop2
            ADDPL r2, r2, 1
            CMP r2, WBLOCK_SIZE
            JNE wloop
            NOP
            NOP
            NOP
            NOP
        
        CMP r0, LO(640*480)
        CMPEQ r1, HI(640*480)
        JNE write
end:    JEQ end
            MOVEQ OUT_LEDS, 15
            NOP
            NOP
            NOP

