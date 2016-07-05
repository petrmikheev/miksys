
#define _(x) display_##x
        /*** Sort vertices ***/
        CMOV r11, FACES_COUNT*4+FACES_BUF // end
        CMOV r12, FACES_BUF // from
        CMOV r13, FACES_BUF-4 // to
_(sort_loop):
        CMP r12, r11
        JEQ _(sort_loop_end)
            MOV r0, [r12]
            MOV r1, [r12+1]
            MOV r2, [r12+2]
            MOV r3, [r12+3]
        
        CMP ZERO, [r0]
        CMPGT ZERO, [r1]
        CMPGT ZERO, [r2]
        JGT _(sort_loop) // p1.x < 0 && p2.x < 0 && p3.x < 0
            ADD r12, r12, 4
            CMP ZERO, [r0+1]
            CMPGT ZERO, [r1+1]
            CMPGT ZERO, [r2+1]
        JGT _(sort_loop) // p1.y < 0 && p2.y < 0 && p3.y < 0
            CMOV r10, SCREEN_WIDTH
            CMP r10, [r0]
            CMPLE r10, [r1]
            CMPLE r10, [r2]
        JLE _(sort_loop) // p1.x >= 640 && p2.x >= 640 && p3.x >= 640
            CMOV r10, SCREEN_HEIGHT
            CMP r10, [r0+1]
            CMPLE r10, [r1+1]
            CMPLE r10, [r2+1]
        JLE _(sort_loop) // p1.y >= 480 && p2.y >= 480 && p3.y >= 480
            MOV r4, [r1]
            SUB r4, r4, [r0]
            MOV r5, [r2+1]
            SUB r5, r5, [r0+1]
        SMUL r5, r4
        MOV r4, [r2]
        SUB r4, r4, [r0]
        MOV r5, [r1+1]
        SUB r5, r5, [r0+1]
        SMUL r5, r4
        MOV r4, MUL_RESULT_LO
        MOV r5, MUL_RESULT_HI
        SUB r4, r4, MUL_RESULT_LO
        SBCS r5, r5, MUL_RESULT_HI
        JPL _(sort_loop) // back side
            ADDMI r13, r13, 4
            MOV r4, [r1+1]
            MOV r5, [r2+1]
            CMP r5, [r0+1]
        MOV [r13], r0
        MOV [r13+1], r1
        MOV [r13+2], r2
        MOVLT [r13], r2
        MOVLT [r13+1], r0
        MOVLT [r13+2], r1
        CMP r4, [r0+1]
        CMPLT r4, r5
        J _(sort_loop)
            MOVLT [r13], r1
            MOVLT [r13+1], r2
            MOVLT [r13+2], r0
            MOV [r13+3], r3
_(sort_loop_end):
        MOV [ZERO + last_face_pointer], r13 //FACES_COUNT*4+FACES_BUF-4

        /*** View loop ***/
        CMOV r13, SCREEN_HEIGHT-1 // counter y
_(row):
        MOV [ZERO + counter_y], r13
        CMOV r12, SCREEN_WIDTH // counter x
        MOV r11, [ZERO + last_face_pointer]
        MOV [ZERO + face_pointer], r11
        TST r13, 1
        CMOVEQ r8, COLOR1_ROW_BUF
        CMOVNE r8, COLOR2_ROW_BUF
        MOV r10, [ZERO + control_y]
        MOV [ZERO + row_color_buf], r8
        ADD r10, r10, r10
        RSB r10, r10, 240
        CMOV r9, 0x7fff
        CMP r13, r10
        CMOVLE r10, RGB("15 15 25")
        CMOVGT r10, RGB("8 10 8")
_(clear_loop):
        SUBS r12, r12, 4
        JNE _(clear_loop)
            ADD r7, r12, DEPTH_ROW_BUF
            ADD r8, r8, 4
            MOV [ALL r8], r10
            MOV [ALL r7], r9
        
