`ifndef opcodes_h
`define opcodes_h

enum reg [4:0] {
      NOP = 5'h0,
      JUMP = 5'h1,
      CMOV = 5'h2,
      CCMOV = 5'h3,

      DJUMP = 5'h5,
      
      SHL = 5'hc,
      SHR = 5'hd,
      MUL = 5'he,
      RW = 5'hf,
      OR = 5'h10,
      XOR = 5'h11,
      AND = 5'h12,
      TST = 5'h13,
      MOV = 5'h14,

      RGBADD = 5'h16,
      RGBSHR = 5'h17,
      ADD = 5'h18,
      RSB = 5'h19,
      SUB = 5'h1a,
      CMP = 5'h1b,
      ADC = 5'h1c,
      RSC = 5'h1d,
      SBC = 5'h1e
} OPCODE;

`endif
