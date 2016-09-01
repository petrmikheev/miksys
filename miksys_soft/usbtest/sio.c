#include <miksys.h>

void wait_enter() {
    unsigned bcounter = 0;
    while (1) {
        if (is_button_pressed())
            bcounter++;
        else if (bcounter > 500) return;
        if (getc(SERIAL) == '\r') return;
    }
}

void write_serial(char* b, char* e) {
    while (b != e) {
        if (putc(SERIAL, *b)) b++;
    }
}

static char buf[128];
void printf(char* fmt, int v1, int v2, int v3, int v4, int v5, int v6, int v7, int v8, int v9) {
    char* e = print(buf, fmt, NUM_FORMATTING, v1, v2, v3, v4, v5, v6, v7, v8, v9);
    write_serial(buf, e);
}