_(faces_loop):
        MOV r11, [ZERO + face_pointer]
        CMP r11, FACES_BUF
        JCC _(wrbuf)
            MOV r8, [r11]
            MOV r9, [r11+1]
            MOV r10, [r11+2]
            MOV r12, [r11+3]
        SUB r11, r11, 4
        MOV r13, [ZERO + counter_y]
        CMP r13, [r8 + 1] // if y < v1.y
        JLT _(faces_loop)
            MOV [ZERO + face_pointer], r11
            MOV [ZERO + current_material], r12
            CMP r13, [r9 + 1]
            CMPGT r13, [r10 + 1] // if y > v2.y && y > v3.y
        JGT _(faces_loop)
            MOV r7, r10
            CALLLE _(func_avg)
            MOV r6, r8
            CMP r13, [r10+1]
            MOVGT r7, r9
            MOVGT r6, r10
        MOV [ZERO + row_lx], r0
        MOV [ZERO + row_dz], r2
        MOV [ZERO + row_dtx], r3
        MOV [ZERO + row_dty], r4
        
        CMP r13, [r9+1]
        CALL _(func_avg)
            MOV r6, r8
            MOV r7, r9
            MOVGT r7, r10
            MOVGT r6, r9
        MOV [ZERO + row_fz], r2
        MOV [ZERO + row_ftx], r3
        MOV [ZERO + row_fty], r4
        MOV r5, 0
        RSB r1, r0, [ZERO + row_lx]
_(div_loop2):
        SHR r1, 1
        TST r1, 0xff00
        JNE _(div_loop2)
            MOVNE r1, SHIFT_RESULT
            ADD r6, r1, DIV_TABLE
            ADDNE r5, r5, 1
            MOV r8, 0
        MOV r1, [r6]
        SHR r1, r5
        RSBS r7, r2, [ZERO + row_dz]
        MOV r11, SHIFT_RESULT // 65536/(vb.x-va.x)
        RSBMI r7, r7, 0
        ORMI r8, r8, 1
        MOV [ZERO + row_dz], r7
        RSBS r7, r3, [ZERO + row_dtx]
        RSBMI r7, r7, 0
        ORMI r8, r8, 2
        MOV [ZERO + row_dtx], r7
        RSBS r7, r4, [ZERO + row_dty]
        RSBMI r7, r7, 0
        ORMI r8, r8, 4
        MOV [ZERO + row_dty], r7
        
        MOVS [ZERO + row_fx], r0
        CMOVMI r0, 0
        AND r10, r0, 0xfffc
        
        CMOV r1, SCREEN_WIDTH-1
        CMP r1, [ZERO + row_lx]
        MOVLT [ZERO + row_lx], r1
        
        AND r0, IN_FLAGS, 3
        ADD r1, r0, r10
        MOV r13, [ZERO + current_material]
        AND r12, r13, 7
        SHL r12, 10
        SUB r7, r1, [ZERO + row_fx]
        ADD r12, SHIFT_RESULT, 0x2000
        MOV r5, r13
        MOV r4, [ZERO + row_fz]
        
        // r0 - PU
        // r1 - counter
        // r2 - avg_z
        // r3 - tmp
        // r4 - row_fz
        // r5 - pixel_addr+color
        // r6 - tmp
        // r7 - steps
        // r8 - flags
        // r9 - depth_addr
        // r10 - color_addr
        // r11 - denom
        // r12 - texture_offset
        // r13 - material
        
_(x_loop):
        CMP r1, [ZERO + row_lx]
        JGT _(faces_loop)
            MUL r11, [ZERO + row_dz]
            ADD r9, r1, DEPTH_ROW_BUF
            ADD r10, r1, [ZERO + row_color_buf]
            WMUL r7, MUL_RESULT_LO
        TST r13, 0x0020
        JEQ _(row_skip_texture)
            TST r8, 1
            MUL r11, [ZERO + row_dtx]
            ADDEQ r2, r4, MUL_RESULT_LO
            SUBNE r2, r4, MUL_RESULT_LO
        WMUL r7, MUL_RESULT_LO
        TST r8, 2
        MUL r11, [ZERO + row_dty]
        MOV r3, [ZERO + row_fty]
        MOV r6, MUL_RESULT_LO
        WMUL r7, MUL_RESULT_LO
        ADDEQ r5, r6, [ZERO + row_ftx]
        RSBNE r5, r6, [ZERO + row_ftx]
        TST r8, 4
        ADDEQ r6, r3, MUL_RESULT_LO
        SUBNE r6, r3, MUL_RESULT_LO
        TST r13, 0x8
        ANDEQ r6, r6, 0x1f
        ANDNE r6, r6, 0x3f
        TST r13, 0x10
        SHLEQ r6, 5
        SHLNE r6, 6
        ANDEQ r5, r5, 0x1f
        ANDNE r5, r5, 0x3f
        ADD r5, r5, SHIFT_RESULT
        ADD [ALL ZERO + pu_addr_group], r5, r12

        ADD r6, r5, r12
        MOV r5, 0
        CMP r0, 1
        MOV r3, [r6]
        
        MOV r6, [ALL ZERO + pu_addr_group + 1]
        MOV r6, [ALL ZERO + pu_addr_group + 2]
        MOV r6, [ALL ZERO + pu_addr_group + 3]
        MOVEQ r3, [r6]
        MOVHI r3, [r6]
        CMP r0, 3
        MOVEQ r3, [r6]
        TST r13, 0x200
        MOVNE r5, r3
        RGBSHR r3, r3
        TST r13, 0x100
        RGBADDNE r5, r5, r3
        RGBSHR r3, r3
        TST r13, 0x80
        RGBADDNE r5, r5, r3
        RGBSHR r3, r3
        TST r13, 0x40
        RGBADDNE r5, r5, r3

