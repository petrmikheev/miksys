`include "bus_interfaces.sv"

module slowIO_buffer(
            input wire reset,
            input wire clock,
            peripheral_interface.slave peripheral_bus,
            slowIO_interface.master io_bus
      );
      
      parameter ADDR = 3'b0;
      parameter READ_BUF_SIZE = 8;
      parameter READ_BUF_WIDTH = 3;
      parameter WRITE_BUF_SIZE = 8;
      parameter WRITE_BUF_WIDTH = 3;
      
      initial io_bus.data_write = '0;
      
      generate
            if (READ_BUF_SIZE > 0) begin
                  reg [READ_BUF_SIZE-1:0][7:0] read_buf = '0;
                  reg [READ_BUF_WIDTH-1:0] read_head = 0, read_tail = 0;
                  assign io_bus.try_stop_reading = read_head + 1'b1 == read_tail;
                  always @(posedge clock) begin
                        if (reset) begin
                              read_head <= 0;
                              read_tail <= 0;
                              peripheral_bus.read_ready <= 0;
                        end else begin
                              if (io_bus.read_odd != read_head[0]) begin
                                    read_head <= read_head + 1'b1;
                                    read_buf[read_head] <= io_bus.data_read;
                              end
                              if (peripheral_bus.address == ADDR && peripheral_bus.read_request) begin
                                    peripheral_bus.data_read <= read_buf[read_tail];
                                    peripheral_bus.read_ready <= read_tail != read_head;
                                    if (read_tail != read_head) read_tail <= read_tail + 1'b1;
                              end else begin
                                    peripheral_bus.data_read <= '0;
                                    peripheral_bus.read_ready <= 0;
                              end
                        end
                  end
            end else begin
                  reg read_odd = 0;
                  assign io_bus.try_stop_reading = io_bus.read_odd ^ read_odd;
                  always @(posedge clock) begin
                        if (reset) begin
                              read_odd <= 0;
                              peripheral_bus.read_ready <= 0;
                        end else begin
                              if (peripheral_bus.address == ADDR && peripheral_bus.read_request) begin
                                    peripheral_bus.data_read <= io_bus.data_read;
                                    peripheral_bus.read_ready <= io_bus.read_odd ^ read_odd;
                                    read_odd <= io_bus.read_odd;
                              end else begin
                                    peripheral_bus.data_read <= '0;
                                    peripheral_bus.read_ready <= 0;
                              end
                        end
                  end
            end
            if (WRITE_BUF_SIZE > 0) begin
                  reg [WRITE_BUF_SIZE-1:0][7:0] write_buf = '0;
                  reg [WRITE_BUF_WIDTH-1:0] write_head = 0, write_tail = 0;
                  assign io_bus.write_odd_request = write_tail[0];
                  always @(posedge clock) begin
                        if (reset) begin
                              write_tail <= 0;
                              write_head <= 0;
                              peripheral_bus.write_ready <= 0;
                        end else begin
                              if (io_bus.write_odd == write_tail[0] && write_head != write_tail) begin
                                    write_tail <= write_tail + 1'b1;
                                    io_bus.data_write <= write_buf[write_tail];
                              end
                              peripheral_bus.write_ready <= peripheral_bus.write_request && peripheral_bus.address == ADDR && write_head + 1'b1 != write_tail;
                              if (peripheral_bus.address == ADDR && peripheral_bus.write_ready) begin
                                    if (write_head + 1'b1 != write_tail) write_head <= write_head + 1'b1;
                                    write_buf[write_head] <= peripheral_bus.data_write;
                              end
                        end
                  end
            end else begin
                  reg write_odd = 0;
                  assign io_bus.write_odd_request = write_odd;
                  always @(posedge clock) begin
                        if (reset) begin
                              write_odd <= 0;
                              peripheral_bus.write_ready <= 0;
                        end else begin
                              peripheral_bus.write_ready <= peripheral_bus.write_request && peripheral_bus.address == ADDR && write_odd == io_bus.write_odd;
                              if (peripheral_bus.address == ADDR && peripheral_bus.write_ready) begin
                                    write_odd <= ~write_odd;
                                    io_bus.data_write <= peripheral_bus.data_write;
                              end
                        end
                  end
            end
      endgenerate  
endmodule
