#ifndef CORE_H
#define CORE_H

#include "miksys.h"
#include <QString>

class Core {
    public:
        virtual void reset() = 0;
        virtual void handleNext() = 0;
        virtual QString getStateInfo() = 0;
        inline virtual void update() {}
        MIKSYS* system;
};

#endif // CORE_H