_(row_skip_texture):
        ADD r7, r7, 4
        CMP r2, [ALL r9]
        RSBLES r6, r1, [ZERO + row_fx]
        J _(x_loop)
            CMPLE r1, [ZERO + row_lx]
            MOVLE [ALL r10], r5
            MOVLE [ALL r9], r2
            ADD r1, r1, 4

_(wrbuf):
        /* Write row to color buffer */
        MOV r13, [ZERO + counter_y]
        #ifdef FPS30
        CMOV r0, 2
        #else
        CMOV r0, 1
        #endif
_(wait_mem):
        TST IN_FLAGS, MEM_FLAG
        JNE _(wait_mem)
            MUL r13, SCREEN_WIDTH
            TST r0, [ZERO + frame]
            CMOVNE r0, LO(MEMORY_COLOR_BUF1)
            CMOVNE r1, HI(MEMORY_COLOR_BUF1)
        CMOVEQ r0, LO(MEMORY_COLOR_BUF2)
        CMOVEQ r1, HI(MEMORY_COLOR_BUF2)
        ADD r0, r0, MUL_RESULT_LO
        ADC r1, r1, MUL_RESULT_HI
        SUBS r13, r13, 1
        JPL _(row)
            MOV MEM_ADDR_LO, r0
            MOV MEM_ADDR_HI, r1
            MOV r6, [ZERO + row_color_buf]
            WRITE r6, SCREEN_WIDTH
        DJ _(end)

/* r6, r7 - pointers
   r13 - y
   r0, r2, r3, r4 - results
   r1, r5 - tmp
*/
_(func_avg):
        MOV r3, 0
        MOV r1, [r7+1]
        SUBS r1, r1, [r6+1] // frac2
_(div_loop):
        SHR r1, 1
        TST r1, 0xff00
        JNE _(div_loop)
            MOVNE r1, SHIFT_RESULT
            ADD r2, r1, DIV_TABLE
            ADDNE r3, r3, 1
            MOV r0, [r7]
        MOV r1, [r2]
        SHR r1, r3
        SUB r5, r13, [r6+1] // frac1
        
        SUBS r0, r0, [r6]
        RSBMI r0, r0, 0
        MUL r0, r5
        MOV r1, SHIFT_RESULT // 65536/frac2
        MOV r2, [r7+2]
        WMUL r1, MUL_RESULT_LO
        MOV r4, [r7+4]
        MOV r0, [r6]
        MOV r3, [r7+3]
        ADDPL r0, r0, MUL_RESULT_LO
        SUBMI r0, r0, MUL_RESULT_LO

        SUBS r2, r2, [r6+2]
        MOV [ZERO + tmp1], r2
        RSBMI r2, r2, 0
        MUL r2, r5
        SUBS r3, r3, [r6+3]
        MOV [ZERO + tmp2], r3
        RSBMI r3, r3, 0

        WMUL r1, MUL_RESULT_LO
        MOV r2, [r6+2]
        CMP ZERO, [ZERO + tmp1]
        MUL r3, r5
        ADDLE r2, r2, MUL_RESULT_LO
        SUBGT r2, r2, MUL_RESULT_LO

        SUBS r4, r4, [r6+4]
        MOV [ZERO + tmp1], r4
        RSBMI r4, r4, 0
        WMUL r1, MUL_RESULT_LO
        MOV r3, [r6+3]
        CMP ZERO, [ZERO + tmp2]
        MUL r4, r5
        ADDLE r3, r3, MUL_RESULT_LO
        SUBGT r3, r3, MUL_RESULT_LO

        WMUL r1, MUL_RESULT_LO
        RET
            MOV r4, [r6 + 4]
            CMP ZERO, [ZERO + tmp1]
            ADDLE r4, r4, MUL_RESULT_LO
            SUBGT r4, r4, MUL_RESULT_LO
_(end):
#undef _

