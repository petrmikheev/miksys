/****************************************************************************
** Meta object code from reading C++ file 'miksys.h'
**
** Created by: The Qt Meta Object Compiler version 67 (Qt 5.2.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../qt_sim/miksys.h"
#include <QtCore/qbytearray.h>
#include <QtCore/qmetatype.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'miksys.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 67
#error "This file was generated using the moc from 5.2.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
struct qt_meta_stringdata_MIKSYS_t {
    QByteArrayData data[4];
    char stringdata[34];
};
#define QT_MOC_LITERAL(idx, ofs, len) \
    Q_STATIC_BYTE_ARRAY_DATA_HEADER_INITIALIZER_WITH_OFFSET(len, \
    offsetof(qt_meta_stringdata_MIKSYS_t, stringdata) + ofs \
        - idx * sizeof(QByteArrayData) \
    )
static const qt_meta_stringdata_MIKSYS_t qt_meta_stringdata_MIKSYS = {
    {
QT_MOC_LITERAL(0, 0, 6),
QT_MOC_LITERAL(1, 7, 22),
QT_MOC_LITERAL(2, 30, 0),
QT_MOC_LITERAL(3, 31, 1)
    },
    "MIKSYS\0addByteToKeyboardQueue\0\0c\0"
};
#undef QT_MOC_LITERAL

static const uint qt_meta_data_MIKSYS[] = {

 // content:
       7,       // revision
       0,       // classname
       0,    0, // classinfo
       1,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

 // slots: name, argc, parameters, tag, flags
       1,    1,   19,    2, 0x0a,

 // slots: parameters
    QMetaType::Void, QMetaType::UChar,    3,

       0        // eod
};

void MIKSYS::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        MIKSYS *_t = static_cast<MIKSYS *>(_o);
        switch (_id) {
        case 0: _t->addByteToKeyboardQueue((*reinterpret_cast< unsigned char(*)>(_a[1]))); break;
        default: ;
        }
    }
}

const QMetaObject MIKSYS::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_MIKSYS.data,
      qt_meta_data_MIKSYS,  qt_static_metacall, 0, 0}
};


const QMetaObject *MIKSYS::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *MIKSYS::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_MIKSYS.stringdata))
        return static_cast<void*>(const_cast< MIKSYS*>(this));
    return QObject::qt_metacast(_clname);
}

int MIKSYS::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 1)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 1;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 1)
            *reinterpret_cast<int*>(_a[0]) = -1;
        _id -= 1;
    }
    return _id;
}
QT_END_MOC_NAMESPACE
