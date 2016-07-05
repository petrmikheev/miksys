// Меняет состояние светодиодов два раза в секунду
.code 0x0
l:          J l
            SHR IN_TIME_MS4, 11
            NOP
            MOV OUT_LEDS, SHIFT_RESULT
            NOP
