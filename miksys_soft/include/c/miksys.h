#ifndef MIKSYS_H
#define MIKSYS_H

/* Изменить состояние светодиодов. Используются только младшие 4 бита. */
void set_leds(unsigned leds);

/* Счетчик, увеличивающися 4000 раз в секунду */
unsigned get_time_ms4();

/* Счетчик, увеличивающийся на каждом такте */
unsigned get_clocks();

/* Возвращает состояние кнопки на плате */
int is_button_pressed();

#define PS2_0 0
#define PS2_1 1
#define SERIAL 2
/* Считать байт из порта. Если буфер пуст, возвращает -1. */
int getc(unsigned port);

/* Записать байт в порт. Если буфер переполнен, возвращает 0, иначе 1. */
int putc(unsigned port, char c);

/* Статистика sdram -- процент полезной нагрузки (когда передавались данные) и процент ожидания запроса (когда память готова к работе, но запросы отсутствуют). Оба числа принимают значения от 0 (0%) до 255 (100%). */
void sdram_stats(unsigned * work, unsigned * idle);

#define SDRAM_READ 0
#define SDRAM_WRITE 1
/* Обмен данным с микросхемой sdram */
void sdram(unsigned op, void* buf, unsigned size, long addr);

#define NUM2STR_LEFT 0x100
#define NUM2STR_SIGN 0x200
/* Перевод числа в строку */
void* num2str(void* buf, unsigned num, unsigned base, unsigned color);

#define TEXT_WHITE 0xff00
#define TEXT_RED 0xe000
#define TEXT_GREEN 0x1c00
#define TEXT_BLUE 0x300
#define PIXEL_RGB(r, g, b) ((r)&0xf800 | ((unsigned)(g))>>5)&0x07c0 | ((unsigned)(b))>>11)&0x1f)
#define TEXT_RGB(r, g, b) (((r)<<8)&0xe000 | ((g)<<5)&0x1c00 | ((b)<<2)&0x300)
#define ENABLE_FORMATTING 0
#define DISABLE_FORMATTING 1
/* Форматирование текста.
    %d -> десятичное со знаком
    %u -> десятичное без знака
    %b -> двоичное
    %x -> шеснадцатиричное
    %D, %U, %B, %X -> фиксированой ширины (расширяется влево от %)
    Возвращаемое значение: смещенный буфер
*/
void* print(void* buf, void* fmt, unsigned flags, ...);
#define str_unpack(buf, fmt) print(buf, fmt, DISABLE_FORMATTING)

void str_pack(void* dst, char* src);

//void set_display();

#define USB_ADDR(device, endpoint) ((device)|(unsigned)(endpoint)<<7)
#define USB_SENDRECV 0
#define USB_SEND 0x2000
#define USB_RECV 0x4000
#define USB_SEND_EMPTY 0xa000
/* Отправка запроса usb
addr = USB_ADDR(device, endpoint) | REQUEST_TYPE
Возвращаемое значение: 0 - fail, 1 - success
В data_out[0] записывается количество байтов для записи, в data_out[1] - первое слово (2 байта) и т.д.
*/
int usb_request(unsigned addr, void* data_out, void* data_in, unsigned size_in, unsigned *parity);

#endif
