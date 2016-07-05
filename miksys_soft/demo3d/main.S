#include "../include/std.H"
#include "consts.H"

.macro wait_mem
$(m):   TST IN_FLAGS, MEM_FLAG
        DJNE $(m)
.endmacro

/* Форматирование текста для вывода на экран
* (буфер, строка, цвет|флаги, [число1], ..., [число9]) -> (смещенный буфер) 
* флаг 0x0001 = 0 -> Форматирование включено
* флаг 0x0001 = 1 -> Форматирование выключено
*/
.macro show_state t_disp, t_cpu
        MOV r10, [ZERO + time_transform]
        CCMOV [SP+3], FPS
        MOV [SP+4], r10
        MOV [SP+6], t_cpu
        IN DEV_SDRAM, [SP+7]
        IN DEV_SDRAM, [SP+8]
        CALL printf_func
            CCMOV [SP], STR_BUF + 0x100  // buf
            CCMOV [SP+1], str_state  // str
            CCMOV [SP+2], 0xff00 // color|flags
            MOV [SP+5], t_disp
        CMOV r8, STR_BUF + 0x100
        RSB r9, r8, [SP]
        MOV MEM_ADDR_LO, r4
        MOV MEM_ADDR_HI, r5
        WRITE r8, r9
        NOP
        wait_mem
.endmacro

.macro read_faces_and_vertecies
        CMOV r0, FACES_BUF
        CMOV MEM_ADDR_LO, LO(MEMORY_BASE_ADDR + MEMORY_FACES_OFFSET)
        CMOV MEM_ADDR_HI, HI(MEMORY_BASE_ADDR + MEMORY_FACES_OFFSET)
        READ r0, 0x2000 - FACES_BUF
.endmacro

.code MEMORY_BASE_ADDR 0x0

/* init */
        CMOV ZERO, 0
        CMOV SP, STACK_BUF
        
m0:     INS DEV_PS2_1, r0
        DJPL m0
        CMOV r0, 0xF3
        DCALL mouse_send
        CMOV r0, 0x20
        DCALL mouse_send
        CMOV r0, 0xE8
        DCALL mouse_send
        CMOV r0, 0x0
        DCALL mouse_send
        CMOV r0, 0xF4
        DCALL mouse_send
        
        MOVS r0, 0xffff
clear_cache_loop:
        JNE clear_cache_loop
            CMOV MEM_ADDR_LO, LO(MEMORY_BASE_ADDR + MEMORY_VARIABLES_OFFSET)
            CMOV MEM_ADDR_HI, HI(MEMORY_BASE_ADDR + MEMORY_VARIABLES_OFFSET)
            CCMOV [r0], 0
            SUBS r0, r0, 1
        READ ZERO, 0x180 // read global variables and div_table
        CMOV MEM_ADDR_LO, LO(MEMORY_TEXT_BUF1)
        wait_mem
        CMOV MEM_ADDR_HI, HI(MEMORY_TEXT_BUF1)
        WRITE SP, 10240 // clear text buffers
        IN DEV_VGA, r0 // get current frame number
        #ifdef FPS30
        AND r0, r0, 0xfffe
        #endif
        MOV [ZERO + frame], r0
        wait_mem
        CMOV r0, 0x2000
        CMOV MEM_ADDR_LO, LO(MEMORY_BASE_ADDR + MEMORY_TEXTURES_OFFSET)
        CMOV MEM_ADDR_HI, HI(MEMORY_BASE_ADDR + MEMORY_TEXTURES_OFFSET)
        READ r0, 0x2000 // read textures
        NOP //IN DEV_PS2_1, r0 // mouse get answer
        wait_mem

main_loop:
        
        /*** Read faces and vertices ***/
        CMOV r0, FACES_BUF
        CMOV MEM_ADDR_LO, LO(MEMORY_BASE_ADDR + MEMORY_FACES_OFFSET)
        CMOV MEM_ADDR_HI, HI(MEMORY_BASE_ADDR + MEMORY_FACES_OFFSET)
        READ r0, 0x2000 - FACES_BUF
        
        /*** Controls ***/
        CALL read_key_func
            CCMOV [SP], keyboard_settings
            CCMOV [SP+1], 0
            MOV r1, [ZERO + control_x]
            MOV r2, [ZERO + control_y]
        CMOV r0, 0x8000
        TST r0, [ZERO + go_forward_key]
        ADDNE r2, r2, 3
        TST r0, [ZERO + go_backward_key]
        SUBNE r2, r2, 3
        TST r0, [ZERO + go_right_key]
        ADDNE r1, r1, 3
        MOV r3, [ZERO + mouse_pointer]
        TST r0, [ZERO + go_left_key]
        SUBNE r1, r1, 3
