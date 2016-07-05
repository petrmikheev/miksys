#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "miksys.h"
#include "fastcore.h"
#include <cstdio>
#include <ctime>
#include <unistd.h>

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    this->setFixedSize(this->size());
    miksys = new MIKSYS();
    QObject::connect(ui->display, SIGNAL(addByteToKeyboardQueue(unsigned char)), miksys, SLOT(addByteToKeyboardQueue(unsigned char)));
    miksys->serial_in = fopen("../miksys_soft/serial_in", "r");
    miksys->serial_out = fopen("../miksys_soft/serial_out", "w");
    ui->display->setMIKSYS(miksys);
    core = new FastCore(miksys, (char*)"../startup/startup.bin");
    updateLEDs(miksys->buttonState);
    timerId = -1;
    showInfo();
    running = false;
    RunThread* t = new RunThread();
    t->w = this;
    freq = 0;
    t->start();
}

void MainWindow::nextStep() {
    miksys->buttonState = ui->softButton->isChecked();
    core->update();
    core->handleNext();
    updateLEDs(miksys->LEDstate);
}

void MainWindow::updateLEDs(int v) {
    QString off = "background-color: gray";
    QString on = "background-color: green";
    ui->led3->setStyleSheet(v&1 ? on : off);
    ui->led2->setStyleSheet(v&2 ? on : off);
    ui->led1->setStyleSheet(v&4 ? on : off);
    ui->led0->setStyleSheet(v&8 ? on : off);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_commandline_returnPressed()
{
    QString c = ui->commandline->text();
    ui->commandline->clear();
    ui->log->append("> " + c);
    if (c.startsWith("c ")) {
        unsigned addr = c.mid(2).toInt();
        QString ans = QString("cache[%1:%2] = ").arg(addr).arg(addr+8);
        for (int i = 0; i<8; ++i) {
            int v = ((FastCore*)core)->cache[addr+i];
            ans += QString("%1 ").arg(v, 4, 16, QChar('0'));
        }
        ui->log->append(ans);
    }
    if (c == "vga") {
        QString ans = "vga_control: ";
        for (int i = 0; i<6; ++i) {
            int v = miksys->vga_control[i];
            ans += QString("%1 ").arg(v, 2, 16, QChar('0'));
        }
        ui->log->append(ans);
    }
    if (c.startsWith("goto ")) {
        char cond = c.at(5).toLatin1();
        unsigned addr = c.mid(7).toInt(NULL, 16) / 2;
        int jump_count = 0;
        int jump_from = -1, jump_to = -1;
        while (!((cond=='=' && core->ip == addr) || (cond=='>' && core->ip > addr) || (cond=='<' && core->ip < addr))) {
            core->update();
            int pos = core->ip;
            core->handleNext();
            if (pos+1 != (int)core->ip) {
                if (jump_from==pos && jump_to == (int)core->ip)
                    jump_count ++;
                else {
                    //if (jump_count>1) ui->log->append(QString("Count %1").arg(jump_count));
                    jump_count = 1;
                    jump_from = pos;
                    jump_to = core->ip;
                    //ui->log->append(QString("Jump from %1 to %2").arg(jump_from*2, 4, 16).arg(jump_to*2, 4, 16));
                }
            }
        }
        if (jump_count>0) {
            ui->log->append(QString("Jump from %1 to %2").arg(jump_from*2, 4, 16).arg(jump_to*2, 4, 16));
            ui->log->append(QString("Count %1").arg(jump_count));
        }
        showInfo();
    }
}

void MainWindow::showInfo() {
    ui->info->setText(core->getStateInfo());
}

void MainWindow::on_nextButton_clicked()
{
    nextStep();
    showInfo();
}

void MainWindow::on_resetButton_clicked()
{
    on_stopButton_clicked();
    usleep(10000);
    core->reset();
    showInfo();
}

void MainWindow::on_pushButton_clicked()
{
    ui->display->repaint();
    miksys->frame++;
}

void RunThread::run() {
    Core* core = w->core;
    while (true) {
        if (!w->running) {
            this->yieldCurrentThread();
            continue;
        }
        struct timespec ts;
        clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
        double t1 = ts.tv_sec + ts.tv_nsec * 1.0e-9;
        core->update();
        const int ccount = 100;
        for (int i = 0; i < ccount; ++i)
            if (w->running) core->handleNext();
        clock_gettime(CLOCK_MONOTONIC_RAW, &ts);
        double t2 = ts.tv_sec + ts.tv_nsec * 1.0e-9;
        w->freq = (ccount*1.0e-6) / (t2 - t1);
    }
}

void MainWindow::timerEvent(QTimerEvent *) {
    miksys->buttonState = ui->softButton->isChecked();
    updateLEDs(miksys->LEDstate);
    if (miksys->frame % 2 == 0) ui->display->repaint();
    miksys->frame++;
    showInfo();
    ui->frequency->setText(QString("Freq: %1 MHz").arg(freq));
}

void MainWindow::on_startButton_clicked()
{
    if (timerId != -1) return;
    miksys->buttonState = ui->softButton->isChecked();
    timerId = this->startTimer(20);
    running = true;
}

void MainWindow::on_stopButton_clicked()
{
    if (timerId == -1) return;
    this->killTimer(timerId);
    timerId = -1;
    running = false;
}
