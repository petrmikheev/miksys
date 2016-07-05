# miksys
SoC for Marsohod2

Файлы:
miksys.html - справка по системе команд
write.sh - загрузить прошивку в марсоход2
write_epcs4.sh - загрузить прошивку в микросхему epcs4 на плате разъемов
prepare_port.sh - установить нужные настройки последовательно порта
verilog/* - проект quartus
qt_sim - эмулятор (исходники)
qt_sim_build - эмулятор (откомпилированный для linux)
mbftdi - программатор http://marsohod.org/downloads/doc_download/91-programmator-usb-mbftdi-versiya-1-0
miksys_soft/compile.py - транслятор ассемблера
miksys_soft/pack.py - упаковывает откомпилированную программу для загрузки по последовательному порту
miksys_soft/pack_usb.py - упаковывает откомпилированную программу для загрузки по USB
miksys_soft/demo3d - демонстрационная программа с 3д графикой
