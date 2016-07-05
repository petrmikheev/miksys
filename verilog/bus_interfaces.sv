`ifndef bus_interface_h
`define bus_interface_h

/* Протокол:

1) master задает address, write_enable и устанавливает request
2) slave (возможно, пропустив несколько тактов) устанавливает ready
3) master передает/принимает данные в каждом такте
4) передача заканчивается, когда master сбрасывает request, либо slave сбрасывает ready
*) при записи ready означает, что данные должны быть переданы в следующем такте

*/

interface mem_interface;
      reg [15:0] data_read;
      reg [15:0] data_write;
      reg ready;
      reg request;
      reg write_enable;
      reg last4; // Используется при чтении.  "1" означает, что осталось считать не более 4 записей.
      reg [21:0] address;
      modport master(input data_read, output data_write, output write_enable, output last4,
                     input ready, output request, output address);
      modport slave(output data_read, input data_write, input write_enable, input last4,
                     output ready, input request, input address);
      modport monitor(input data_read, input data_write, input write_enable, input last4,
                     input ready, input request, input address);
endinterface

/* peripheral bus
      address = 0: serial port r/w
      address = 1: sdram statistic
            read 2 bytes: work, idle
      address = 2: vga control
            read 1 byte: frame_number
            write 8 bytes: 7-0
                  {8'graphic_flags, 24'graphic_address(if enabled)/{8'x,16'background}(if disabled),
                   8'text_flags, 24'text_address}
                  flags[7] -- disable

Протокол:
Чтение
      Установить на один такт read_request
      В следующем такте получить данные. Если ready не установлен -- чтение не удалось
Запись
      Установить на один такт write_request
      В следующем такте передать данные. Если ready не установлен -- запись не удалась
*/
interface peripheral_interface;
      reg [7:0] data_read;
      reg [7:0] data_write;
      reg read_ready;
      reg write_ready;
      reg read_request;
      reg write_request;
      reg [2:0] address;
      modport master(input data_read, output data_write, output read_request, output write_request,
                     input read_ready, input write_ready, output address);
      modport slave(output data_read, input data_write, input read_request, input write_request,
                     output read_ready, output write_ready, input address);
endinterface

interface slowIO_interface;
      reg [7:0] data_write;
      reg write_odd_request;
      reg write_odd;
      reg [7:0] data_read;
      reg try_stop_reading;
      reg read_odd;
      modport master(output data_write, output write_odd_request, input write_odd, input data_read,
                      output try_stop_reading, input read_odd);
      modport slave(input data_write, input write_odd_request, output write_odd, output data_read,
                      input try_stop_reading, output read_odd);
endinterface

`endif
