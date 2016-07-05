#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QThread>
#include "miksys.h"
#include "fastcore.h"

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

private slots:
    void on_commandline_returnPressed();

    void on_nextButton_clicked();

    void on_resetButton_clicked();

    void on_pushButton_clicked();

    void on_startButton_clicked();

    void on_stopButton_clicked();

    void timerEvent(QTimerEvent *);

public:
    bool running;
    int timerId;
    int timerCounter;
    Ui::MainWindow *ui;
    void updateLEDs(int);
    void nextStep();
    void showInfo();
    MIKSYS* miksys;
    FastCore* core;
    double freq;
};

class RunThread : public QThread
{
    Q_OBJECT
public:
    MainWindow* w;
private:
    void run();
};

#endif // MAINWINDOW_H
