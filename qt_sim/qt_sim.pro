#-------------------------------------------------
#
# Project created by QtCreator 2015-08-23T14:50:24
#
#-------------------------------------------------

QT       += core gui
QMAKE_CXXFLAGS += -O5 -funroll-loops

# QMAKE_CXXFLAGS += -fopenmp
# QMAKE_LFLAGS += -fopenmp

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = qt_sim
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp \
    miksys.cpp \
    testcore.cpp \
    miksys_display.cpp \
    fastcore.cpp

HEADERS  += mainwindow.h \
    miksys.h \
    core.h \
    testcore.h \
    miksys_display.h \
    fastcore.h

FORMS    += mainwindow.ui
