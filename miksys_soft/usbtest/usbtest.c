#include <miksys.h>

void wait_enter();
void printf(char* fmt, ...);
void write_serial(void* b, void* e);

static unsigned buf[512];

int usb_get_descriptor(unsigned addr, unsigned d, unsigned size, unsigned *b) {
    static unsigned get_descriptor[] = {8, 0x0680, 0 /* d */, 0x0000, 0 /* size */};
    get_descriptor[2] = d;
    get_descriptor[4] = size;
    return usb_request(addr, get_descriptor, b, size);
}

void usb_show_string(unsigned addr, unsigned str_id) {
    unsigned size;
    static unsigned get_str[] = {8, 0x0680, 0x0300, 0x0000, 0x0000};
    unsigned* b = buf+18;
    if (!usb_get_descriptor(addr, 0x0300|str_id, 2, b)) goto err;
    size = (*b) & 0xff;
    if (!usb_get_descriptor(addr, 0x0300|str_id, size, b)) goto err;
    write_serial(b+1, b+size/2);
    return;
    err:
    printf("*");
}

unsigned buf_byte(unsigned b) {
    unsigned v = buf[b/2];
    if (b&1)
        return v >> 8;
    else
        return v & 0xff;
}

void main() {
    unsigned i, inum, ipos, epos;
    unsigned long li;
    while (1) {
        printf("\r\n\n[USB test] Press enter to continue\r\n");
        wait_enter();
        printf("Waiting for device...  ");
        while (!usb_reset());
        printf("[OK]\r\n");
        for (li = 0; li < 10000000; li++);
        printf("Get device descriptor  ");
        if (!usb_get_descriptor(0, 0x0100, 18, buf)) goto err;
        printf("[OK]   ");
        for (i = 0; i < 18; i++) printf(" 0%X", buf_byte(i));
        printf("\r\n   Vendor:  0x000%X  ", buf[4]);
        usb_show_string(0, buf[7]&0xff);
        printf("\r\n   Product: 0x000%X  ", buf[5]);
        usb_show_string(0, buf[7]>>8);
        printf("\r\n   Device:  0x000%X  ", buf[6]);
        usb_show_string(0, buf[8]&0xff);
        printf("\r\nGet configuration descriptor  ");
        if (!usb_get_descriptor(0, 0x0200, 9, buf)) goto err;
        if (!usb_get_descriptor(0, 0x0200, buf[1], buf)) goto err;
        printf("[OK]   ");
        for (i = 0; i < 9; i++) printf(" 0%X", buf_byte(i));
        inum = buf_byte(4);
        ipos = 9;
        epos = inum*9 + 9;
        for (i = 1; i <= inum; i++) {
            unsigned endpoints = buf_byte(ipos + 4);
            unsigned e, j;
            printf("\r\n   Interface %d:", i);
            for (j = 0; j < 9; j++) printf(" 0%X", buf_byte(ipos++));
            for (e = 1; e <= endpoints; e++) {
                printf("\r\n      Endpoint %d:", e);
                for (j = 0; j < 7; j++) printf(" 0%X", buf_byte(epos++));
            }
        }
        continue;
        err: printf("[FAILED]\r\n");
    }
}

