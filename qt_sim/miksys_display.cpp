#include "miksys_display.h"
#include <QPainter>
#include <QPaintEvent>

MIKSYS_display::MIKSYS_display(QWidget* parent) : QWidget(parent)
{
    this->system = NULL;
}

QColor getColor(unsigned c) {
    int r = ((c>>11)&0x1f) << 3;
    int g = ((c>>5)&0x3f) << 2;
    int b = (c&0x1f) << 3;
    return QColor(r, g, b);
}

void MIKSYS_display::keyPressEvent(QKeyEvent *e) {
    //int v1 = e->key();
    //int v2 = e->nativeScanCode();
    //int v3 = e->nativeVirtualKey();
    //qDebug() << QString("press 0x%1 0x%2 0x%3").arg(v1, 2, 16, QChar('0')).arg(v2, 2, 16, QChar('0')).arg(v3, 2, 16, QChar('0'));
    int code = 0;
    switch(e->key()) {
        case Qt::Key_Tab: code = 0x0d; break;
        case Qt::Key_AsciiTilde:
        case Qt::Key_Apostrophe: code = 0x0e; break;
        case Qt::Key_Q: code = 0x15; break;
        case Qt::Key_Exclam:
        case Qt::Key_1: code = 0x16; break;
        case Qt::Key_Z: code = 0x1a; break;
        case Qt::Key_S: code = 0x1b; break;
        case Qt::Key_A: code = 0x1c; break;
        case Qt::Key_W: code = 0x1d; break;
        case Qt::Key_At:
        case Qt::Key_2: code = 0x1e; break;
        case Qt::Key_C: code = 0x21; break;
        case Qt::Key_X: code = 0x22; break;
        case Qt::Key_D: code = 0x23; break;
        case Qt::Key_E: code = 0x24; break;
        case Qt::Key_Dollar:
        case Qt::Key_4: code = 0x25; break;
        case Qt::Key_NumberSign:
        case Qt::Key_3: code = 0x26; break;
        case Qt::Key_Space: code = 0x29; break;
        case Qt::Key_V: code = 0x2a; break;
        case Qt::Key_F: code = 0x2b; break;
        case Qt::Key_T: code = 0x2c; break;
        case Qt::Key_R: code = 0x2d; break;
        case Qt::Key_5: code = 0x2e; break;
        case Qt::Key_N: code = 0x31; break;
        case Qt::Key_B: code = 0x32; break;
        case Qt::Key_H: code = 0x33; break;
        case Qt::Key_G: code = 0x34; break;
        case Qt::Key_Y: code = 0x35; break;
        case Qt::Key_6: code = 0x36; break;
        case Qt::Key_M: code = 0x3a; break;
        case Qt::Key_J: code = 0x3b; break;
        case Qt::Key_U: code = 0x3c; break;
        case Qt::Key_7: code = 0x3d; break;
        case Qt::Key_8: code = 0x3e; break;
        case Qt::Key_Less:
        case Qt::Key_Comma: code = 0x41; break;
        case Qt::Key_K: code = 0x42; break;
        case Qt::Key_I: code = 0x43; break;
        case Qt::Key_O: code = 0x44; break;
        case Qt::Key_BracketRight:
        case Qt::Key_0: code = 0x45; break;
        case Qt::Key_BracketLeft:
        case Qt::Key_9: code = 0x46; break;
        case Qt::Key_Greater:
        case Qt::Key_Colon: code = 0x49; break;
        case Qt::Key_Question:
        case Qt::Key_Slash: code = 0x4a; break;
        case Qt::Key_L: code = 0x4b; break;
        case Qt::Key_Semicolon: code = 0x4c; break;
        case Qt::Key_P: code = 0x4d; break;
        case Qt::Key_Underscore:
        case Qt::Key_Minus: code = 0x4e; break;
        case Qt::Key_QuoteDbl: code = 0x52; break;
        case Qt::Key_BraceLeft: code = 0x54; break;
        case Qt::Key_Plus:
        case Qt::Key_Equal: code = 0x55; break;
        case Qt::Key_Enter: code = 0x5a; break;
        case Qt::Key_BraceRight: code = 0x5b; break;
        case Qt::Key_Backslash: code = 0x5d; break;

        case Qt::Key_Left: code = 0xe06b; break;
        case Qt::Key_Right: code = 0xe074; break;
        case Qt::Key_Up: code = 0xe075; break;
        case Qt::Key_Down: code = 0xe072; break;
        case Qt::Key_Shift: code = 0x12; break;
        case Qt::Key_Backspace: code = 0x66; break;
        case Qt::Key_Control: code = 0x14; break;
        case Qt::Key_Alt: code = 0x11; break;
        case Qt::Key_Delete: code = 0xe071; break;
        case Qt::Key_Escape: code = 0xe076; break;
        case Qt::Key_Home: code = 0xe06c; break;
        case Qt::Key_End: code = 0xe069; break;
    }
    if (code > 0xff) addByteToKeyboardQueue(0xe0);
    addByteToKeyboardQueue(code & 0xff);
}

void MIKSYS_display::keyReleaseEvent(QKeyEvent *e) {
    addByteToKeyboardQueue(0xf0);
    keyPressEvent(e);
}

void MIKSYS_display::paintEvent(QPaintEvent*) {
    if (system == NULL) return;
    unsigned graphic_flags = system->vga_control[5];
    unsigned text_flags = system->vga_control[2];
    unsigned background = (system->vga_control[4]<<8)|system->vga_control[3];
    unsigned graphic_address = background << 8;
    unsigned text_address = (system->vga_control[1]<<16)|(system->vga_control[0]<<8);

    QPainter painter(this);
    int sizex = 640;
    int sizey = 480;
    int char_sizex = 6;
    int char_sizey = 12;
    if (graphic_flags & 128) { // graphic disabled
        painter.fillRect(0, 0, sizex, sizey, getColor(background));
    } else { // graphic enabled
        for (int y = 0; y < sizey; ++y)
            for (int x = 0; x < sizex; ++x) {
                unsigned int addr = (graphic_address + y * sizex + x) % system->MEM_SIZE;
                painter.setPen(getColor(system->memory[addr]));
                painter.drawPoint(x, y);
            }
    }
    if (!(text_flags & 128)) { // text enabled
        painter.setFont(QFont("Monospace", 8));
        int cy = 0;
        for (int y = 0; y < sizey; y+=char_sizey) {
            int cx = 0;
            for (int x = 0; x < sizex; x+=char_sizex) {
                unsigned int addr = (text_address + cy * 128 + cx++) % system->MEM_SIZE;
                unsigned v = system->memory[addr];
                char c = v&0xff;
                if (!c) continue;
                int r = ((v>>13)&7)<<5;
                int g = ((v>>10)&7)<<5;
                int b = ((v>>8)&3)<<6;
                painter.setPen(QColor(r, g, b));
                painter.setBrush(QBrush(Qt::black));
                painter.drawText(x, y+12, QString(c));
            }
            cy++;
        }
    }
}
