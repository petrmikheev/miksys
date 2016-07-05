#include "miksys.h"
#include <QDebug>

MIKSYS::MIKSYS(QObject* parent) : QObject(parent)
{
    buttonState = false;
    LEDstate = 0;
    frame = 0;
    vga_control_index = 0;
    serial_in = NULL;
    serial_out = NULL;
    keyboard_queue_begin = keyboard_queue_end = 0;
}

MIKSYS::~MIKSYS() {}

bool MIKSYS::peripheral_read(unsigned char& v) {
    v = 0;
    switch (peripheralAddr) {
        case 0: {
            if (!serial_in) return false;
            return fread(&v, 1, 1, serial_in);
        } break;
        case 1: { // sdram stats
            v = 0;
        } return true;
        case 2: { // vga_frame
            v = frame % 256;
        } return true;
        case 4: { // keyboard
            bool ok = keyboard_queue_begin != keyboard_queue_end;
            v = keyboard_buf[keyboard_queue_end];
            if (ok)
                keyboard_queue_end = (keyboard_queue_end+1)&3;
            return ok;
        }
        default: return false;
    }
}

bool MIKSYS::peripheral_write(unsigned char v) {
    switch (peripheralAddr) {
        case 0: {
            if (!serial_out) return false;
            bool r = fwrite(&v, 1, 1, serial_out);
            fflush(serial_out);
            return r;
        } break;
        case 2: { // vga_control
            vga_control[vga_control_index] = v;
            vga_control_index = (vga_control_index+1) % 6;
        } return true;
        default: return false;
    }
}

void MIKSYS::addByteToKeyboardQueue(unsigned char c) {
    keyboard_buf[keyboard_queue_begin] = c;
    keyboard_queue_begin = (keyboard_queue_begin+1)&3;
    //qDebug() << QString("k 0x%1").arg(c, 2, 16, QChar('0'));
}
