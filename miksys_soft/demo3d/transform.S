#define _(x) transform_##x
        CMOV r13, tmp1
        CMOV MEM_ADDR_HI, HI(MEMORY_BASE_ADDR + MEMORY_SIN_TABLE_OFFSET)
        MOV r1, [ZERO + control_x]
        AND r0, r1, 0xff
        ADD r0, r0, LO(MEMORY_BASE_ADDR + MEMORY_SIN_TABLE_OFFSET)
        MOV MEM_ADDR_LO, r0
        READ r13, 1
        ANDS r0, r1, 0xff
        MOVEQ r0, 1
        RSB r0, r0, 256
        ADD r0, r0, LO(MEMORY_BASE_ADDR + MEMORY_SIN_TABLE_OFFSET)
        MOV MEM_ADDR_LO, r0
        wait_mem
        TST r1, 0x100
        MOVEQ r8, [ZERO + tmp1] // sx
        MOVNE r9, [ZERO + tmp1] // cx
        READ r13, 1
        
        MOV r2, [ZERO + control_y]
        AND r0, r2, 0xff
        ADD r0, r0, LO(MEMORY_BASE_ADDR + MEMORY_SIN_TABLE_OFFSET)
        MOV MEM_ADDR_LO, r0
        wait_mem
        TST r1, 0x100
        MOVNE r8, [ZERO + tmp1] // sx
        MOVEQ r9, [ZERO + tmp1] // cx
        READ r13, 1
        SUBNE r9, ZERO, r9
        
        ANDS r0, r2, 0xff
        MOVEQ r0, 1
        RSB r0, r0, 256
        ADD r0, r0, LO(MEMORY_BASE_ADDR + MEMORY_SIN_TABLE_OFFSET)
        MOV MEM_ADDR_LO, r0
        wait_mem
        MOV r10, [ZERO + tmp1] // sy
        READ r13, 1
        TST r1, 0x200
        SUBNE r8, ZERO, r8
        SUBNE r9, ZERO, r9
        MOV r3, transform_matrix
        SUB r10, ZERO, r10
        wait_mem
        MOV r11, [ZERO + tmp1] // cy
        // r8 - sx
        // r9 - cx
        // r10 - sy
        // r11 - cy
        SMUL r9, 0x4000
        SMUL r8, 0x4000
        SMUL r8, r10
        MOV [r3], MUL_RESULT_HI
        MOV [r3+2], MUL_RESULT_HI
        SMUL r11, -0x4000
        SUB r0, ZERO, MUL_RESULT_HI
        SMUL r9, r10
        MOV [r3+5], MUL_RESULT_HI
        SMUL r8, r11
        MOV [r3+4], r0
        MOV [r3+6], MUL_RESULT_HI
        SUB r0, ZERO, MUL_RESULT_HI
        SMUL r10, 0x4000
        SMUL r9, r11
        MOV [r3+8], r0
        MOV [r3+9], MUL_RESULT_HI
        MOV [r3+10], MUL_RESULT_HI
        
        CMOV r13, VERTICES_BUF + vertices_list_end
        CMOV r12, VERTICES_BUF
_(loop):
        CMP r12, r13
        JEQ _(end)
            CALLNE transform_vector
            MOV r0, [r12]
            MOV r1, [r12+1]
            MOV r2, [r12+2]
            NOP
        
        SHR r8, 4
        CMP r8, 0
        ADD r8, SHIFT_RESULT, 320
        ADDMI r8, r8, 0xf000
        SHR r9, 4
        CMP r9, 0
        ADD r9, SHIFT_RESULT, 240
        ADDMI r9, r9, 0xf000
        J _(loop)
            MOV [r12], r8
            MOV [r12+1], r9
            MOV [r12+2], r10
            ADD r12, r12, 5

/* r0, r1, r2 - vector in
r3 - matrix

r8  = r0*[r3]   + r1*[r3+1] + r2*[r3+2]  + [r3+3]
r9  = r0*[r3+4] + r1*[r3+5] + r2*[r3+6]  + [r3+7]
r10 = r0*[r3+8] + r1*[r3+9] + r2*[r3+10] + [r3+11]
r11 - camera dist
*/

transform_vector:
        SMUL r0, [r3]
        MOV r8, [r3+3]
        SMUL r1, [r3+1]
        MOV r4, MUL_RESULT_LO
        MOV r5, MUL_RESULT_HI
        SMUL r2, [r3+2]
        ADD r4, r4, MUL_RESULT_LO
        ADC r5, r5, MUL_RESULT_HI
        ADD r4, r4, MUL_RESULT_LO
        ADC r5, r5, MUL_RESULT_HI
        MUL r4, 16
        MUL r5, 16
        SMUL r0, [r3+4]
        ADD r8, r8, MUL_RESULT_HI
        ADD r8, r8, MUL_RESULT_LO

        MOV r9, [r3+7]
        SMUL r1, [r3+5]
        MOV r4, MUL_RESULT_LO
        MOV r5, MUL_RESULT_HI
        SMUL r2, [r3+6]
        ADD r4, r4, MUL_RESULT_LO
        ADC r5, r5, MUL_RESULT_HI
        ADD r4, r4, MUL_RESULT_LO
        ADC r5, r5, MUL_RESULT_HI
        MUL r4, 16
        MUL r5, 16
        SMUL r0, [r3+8]
        ADD r9, r9, MUL_RESULT_HI
        ADD r9, r9, MUL_RESULT_LO

        SMUL r1, [r3+9]
        MOV r4, MUL_RESULT_LO
        MOV r5, MUL_RESULT_HI
        SMUL r2, [r3+10]
        ADD r4, r4, MUL_RESULT_LO
        ADC r5, r5, MUL_RESULT_HI
        ADD r4, r4, MUL_RESULT_LO
        ADC r5, r5, MUL_RESULT_HI
        MOVS r11, [ZERO + perspective]
        //ADDEQ r8, r8, 320
        //ADDEQ r9, r9, 240
        MUL r4, 16
        RETEQ
            MUL r5, 16
            MOV r10, [r3+11]
            ADD r10, r10, MUL_RESULT_HI
            ADD r10, r10, MUL_RESULT_LO

        SHR r11, 6
        ADD r4, r10, r11
        MOV r11, SHIFT_RESULT
        SHR r4, 6
        MOV r5, 0
        MOV r4, SHIFT_RESULT
_(div_loop):
        SHR r4, 1
        TST r4, 0xff00
        JNE _(div_loop)
            MOVNE r4, SHIFT_RESULT
            ADD r6, r4, DIV_TABLE
            ADDNE r5, r5, 1
            NOP
        MOV r4, [r6]
        SHR r4, r5
        SMUL r11, r8
        MOV r4, SHIFT_RESULT // 65536/(c+z)
        NOP //MOV r8, 320
        WMUL r4, MUL_RESULT_LO
        NOP
        SMUL r11, r9
        NOP //MOV r9, 240
        MOV r8, MUL_RESULT_LO //ADD r8, r8, MUL_RESULT_LO
        WMUL r4, MUL_RESULT_LO
        RET
            NOP
            NOP
            MOV r9, MUL_RESULT_LO //ADD r9, r9, MUL_RESULT_LO
            NOP

_(end):
#undef _

