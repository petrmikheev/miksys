// r0 - byte
// r1 - tmp
mouse_send:
        OUT DEV_PS2_1, r0
        MOV r0, 0xffff
mouse_wait_loop:
        INS DEV_PS2_1, r1
        DRETPL
        SUBS r0, r0, 1
        DRETEQ
        DJ mouse_wait_loop

