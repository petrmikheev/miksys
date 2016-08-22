#ifndef PS2_KEYBOARD_H
#define PS2_KEYBOARD_H

#pragma link ps2_keyboard.S

char ps2k_readcode();
char ps2k_readchar();
#define ps2k_handle() while(ps2k_readcode())

#define PS2_KEY_SHIFT 0x12
#define PS2_KEY_W 0x1d
#define PS2_KEY_A 0x1c
#define PS2_KEY_S 0x1b
#define PS2_KEY_D 0x23
int* ps2k_watch(unsigned code);
void ps2k_unwatch_all();
#define ps2k_ispressed(x) (*(int*)(x) < 0)

#endif
