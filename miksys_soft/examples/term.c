#include <miksys.h>
#include <ps2_keyboard.h>

char buf[128*40];
unsigned buf_offset = 0;

void update_display() {
    static int i = 0;
    if (sdram_busy()) return;
    if (i^=1)
        sdram(SDRAM_WRITE_ASYNC, buf+buf_offset, sizeof(buf)-buf_offset, 0);
    else
        sdram(SDRAM_WRITE_ASYNC, buf, buf_offset, sizeof(buf)-buf_offset);
}

void main() {
    unsigned i, pos = 0, char_color = 0xff00;
    for (i = 0; i < sizeof(buf); i++) buf[i] = 0;
    while (1) {
        int c = ps2k_readchar();
        if (c != -1) putc(SERIAL, c);
        update_display();
        if ((c=getc(SERIAL)) == -1) continue;
        if (c != '\n') buf[pos] = char_color | c;
        if ((++pos&127) == 106 || c == '\n')
            while (pos&127) buf[pos++] = 0;
        if (pos == sizeof(buf)) pos = 0;
        if (pos == buf_offset) {
            buf_offset = (buf_offset+128)%sizeof(buf);
            for (i = 0; i < 106; i++) buf[pos+i] = 0;
        }
    }
}
