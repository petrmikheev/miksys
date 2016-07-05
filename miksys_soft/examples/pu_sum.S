// Считает сумму номеров всех PU и выводит на светодиоды
.code 0x0
            MOV r15, 0
            NOP
            AND r0, IN_FLAGS, 3
            MOV [ALL r15], r0
            NOP
            NOP
            NOP
            ADD r1, r15, [r15]
            ADD r1, r1, [r15+1]
            ADD r1, r1, [r15+2]
            ADD r1, r1, [r15+3]
            MOV OUT_LEDS, r1
end:        J end
                NOP
                NOP
                NOP
                NOP
