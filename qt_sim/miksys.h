#ifndef MIKSYS_H
#define MIKSYS_H

#include <cstdio>
#include <QObject>

class MIKSYS : public QObject
{
    Q_OBJECT
public:
    MIKSYS(QObject* parent = 0);
    virtual ~MIKSYS();
    const static int MEM_SIZE = 4 * 1024 * 1024;
    unsigned short memory[MEM_SIZE];
    unsigned char vga_control[6];
    int vga_control_index;
    unsigned char frame;
    int peripheralAddr;
    bool peripheral_read(unsigned char& v);
    bool peripheral_write(unsigned char v);
    bool buttonState;
    int LEDstate;
    FILE* serial_in;
    FILE* serial_out;
    unsigned char keyboard_buf[4];
    int keyboard_queue_begin, keyboard_queue_end;
public slots:
    void addByteToKeyboardQueue(unsigned char c);
};

#endif // MIKSYS_H