mouse_loop:
        INS DEV_PS2_1, [r3]
        JMI mouse_end
            ADDPL r3, r3, 1
            CMP r3, mouse_data + 3
            MOVEQ r3, mouse_data
            MOV [ZERO + mouse_pointer], r3
        JNE mouse_loop
            MOV r4, [ZERO + mouse_data]
            MOV r5, [ZERO + mouse_data+1]
            MOV r6, [ZERO + mouse_data+2]
            TST r4, 16
        ORNE r5, r5, 0xff00
        J mouse_loop
            TST r4, 32
            ORNE r6, r6, 0xff00
            ADD r1, r1, r5
            ADD r2, r2, r6
mouse_end:
        
        CMP ZERO, [ZERO+rotate_mode]
        ADDNE r1, r1, 1
        CMP r2, 0
        MOVLT r2, 0
        CMP r2, 256
        MOVGE r2, 255
        MOV [ZERO + control_x], r1
        MOV [ZERO + control_y], r2
        
        /*** Control perspective mode ***/
        TST IN_FLAGS, SOFTKEY_FLAG
        CCMOVNE [ZERO + persp_timer], FPS/2
        MOV r2, [ZERO + rotate_mode]
        XOR r2, r2, 1
        MOVS r0, [ZERO + perspective]
        CMOVEQ r0, 800*16
        CMOVNE r0, 0
        MOV r1, [ZERO + persp_timer]
        CMPEQ r1, 1
        MOVEQ [ZERO + rotate_mode], r2
        CMP r1, 1
        MOVEQ [ZERO + perspective], r0
        SUB r1, r1, 1
        MOVPL [ZERO + persp_timer], r1

        /*** Transform ***/
        MOV r8, IN_TIME_MS4
        MOV [ZERO + time_transform], r8
        wait_mem
        #include "transform.S"
        MOV r9, [ZERO + time_transform]
        MOV r8, IN_TIME_MS4
        SUB [ZERO + time_transform], r8, r9

        /*** Display ***/
        MOV [ZERO + time_display], r8
        #include "display.S"
        wait_mem
        MOV r9, IN_TIME_MS4 // display time
        
        /*** Load string data ***/
        CMOV r0, STR_BUF
        CMOV MEM_ADDR_LO, LO(MEMORY_BASE_ADDR + MEMORY_STR_DATA_OFFSET)
        CMOV MEM_ADDR_HI, HI(MEMORY_BASE_ADDR + MEMORY_STR_DATA_OFFSET)
        READ r0, STR_BUF_END - STR_BUF
        SUB r9, r9, [ZERO + time_display]
        wait_mem
        
        /*** Rate control ***/
        IN DEV_VGA, r0
        #ifdef FPS30
        TST r0, 2
        #else
        TST r0, 1
        #endif
        CMOVEQ r0, (MEMORY_TEXT_BUF2 / 256) % 256
        CMOVEQ r1, MEMORY_TEXT_BUF2 / 65536
        CMOVNE r0, (MEMORY_TEXT_BUF1 / 256) % 256
        CMOVNE r1, MEMORY_TEXT_BUF1 / 65536
        CMOVEQ r2, (MEMORY_COLOR_BUF2 / 256) % 256
        CMOVEQ r3, MEMORY_COLOR_BUF2 / 65536
        CMOVNE r2, (MEMORY_COLOR_BUF1 / 256) % 256
        CMOVNE r3, MEMORY_COLOR_BUF1 / 65536
        MOV r8, [ZERO + time_idle]
        CMOVEQ r4, LO(MEMORY_TEXT_BUF2 + 128 * 33)
        CMOVNE r4, LO(MEMORY_TEXT_BUF1 + 128 * 33)
        CMOVEQ r5, HI(MEMORY_TEXT_BUF2 + 128 * 33)
        CMOVNE r5, HI(MEMORY_TEXT_BUF1 + 128 * 33)
        show_state r9, r8
        OUT DEV_VGA, r0
        OUT DEV_VGA, r1
        OUT DEV_VGA, 0
        OUT DEV_VGA, r2
        OUT DEV_VGA, r3
        OUT DEV_VGA, 0
        
        MOV r8, IN_TIME_MS4 // cpu idle
wait_frame_loop:
        IN DEV_VGA, r0
        #ifdef FPS30
        AND r0, r0, 0xfffe
        #endif
        CMP r0, [ZERO + frame]
        JEQ wait_frame_loop
            JNE main_loop
            RSBNE r8, r8, IN_TIME_MS4
            MOVNE [ZERO + time_idle], r8
            MOVNE [ZERO + frame], r0
            NOP

#include "../include/keyboard.H"
//#include "../include/math.H"
//#include "../include/string.H"
#include "mouse.H"

#include "global_variables.H"
#include "object_data.H"

