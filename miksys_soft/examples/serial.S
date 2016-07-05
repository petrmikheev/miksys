// Возвращает полученные через последовательный порт байты
// Меняет состояние светодиодов при удержании кнопки на плате
.code 0x0
l:          INS DEV_SERIAL, r1
            JMI l
                TST IN_FLAGS, SOFTKEY_FLAG
                CMOVEQ OUT_LEDS, 10
                CMOVNE OUT_LEDS, 5
                NOP
w:          OUTS DEV_SERIAL, r1
            JMI w
            JPL l
                NOP
                NOP
                NOP
                NOP

