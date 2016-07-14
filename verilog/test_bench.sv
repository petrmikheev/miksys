`timescale 1 ns/ 1 ps

module test_bench;

`include "sdram_model/sdr_parameters.vh"

      reg CLK100MHZ = 0;
      always #5 CLK100MHZ = ~CLK100MHZ;

      defparam top.SIMULATION = 1;
      
      reg in = 1;
      reg key = 0;//1;
      wire out = ftdi.BD1;
      FTDI_INTERFACE ftdi();
      VGA_INTERFACE vga();
      SDRAM_INTERFACE sdram();
      assign ftdi.BD0 = in;
      assign ftdi.BD2 = 0;
      wire [3:0] led;
      wire [11:0] IO;
      reg usb_out = 0;
      reg usb_m = 1;
      reg usb_p = 0;
      assign IO[1] = usb_out ? usb_m : 1'bz;
      assign IO[2] = usb_out ? usb_p : 1'bz;
      pulldown (IO[1]);
      pullup (IO[2]);
      
      reg ps2_clock = 1;
      reg ps2_data = 1;
      assign IO[8] = ps2_clock;
      assign IO[9] = ps2_data;
      reg [7:0] send_byte;
      integer i, j;
      initial begin
            #60000;
            for (j = 0; j < 10000; j = j+1) begin
                  send_byte = j[7:0] + 8'd65;
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
                  #100000;
            end
      end
      
      system_top top(
            .CLK100MHZ(CLK100MHZ),
            .KEY0(1'b1), .KEY1(key),
            .I_FTDI(ftdi),
            .I_VGA(vga),
            .I_SDRAM(sdram),
            .LED(led),
            .IO(IO)
      );
      
      parameter            hi_z = {DQ_BITS{1'bz}};                  // Hi-Z

      sdr sdram0 (
            sdram.DQ,
            sdram.A,
            {sdram.BA1, sdram.BA0},
            sdram.CLK,
            1'b1, 1'b0,
            sdram.RAS, sdram.CAS, sdram.WE, {sdram.LDQM, sdram.UDQM}
      );

      integer serial_file = $fopen("PATH_TO_SERIAL_IN", "rb");
      reg [7:0] serial_byte;
      integer k;
      initial begin
            #100000;
            while (!$feof(serial_file)) begin
                  #166;
                  in = 0; #83;
                  
                  serial_byte = $fgetc(serial_file);
                  for (k=0; k<8; k=k+1) begin
                        in = serial_byte[k]; #83;
                  end
                  
                  in = 1; #83;
                  
            end
      end
      
endmodule
