#include <miksys.h>

#if 0
#define usb_request usb_request2
unsigned usb_send_package(int count, void* data);
unsigned usb_read_package(void* buf);
int usb_request2(unsigned addr, void* data_out, void* data_in, unsigned size_in) {
    static unsigned buf[70];
    unsigned flags = addr & 0xe000;
    if (flags == USB_SENDRECV || (flags&USB_SEND)) { // USB_SEND_EMPTY
        int c = 0;
        buf[0] = flags == USB_SENDRECV ? 0x2d : 0xe1;
        buf[1] = addr;
        buf[2] = addr>>8;
        usb_send_package(3, buf);
        if (flags != USB_SEND_EMPTY) {
            int i;
            c = data_out[0];
            buf[0] = 0xc3;
            for (i = 1; i <= c; ++i) {
                buf[i+1] = data_out[i/2];
            }
        }
        // SEND
        // wait ACK
    }
    if (flags == USB_SENDRECV || flags == USB_RECV) {
        // RECV
    }
}
#endif

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

unsigned set_addr[] = {8, 0x0500, 0x0001, 0x0000, 0x0000};
unsigned set_conf[] = {8, 0x0900, 0x0001, 0x0000, 0x0000};
unsigned usbms_reset[] = {8, 0xff21, 0x0000, 0x0000, 0x0000};
unsigned clear_halt[] = {8, 0x0102, 0x0000, 0x0, 0x0000};

unsigned buf_byte(unsigned b) {
    unsigned v = buf[b/2];
    if (b&1)
        return v >> 8;
    else
        return v & 0xff;
}

unsigned USBMS_CBW_Read512[] = {
    31 /* size */,
    0x5355, 0x4342 /* signature */,
    0, 0 /* tag */,
    512, 0 /* dcBWDataTransferLength */,
    0x80 /* flags and wlun -- work with endpoint_in  */,
    0x280a /* USBMS_Read */, 0x0000, 
    0x0000 /* addr/512 */,
    0x0000,
    0x0100 /* size/512 <<< 8 */,
    0x0000, 0x0000, 0x0000, 0x00
}; /* Read first 512 bytes */

unsigned usb_mass_storage = 0, endpoint_in, endpoint_out;
int test_usb_mass_storage() {
    int i;
    printf("\r\nUsb mass storage detected\r\n");
    printf("Set address  ");
    if (!usb_request(0, set_addr, 0, 0)) return 0;
    printf("[OK]\r\nSet configuration  ");
    if (!usb_request(1, set_conf, 0, 0)) return 0;
    printf("[OK]\r\nUSBMS Reset  ");
    if (!usb_request(1, usbms_reset, 0, 0)) return 0;
    printf("[OK]\r\nClear feature HALT to the Bulk-In endpoint  ");
    clear_halt[3] = 0x80 | endpoint_in;
    if (!usb_request(1, clear_halt, 0, 0)) return 0;
    printf("[OK]\r\nClear feature HALT to the Bulk-Out endpoint  ");
    clear_halt[3] = endpoint_out;
    if (!usb_request(1, clear_halt, 0, 0)) return 0;
    printf("[OK]\r\nSend CBW (read first 512 bytes)  ");
    if (!usb_request(USB_SEND | (endpoint_out<<7) | 1, &USBMS_CBW_Read512, 0, 0)) return 0;
    printf("[OK]\r\nReceiving data  ");
    if (!usb_request(USB_RECV | (endpoint_in<<7) | 1, 0, buf, 512)) return 0;
    printf("[OK]   ");
    for (i = 0; i < 16; i++) printf(" 0%X", buf_byte(i));
    printf(" ...\r\nReceiving CSW  ");
    if (!usb_request(USB_RECV | (endpoint_in<<7) | 1, 0, buf, 13)) return 0;
    printf("[OK]   ");
    for (i = 0; i < 13; i++) printf(" 0%X", buf_byte(i));
    return 1;
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
            if (buf_byte(ipos+5)==0x08 && buf_byte(ipos+7)==0x50) usb_mass_storage = 1;
            printf("\r\n   Interface %d:", i);
            for (j = 0; j < 9; j++) printf(" 0%X", buf_byte(ipos++));
            for (e = 1; e <= endpoints; e++) {
                if (buf_byte(epos+2)&0x80) endpoint_in = e;
                else endpoint_out = e;
                printf("\r\n      Endpoint %d:", e);
                for (j = 0; j < 7; j++) printf(" 0%X", buf_byte(epos++));
            }
        }
        if (!usb_mass_storage || test_usb_mass_storage()) continue;
        err: printf("[FAILED]");
    }
}

