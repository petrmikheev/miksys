`include "bus_interfaces.sv"

module direct_io(
            input wire clock,
            peripheral_interface.slave peripheral_bus,
            input wire [7:0] io
);
      parameter ADDR = 0;
      wire choosed = peripheral_bus.address == ADDR;
      assign peripheral_bus.read_ready = choosed;
      assign peripheral_bus.write_ready = 0;
      always @(posedge clock) begin
            peripheral_bus.data_read <= choosed ? io : '0;
      end

endmodule
