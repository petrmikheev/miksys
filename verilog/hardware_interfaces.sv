`ifndef hardware_interfaces_h
`define hardware_interfaces_h

interface VGA_INTERFACE;
      reg [4:0] RED;
      reg [5:0] GREEN;
      reg [4:0] BLUE;
      reg HSYNC;
      reg VSYNC;
      modport OUT(output RED, output GREEN, output BLUE, output HSYNC, output VSYNC);
endinterface

interface SDRAM_INTERFACE;
      wire [15:0] DQ;
      reg [11:0] A;
      reg LDQM;
      reg UDQM;
      reg BA0;
      reg BA1;
      reg RAS;
      reg CAS;
      reg WE;
      reg CLK;
      modport OUT(
            inout DQ,
            output A, output LDQM, output UDQM, output BA0, output BA1,
            output RAS, output CAS, output WE, output CLK
      );
endinterface

interface FTDI_INTERFACE;
      reg BD0; // RXD
      reg BD1; // TXD
      reg BD2; // CTS#
      reg BD3; // RTS#
      modport OUT(input BD0, output BD1, input BD2, output BD3);
endinterface

`endif
