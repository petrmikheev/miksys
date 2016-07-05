/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 5.2.1
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QAction>
#include <QtWidgets/QApplication>
#include <QtWidgets/QButtonGroup>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QRadioButton>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QTabWidget>
#include <QtWidgets/QTextEdit>
#include <QtWidgets/QToolBar>
#include <QtWidgets/QWidget>
#include "miksys_display.h"

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QWidget *centralWidget;
    QPushButton *resetButton;
    QRadioButton *softButton;
    QWidget *led0;
    QWidget *led1;
    QWidget *led2;
    QWidget *led3;
    QTabWidget *tabWidget;
    QWidget *displayTab;
    MIKSYS_display *display;
    QWidget *debugTab;
    QTextEdit *log;
    QLineEdit *commandline;
    QTextEdit *info;
    QPushButton *nextButton;
    QPushButton *pushButton;
    QPushButton *startButton;
    QPushButton *stopButton;
    QLabel *frequency;
    QMenuBar *menuBar;
    QToolBar *mainToolBar;
    QStatusBar *statusBar;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName(QStringLiteral("MainWindow"));
        MainWindow->resize(680, 610);
        QSizePolicy sizePolicy(QSizePolicy::Preferred, QSizePolicy::Preferred);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(0);
        sizePolicy.setHeightForWidth(MainWindow->sizePolicy().hasHeightForWidth());
        MainWindow->setSizePolicy(sizePolicy);
        MainWindow->setAnimated(true);
        centralWidget = new QWidget(MainWindow);
        centralWidget->setObjectName(QStringLiteral("centralWidget"));
        resetButton = new QPushButton(centralWidget);
        resetButton->setObjectName(QStringLiteral("resetButton"));
        resetButton->setGeometry(QRect(320, 10, 71, 27));
        softButton = new QRadioButton(centralWidget);
        softButton->setObjectName(QStringLiteral("softButton"));
        softButton->setGeometry(QRect(420, 0, 51, 22));
        led0 = new QWidget(centralWidget);
        led0->setObjectName(QStringLiteral("led0"));
        led0->setGeometry(QRect(490, 0, 21, 21));
        led1 = new QWidget(centralWidget);
        led1->setObjectName(QStringLiteral("led1"));
        led1->setGeometry(QRect(530, 0, 21, 21));
        led2 = new QWidget(centralWidget);
        led2->setObjectName(QStringLiteral("led2"));
        led2->setGeometry(QRect(570, 0, 21, 21));
        led3 = new QWidget(centralWidget);
        led3->setObjectName(QStringLiteral("led3"));
        led3->setGeometry(QRect(610, 0, 21, 21));
        tabWidget = new QTabWidget(centralWidget);
        tabWidget->setObjectName(QStringLiteral("tabWidget"));
        tabWidget->setGeometry(QRect(20, 50, 644, 513));
        displayTab = new QWidget();
        displayTab->setObjectName(QStringLiteral("displayTab"));
        display = new MIKSYS_display(displayTab);
        display->setObjectName(QStringLiteral("display"));
        display->setGeometry(QRect(0, 0, 640, 480));
        display->setFocusPolicy(Qt::ClickFocus);
        tabWidget->addTab(displayTab, QString());
        debugTab = new QWidget();
        debugTab->setObjectName(QStringLiteral("debugTab"));
        log = new QTextEdit(debugTab);
        log->setObjectName(QStringLiteral("log"));
        log->setGeometry(QRect(10, 10, 281, 421));
        log->setReadOnly(true);
        commandline = new QLineEdit(debugTab);
        commandline->setObjectName(QStringLiteral("commandline"));
        commandline->setGeometry(QRect(10, 440, 341, 31));
        info = new QTextEdit(debugTab);
        info->setObjectName(QStringLiteral("info"));
        info->setGeometry(QRect(300, 10, 331, 421));
        info->setReadOnly(true);
        nextButton = new QPushButton(debugTab);
        nextButton->setObjectName(QStringLiteral("nextButton"));
        nextButton->setGeometry(QRect(360, 440, 99, 27));
        tabWidget->addTab(debugTab, QString());
        pushButton = new QPushButton(centralWidget);
        pushButton->setObjectName(QStringLiteral("pushButton"));
        pushButton->setGeometry(QRect(210, 10, 81, 27));
        startButton = new QPushButton(centralWidget);
        startButton->setObjectName(QStringLiteral("startButton"));
        startButton->setGeometry(QRect(20, 10, 61, 27));
        stopButton = new QPushButton(centralWidget);
        stopButton->setObjectName(QStringLiteral("stopButton"));
        stopButton->setGeometry(QRect(110, 10, 61, 27));
        frequency = new QLabel(centralWidget);
        frequency->setObjectName(QStringLiteral("frequency"));
        frequency->setGeometry(QRect(430, 30, 171, 17));
        MainWindow->setCentralWidget(centralWidget);
        menuBar = new QMenuBar(MainWindow);
        menuBar->setObjectName(QStringLiteral("menuBar"));
        menuBar->setGeometry(QRect(0, 0, 680, 25));
        MainWindow->setMenuBar(menuBar);
        mainToolBar = new QToolBar(MainWindow);
        mainToolBar->setObjectName(QStringLiteral("mainToolBar"));
        MainWindow->addToolBar(Qt::TopToolBarArea, mainToolBar);
        statusBar = new QStatusBar(MainWindow);
        statusBar->setObjectName(QStringLiteral("statusBar"));
        MainWindow->setStatusBar(statusBar);

        retranslateUi(MainWindow);

        tabWidget->setCurrentIndex(0);


        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QApplication::translate("MainWindow", "MIKSYS Simulation", 0));
        resetButton->setText(QApplication::translate("MainWindow", "Reset", 0));
        softButton->setText(QApplication::translate("MainWindow", "K", 0));
        tabWidget->setTabText(tabWidget->indexOf(displayTab), QApplication::translate("MainWindow", "Display", 0));
        nextButton->setText(QApplication::translate("MainWindow", "Next", 0));
        tabWidget->setTabText(tabWidget->indexOf(debugTab), QApplication::translate("MainWindow", "Debug", 0));
        pushButton->setText(QApplication::translate("MainWindow", "Redraw", 0));
        startButton->setText(QApplication::translate("MainWindow", "Start", 0));
        stopButton->setText(QApplication::translate("MainWindow", "Stop", 0));
        frequency->setText(QString());
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
