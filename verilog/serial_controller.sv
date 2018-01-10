`include "bus_interfaces.sv"
`include "hardware_interfaces.sv"

module serial_controller (
            input wire reset,
            input clock,
            slowIO_interface.slave io_bus,
            FTDI_INTERFACE.OUT I_FTDI
      );

      parameter SIMULATION = 0;
      
      initial io_bus.read_odd = 0;
      initial io_bus.write_odd = 0;
      parameter DIVISOR_WIDTH = SIMULATION ? 4 : 8; //5;
      parameter DIVISOR = SIMULATION ? 4'd9 : 8'd234; //5'd18;
      parameter DIVISOR_HALF = SIMULATION ? 4'd2 : 8'd100; //5'd2;
      
      reg [3:0] read_bit_num = 0;
      reg [DIVISOR_WIDTH-1:0] read_state = 0;
      reg [7:0] read_data = 0;
      reg [3:0] write_bit_num = 0;
      reg [DIVISOR_WIDTH-1:0] write_state = 0;
      reg [7:0] write_data = 0;
      
      assign I_FTDI.BD3 = io_bus.try_stop_reading;
      initial I_FTDI.BD1 = 1;
      
      always @(posedge clock) begin
		if (reset) begin
			read_bit_num <= 0;
			read_state <= 0;
			io_bus.read_odd <= 0;
                  write_bit_num <= 0;
			write_state <= 0;
			io_bus.write_odd <= 0;
		end else begin
			if (|read_bit_num) begin
				if (|read_state)
					read_state <= read_state - 1'b1;
				else begin
					read_bit_num <= read_bit_num - 1'b1;
					read_data[6:0] <= read_data[7:1];
					read_data[7] <= I_FTDI.BD0;
					if ((read_bit_num==1) & I_FTDI.BD0) begin
						io_bus.data_read <= read_data;
						io_bus.read_odd <= ~io_bus.read_odd;
						read_state <= DIVISOR_HALF - 1'b1;
					end else read_state <= DIVISOR - 1'b1;
				end
			end else begin
				if (read_state == 0 & ~I_FTDI.BD0)
					read_state <= DIVISOR_HALF - 1'b1;
				else if ((read_state==1) & ~I_FTDI.BD0) begin
					read_state <= DIVISOR - 1'b1;
					read_bit_num <= 4'd9;
				end else if (|read_state)
					read_state <= read_state - 1'b1;
			end
                  if (|write_state) write_state <= write_state - 1'b1;
			else begin
				if (|write_bit_num) begin
					write_bit_num <= write_bit_num - 1'b1;
					write_data[6:0] <= write_data[7:1];
					write_data[7] <= 1;
					I_FTDI.BD1 <= write_data[0];
					write_state <= DIVISOR - 1'b1;
				end else if (~I_FTDI.BD2 && io_bus.write_odd_request != io_bus.write_odd) begin
					I_FTDI.BD1 <= 0;
					write_state <= DIVISOR - 1'b1;
					write_bit_num = 4'd9;
					write_data <= io_bus.data_write;
					io_bus.write_odd <= ~io_bus.write_odd;
				end else I_FTDI.BD1 <= 1;
			end
		end
	end
      
endmodule
