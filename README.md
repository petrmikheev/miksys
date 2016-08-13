# miksys

MIKSYS -- это SoC, разработанная для платы Марсоход2 (http://marsohod.org/prodmarsohod2) с ПЛИС Altera Cyclone III.
Работа выполнена для получения опыта разработки на verilog. Практической ценности не имеет.
Была поставлена цель выжать из платы производительность, достаточную для отображения 3д графики.

Обсуждение проекта: http://marsohod.org/forum/proekty-polzovatelej/4110-realizatsiya-3d-grafiki-na-plate-marsohod2

# Файлы:

* doc/miksys.html - справка по системе команд
* prepare_port.sh - установить нужные настройки последовательного порта (linux)
* verilog/* - проект quartus
* qt_sim - эмулятор
* mbftdi - программатор http://marsohod.org/downloads/doc_download/91-programmator-usb-mbftdi-versiya-1-0 (linux)
* miksys_soft/miksys_cc.py - компилятор СИ для miksys, основанный на LCC 4.2
* miksys_soft/miksys_asm.py - транслятор ассемблера
* miksys_soft/pack.py - упаковывает откомпилированную программу для загрузки по последовательному порту
* miksys_soft/pack_usb.py - упаковывает откомпилированную программу для загрузки по USB
* miksys_soft/demo3d - демонстрационная программа с 3д графикой. Режим вращения и перспектива переключаются кнопкой на плате (вторая кнопка - reset). Можно управлять вращением с PS/2 клавиатуры (кнопки WASD) или с PS/2 мыши (управление мышью глючит).
* miksys_soft/mikasm.lang - подсветка синтаксиса ассемблера для gtksourceview
* miksys_soft/ustartup - загрузчик
* miksys_soft/include/std.H - описания и адреса функций, находящихся в загрузчике. При пересборке загрузчика файл обновляется автоматически.


# Инструкция для Linux:

Путь к quartus/bin (версия 13.1) должен быть добавлен в PATH.
Зависимости для эмулятора: libqt4-dev libqt4-dev-bin qt4-qmake qtcreator.

## Сборка проекта и демонстрационной программы demo3d:

    $ make

## Запуск demo3d в эмуляторе:

    $ make sim_demo3d

Нажать на Start.

Должен появиться крутящийся домик. Крутиться будет медленно и рывками, т.к эмулятор раз в 10 медленнее оригинала. Вращение и перспектива переключается кнопкой на плате. В qt_sim кнопка на плате соответствует чекбоксу "К". Для переключения режима нужно нажать на него, подождать пару секунд (т.к эмулятор работает медленно) и нажать еще раз.

Если автоматическое вращение остановлено, поворотом домика можно управлять с клавиатуры (WASD). В qt_sim перед этим нужно кликнуть на изображение, чтобы фокус ввода перешел куда нужно. Эмуляция мышки в qt_sim на данный момент не реализована.

## Написание программы на ассемблере

Справка по архитектуре и командам находится в miksys.html. Приведенные там примеры программ можно найти в miksys_soft/examples.

Сборка программы some_prog.S выглядит так:

    ./miksys_asm.py some_prog.S some_prog.bin  # компиляция
    ./pack.py some_prog.bin some_prog.packed   # добавление контрольной суммы для загрузки через последомательный порт
    ./pack_usb.py some_prog.bin some_prog.usb_packed   # добавление контрольной суммы для загрузки по USB
    cp some_prog.packed serial_in              # нужно, чтобы запустить some_prog в эмуляторе. Эмулятор загружается из miksys_soft/serial_in

## Написание программы на C

Рекомендуется добавить ссылку на miksys_cc.py в /usr/local/bin:
    $ ln -s `pwd`/miksys_soft/miksys_cc.py /usr/local/bin/miksys_cc

Компиляция демонстрационной программы, выводящей список простых чисел:
    $ cd miksys_soft/examples
    $ miksys_cc primes.c -o primes -pserial

Заголовочные файлы по умолчанию берутся из каталога miksys_soft/include/c

Особенности реализации C в miksys:
* В одном байте 16 бит и sizeof(int) = sizeof(char) = 1
* Доступны только данные, находящиеся в кэше. Загрузка в кэш осуществляется явно (вызовом функции sdram из miksys.h).
* Не поддерживаются указатели на функции (т.к. адресное пространство данных соответствует кэшу, а функции вызываются по адресу в sdram)
* Не поддерживаются функции с переменным числом аргументов

## Запись прошивки в марсоход2:
    $ make write

## Запись прошивки в EPCS4 на плате разъемов к марсоход2:
    $ make write_epcs4

## Загрузка через последовательный порт
Настроить baud_rate виртуального последовательного порта 6MHz (в линуксе делается скриптом prepare_port.sh).
Отправить some_program.packed в последовательный порт.

    $ ./prepare_port.sh
    $ cat miksys_soft/demo3d/demo3d.packed > /dev/serial/by-id/usb-FTDI_Dual_RS232-HS-if01-port0

## Загрузка с флешки

Работает не для всех флешек (я использую флешку SanDisk CruzerBlade - для неё работает).

Откомпилированную программу нужно записать на флешку, начиная с блока 2048 (начало 2-го мегабайта).
Это удобно сделать, если настроить таблицу разделов на флешке, чтобы один из разделов начинался с этого адреса. Например:

    Устр-во Загр     Начало       Конец       Блоки   Id  Система
    /dev/sdb1          264192    15633407     7684608   83  Linux
    /dev/sdb2            2048      264191      131072   83  Linux

В этом случае запись на флешку осуществляется командой `sudo dd if=miksys_soft/demo3d/demo3d.usb_packed of=/dev/sdb2`

# Инструкция для Windows:

По идее в Windows всё должно работать. Но это никто не проверял. И скриптов сборки тоже нет.

Если вы собрали этот проект в Windows и готовы поделиться инструкцией, пожалуйста, отпишитесь на форуме
http://marsohod.org/forum/proekty-polzovatelej/4110-realizatsiya-3d-grafiki-na-plate-marsohod2

# Недоработки:

1) Не реализована работа со звуком

2) Не реализован кэш команд. На данный момент кэш команд жестко привязан к адресам 0x100000-0x101000 оперативной памяти.
Т.е. любой исполняемый код (кроме кода загрузчика) должен лежать в этом кусочке оперативной памяти. Загрузчик размещает программу по адресу 0x100000 и передаёт туда управление.

3) Не реализованы команды LPU0-LPU3
