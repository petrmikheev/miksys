#ifndef MIKSYS_DISPLAY_H
#define MIKSYS_DISPLAY_H

#include <QWidget>
#include <miksys.h>

class MIKSYS_display : public QWidget
{
    Q_OBJECT
public:
    explicit MIKSYS_display(QWidget *parent = 0);
    void paintEvent(QPaintEvent*);
    inline void setMIKSYS(MIKSYS* system) { this->system = system; }
    void keyPressEvent(QKeyEvent *e);
    void keyReleaseEvent(QKeyEvent *e);
signals:
    void addByteToKeyboardQueue(unsigned char c);
private:
    MIKSYS* system;
};

#endif // MIKSYS_DISPLAY_H
