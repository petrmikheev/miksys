`include "bus_interfaces.sv"
`include "hardware_interfaces.sv"

module system_top (
            input CLK100MHZ,
            input KEY0, input KEY1,
            output [3:0] LED,
            VGA_INTERFACE.OUT I_VGA,
            SDRAM_INTERFACE.OUT I_SDRAM,
            FTDI_INTERFACE.OUT I_FTDI,
            inout [11:0] IO
       );
      
      assign IO[0] = 'z;
      assign IO[7:3] = 'z;
      
      parameter SIMULATION = 0;
           
	wire system_clock; // 108mhz
      wire system_shifted_clock, pll_shifted_clock; // 108mhz +147 degrees
      wire vga_clock; // 25.175mhz
      //wire high_rate_clock; // 264mhz
	PLL1 pll1(
		.inclk0(CLK100MHZ),
		.c0(system_clock),
		.c1(pll_shifted_clock),
		.c2(vga_clock)
		//.c4(high_rate_clock)
	);
      assign system_shifted_clock = SIMULATION ? system_clock : pll_shifted_clock;
      
      wire reset;
      wire [15:0] time_ms4;
      wire [15:0] time_clock;
      defparam timer0.SIMULATION = SIMULATION;
      timer timer0(
            .clock(system_clock),
            .reset(~KEY0),
            .protected_reset(reset),
            .time_ms4(time_ms4),
            .time_clock(time_clock)
      );
      
      mem_interface mem_bus[2]();
      mem_interface sdram_bus();      
      peripheral_interface peripheral_bus();
      
      core system_core(
            .reset(reset),
            .clock(system_clock),
            .time_ms4(time_ms4),
            .time_clock(time_clock),
            .special_key(~KEY1),
            .LED(LED),
            .mem_bus(mem_bus[0]),
            //.command_mem_bus(mem_bus[2]),
            .peripheral_bus(peripheral_bus)
      );    
      
      wire memory_switch;
      memory_multiplexer #(2) sdram_manager(
            .clock(system_clock),
            .resource(sdram_bus),
            .port_list(mem_bus),
            .switch(memory_switch)
      );
      
      peripheral_interface peripheral_bus_list[6]();
      peripheral_multiplexer #(6) per_m(
            .master(peripheral_bus),
            .port_list(peripheral_bus_list)
      );
      
      defparam sdram.SIMULATION = SIMULATION;
      sdram_controller sdram(
            .reset(reset),
            .clock(system_clock), .clock_shifted(system_shifted_clock),
            .I_SDRAM(I_SDRAM),
            .data_bus(sdram_bus),
            .last_word(memory_switch),
            .peripheral_bus(peripheral_bus_list[0])
      );
      
      vga_controller vga(
            .reset(reset),
            .clock(system_clock), .vga_clock(vga_clock),
            .I_VGA(I_VGA),
            .mem_bus(mem_bus[1]),
            .peripheral_bus(peripheral_bus_list[1])
      );
      
      defparam serial.SIMULATION = SIMULATION;
      slowIO_interface serial_bus();
      serial_controller serial(
            .reset(reset),
            .clock(system_clock),
            .io_bus(serial_bus),
            .I_FTDI(I_FTDI)
      );
      defparam serial_buf.ADDR = 3'd0;
      slowIO_buffer serial_buf(
            .reset(reset),
            .clock(system_clock),
            .peripheral_bus(peripheral_bus_list[2]),
            .io_bus(serial_bus)
      );
      
      /*wire [7:0] debug;
      defparam direct.ADDR = 3'd7;
      direct_io direct(
            .clock(system_clock),
            .peripheral_bus(peripheral_bus_list[6]),
            .io(debug)
      );*/
      
      slowIO_interface ps2_0_bus();
      ps2_controller ps2_0(
            .reset(reset),
            .clock(system_clock),
            .io_bus(ps2_0_bus),
            .ps2_clock(IO[8]),
            .ps2_data(IO[9])
            //.debug(debug)
      );
      defparam ps2_0_buf.ADDR = 3'd4;
      defparam ps2_0_buf.WRITE_BUF_SIZE = 0;
      slowIO_buffer ps2_0_buf(
            .reset(reset),
            .clock(system_clock),
            .peripheral_bus(peripheral_bus_list[3]),
            .io_bus(ps2_0_bus)
      );
      
      slowIO_interface ps2_1_bus();
      ps2_controller ps2_1(
            .reset(reset),
            .clock(system_clock),
            .io_bus(ps2_1_bus),
            .ps2_clock(IO[10]),
            .ps2_data(IO[11])
      );
      defparam ps2_1_buf.ADDR = 3'd5;
      defparam ps2_1_buf.WRITE_BUF_SIZE = 0;
      slowIO_buffer ps2_1_buf(
            .reset(reset),
            .clock(system_clock),
            .peripheral_bus(peripheral_bus_list[4]),
            .io_bus(ps2_1_bus)
      );
      
      defparam usb0.SIMULATION = SIMULATION;
      defparam usb0.ADDR = 3'd6;
      usb_controller usb0(
            .reset(reset),
            .clock(system_clock),
            .time_ms4(time_ms4),
            .peripheral_bus(peripheral_bus_list[5]),
            .d_m(IO[1]),
            .d_p(IO[2])
      );
      
endmodule
