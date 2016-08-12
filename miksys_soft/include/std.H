/* Деление с остатком
* (r0=делимое, r1=делитель) -> (r0=остаток, r1=частное)
* Используются регистры r2, r3
*/
#define divide_func 0x0001AC

/*
В последующих функциях параметры и возвращаемые значения передаются через стек.
Указатель стека -- r15. Растет вверх.
[r15] -- первый параметр (и первое возвращаемое значение)
[r15+1] -- второй параметр и т.д.
*/

/* Перевод числа в текст
* (буфер, число, флаги|основание, цвет) -> (r0=смещенный буфер)
* флаг 0x100 = 0 -> буфер указывает на первый символ
* флаг 0x100 = 1 -> буфер указывает на последний символ
* флаг 0x200     -> отображать знак для отрицательных
*/
#define set_number_base_func 0x0001D4
#define C_num2str set_number_base_func

/* Форматирование текста для вывода на экран
* (буфер, строка, цвет|флаги, [число1], ..., [число9]) -> (r0=смещенный буфер)
* флаг 0x0001 = 0 -> Форматирование включено
* флаг 0x0001 = 1 -> Форматирование выключено
*/
#define printf_func 0x000240
#define C_print printf_func

/* Отправка запроса usb
* (addr, data_out, data_in, size_in, parity) -> (NULL, NULL, data_buf, ok, parity)
* addr = type | usb_endpoint<<7 | usb_address
* data_out -> size_out, bytes10, bytes32, ...
* type = 0x0000       : send request (with setup token) and receive answer
* type = 0x2000       : send data (with data_out token)
* type = 0x4000       : receive data
* type = 0xa000       : send empty data
*/
#define usb_request_func 0x0002E0

