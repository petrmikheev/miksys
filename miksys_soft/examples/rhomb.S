// Заполняет экран цветными ромбиками
#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480
#define X r0
#define Y r14
#define tmp r1
#define mem_lo r12
#define mem_hi r13
#define COLOR r2
#define SCREEN_WIDTH_S4 r11
.code 0 0
            OUT DEV_VGA, 0
            OUT DEV_VGA, 0
            OUT DEV_VGA, 128
            OUT DEV_VGA, 0
            OUT DEV_VGA, 0
            OUT DEV_VGA, 0
            CMOV mem_lo, 0
            CMOV mem_hi, 0
            CMOV SCREEN_WIDTH_S4, SCREEN_WIDTH-4
            CMOV Y, 0
loop_y:     AND X, IN_FLAGS, 3
loop_x:     ADD tmp, X, Y
            TST tmp, 16
            CMOVEQ COLOR, 0
            CMOVNE COLOR, 0xf800
            SUB tmp, X, Y
            CMP X, SCREEN_WIDTH_S4
            JNE loop_x
                TST tmp, 16
                ORNE COLOR, COLOR, 0x1f
                MOV [ALL X], COLOR
                ADD X, X, 4
            ADD mem_lo, mem_lo, SCREEN_WIDTH
            ADC mem_hi, mem_hi, 0
            MOV MEM_ADDR_LO, mem_lo
            MOV MEM_ADDR_HI, mem_hi
            CMOV tmp, 0
            TST IN_FLAGS, MEM_FLAG
wait_ram:   JNE wait_ram
                WRITEEQ tmp, SCREEN_WIDTH
                CMPEQ Y, SCREEN_HEIGHT-1
                JMI loop_y
                TST IN_FLAGS, MEM_FLAG
                ADD Y, Y, 1
                NOP
                NOP
end:        J end
                NOP
                NOP
                NOP
                NOP

