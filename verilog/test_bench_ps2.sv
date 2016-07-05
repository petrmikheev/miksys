`timescale 1 ns/ 1 ps

`include "bus_interfaces.sv"

module test_bench_ps2;

      reg clock = 0;
      always #5 clock = ~clock;

      /*wire ps2_clock = 1'bz;
      wire ps2_data = 1'bz;
      pullup(ps2_clock);
      pullup(ps2_data);*/
      
      reg ps2_clock = 1;
      reg ps2_data = 1;
      wire ps2c = ps2_clock;
      wire ps2d = ps2_data;
      reg [7:0] send_byte;
      integer i, j;
      initial begin
            #60000;
            for (j = 0; j < 20; j = j+1) begin
                  send_byte = 133;
                  ps2_data = 0; ps2_clock = 0; #30000;
                  ps2_clock = 1; #30000;
                  for (i=0; i<8; i=i+1) begin
                        ps2_data = send_byte[i]; ps2_clock = 0; #30000;
                        ps2_clock = 1; #30000;
                  end
                  ps2_data = ~^send_byte; ps2_clock = 0; #30000;
                  ps2_clock = 1; #30000;
                  ps2_data = 1; ps2_clock = 0; #30000;
                  ps2_clock = 1; #30000;
                  #500000;
            end
      end
      
      slowIO_interface ps2_bus();
      ps2_controller ps2(
            .clock(clock),
            .reset(1'b0),
            .io_bus(ps2_bus),
            .ps2_clock(ps2c),
            .ps2_data(ps2d)
      );

      defparam ps2_buf.ADDR = 3'd4;
      defparam ps2_buf.WRITE_BUF_SIZE = 0;
      peripheral_interface peripheral_bus();
      slowIO_buffer ps2_buf(
            .reset(1'b0),
            .clock(clock),
            .peripheral_bus(peripheral_bus),
            .io_bus(ps2_bus)
      );
      assign peripheral_bus.write_request = 0;
      assign peripheral_bus.address = 3'd4;
      reg [9:0] c = 0;
      always #10 c = c + 1'b1;
      assign peripheral_bus.read_request = c == 0;
      
endmodule
