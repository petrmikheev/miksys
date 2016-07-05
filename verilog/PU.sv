`include "opcodes.sv"

module PU #(parameter PU_INDEX = 0, MUL_ENABLED = 1, SHIFT_ENABLED = 1)
(
                  input wire clock,
                  input wire enabled,
                  
                  input wire [15:0] hi_rb,
                  input wire [15:0] hi_rd,
                  output reg [7:0][15:0] hi_regs_out,
                  
                  output reg [15:0] cache_waddr,
                  input wire [15:0] cache_rdata,
                  output reg [15:0] cache_wdata,
                  
                  // control wires
                  input wire ST5_wr_reg,
                  input wire ST5_wr_sreg,
                  input wire [3:0] ST5_reg,
                  input wire ST5_set_flags,
                  input wire ST4_rd_cache,
                  input wire ST5_call,
                  input wire [6:0] ST3_addr_offset,
                  input wire [3:0] ST4_b,
                  input wire [3:0] ST4_d,
                  input wire [3:0] ST4_sreg_num,
                  input wire ST4_bsreg,
                  input wire [1:0] ST4_p2type,
                  input wire [15:0] ST4_const,
                  input wire ST4_inv1,
                  input wire ST4_inv2,
                  input wire [31:0] ST4_command,
                  input wire [3:0] st2_r,
                  input wire ST4_mov_arg1,
                  input wire ST4_res_to_p1,
                  
                  // output
                  output reg [15:0] ST5_p1,
                  output reg [15:0] ST5_p2,
                  output reg [15:0] ST3_reg_r,
                  output reg st5_cond_met,
                  
                  // special in
                  input wire special_key,
                  input wire sdram_is_running,
                  input wire [15:0] time_ms4,
                  input wire [15:0] time_clock,
                  //input wire [15:0] fp_res,
                  input wire [31:0] ip_for_return,
                  input wire [7:0] peripheral_in,
                  input wire ST5_peripheral_operation,
                  input wire ST5_peripheral_success,
                  
                  // special out
                  output reg [31:0] mem_addr,
                  output reg [3:0] LED,
                  output reg [7:0] peripheral_out
);

      localparam MAIN_PU = PU_INDEX == 0;
      
      reg [7:0][15:0] lo_regs = '0;
      initial hi_regs_out = '0;
      task set_reg;
            input [3:0] n;
            input [15:0] v;
            if (~n[3])
                  lo_regs[n[2:0]] <= v;
            else if (MAIN_PU)
                  hi_regs_out[n[2:0]] <= v;
      endtask
      
      reg flagZ = 0;
      reg flagN = 0;
      reg flagC = 0;
      reg flagV = 0;
      reg last_enabled = 0;
      initial LED = 4'b0;
      initial ST3_reg_r = '0;
      initial mem_addr = '0;
      initial cache_waddr = '0;
      reg [31:0] mult_res = '0;
      reg [15:0] ST6_p1;
      reg [15:0] ST6_p2;
      
      function [15:0] sreg_in;
            input [3:0] addr;
            case (addr[2:0])
                  3'd0: sreg_in = {8'b0, flagC, flagV, flagZ, flagN, sdram_is_running, special_key, PU_INDEX[1:0]};
                  3'd1: sreg_in = mem_addr[15:0];
                  3'd2: sreg_in = mem_addr[31:16];
                  3'd3: sreg_in = time_clock;
                  3'd4: sreg_in = time_ms4;
                  3'd5: sreg_in = mult_res[15:0];
                  3'd6,3'd7: sreg_in = mult_res[31:16];
            endcase
      endfunction
      task sreg_out;
            input [3:0] addr;
            input [15:0] v;
            case (addr[1:0])
                  2'd0: LED <= v[3:0];
                  2'd1: if (MAIN_PU) mem_addr[15:0] <= v;
                  2'd2: if (MAIN_PU) mem_addr[31:16] <= v;
            endcase
      endtask

      reg [3:0] ST6_reg = 0;
      reg ST6_wr_reg = 0;
      reg [15:0] ST6_data;
      
      reg [3:0] ST5_cond = 0;
      reg [15:0] ST5_waddr = 0;
      reg [4:0] ST5_opcode = 0;
      reg ST5_add_carry = 0;
      reg ST5_inv1 = 0 /* synthesis keep */;
      reg ST5_inv2 = 0 /* synthesis keep */;
      wire [15:0] ST5_arg1 = ST5_inv1 ? ~ST5_p1 : ST5_p1;
      wire [15:0] ST5_arg2 = ST5_inv2 ? ~ST5_p2 : ST5_p2;
      reg [15:0] st5_res;
      reg [5:0] rgb_r;
      reg [6:0] rgb_g;
      reg [5:0] rgb_b;
      reg st5_carry;
      
      reg [15:0] ST4_waddr = '0;
      reg [15:0] st4_rb;
      reg [15:0] st4_rd;
      reg [15:0] st4_p2;
      reg ST5_mov_arg1 = 0;
      wire [15:0] st5_mov_res = ST5_mov_arg1 ? ST5_arg1 : ST5_arg2;
      assign peripheral_out = st5_mov_res[7:0];
      
      reg ST6_mul = 0, ST6_smul = 0, ST6_wmul = 0, ST7_wmul = 0;
      
      wire [33:0] mult_res_wire;
      wire [15:0] shift_res_wire;
      generate
            if (MUL_ENABLED) begin : MUL_BLOCK
                  MULT mult(
                        .dataa({ST6_smul ? ST6_p1[15] : 1'b0, ST6_p1}),
                        .datab({ST6_smul ? ST6_p2[15] : 1'b0, ST6_p2}),
                        .result(mult_res_wire)
                  );
            end else assign mult_res_wire = '0;
            if (SHIFT_ENABLED) begin : SHIFT_BLOCK
                  SHIFT shift(
                        .data(ST5_p1),
                        .direction(ST5_opcode[0]),
                        .distance(ST5_p2[3:0]),
                        .result(shift_res_wire)
                  );
            end else assign shift_res_wire = '0;
      endgenerate
      
      initial st5_cond_met = 1;
      always @(*) begin
            case (ST5_cond)
                  4'd0: st5_cond_met = 1'b1;
                  4'd1: st5_cond_met = flagZ;
                  4'd2: st5_cond_met = ~flagZ;
                  4'd3: st5_cond_met = flagC;
                  4'd4: st5_cond_met = ~flagC;
                  4'd5: st5_cond_met = flagN;
                  4'd6: st5_cond_met = ~flagN;
                  4'd7: st5_cond_met = flagV;
                  4'd8: st5_cond_met = ~flagV;
                  4'd9: st5_cond_met = flagC & ~flagZ;
                  4'd10: st5_cond_met = ~flagC | flagZ;
                  4'd11: st5_cond_met = flagN == flagV;
                  4'd12: st5_cond_met = flagN != flagV;
                  4'd13: st5_cond_met = ~flagZ && flagN == flagV;
                  4'd14: st5_cond_met = flagZ || flagN != flagV;
                  4'd15: st5_cond_met = 1'b0;
            endcase
      end
      
      always @(posedge clock) begin
            last_enabled <= enabled;
            if (last_enabled & ST4_rd_cache) ST5_p2 <= cache_rdata;
            if (enabled) begin
            
                  // mul, shift
                  if (ST7_wmul) mult_res[15:0] <= mult_res_wire[15:0] + mult_res[31:16];
                  else if (ST6_mul) mult_res <= mult_res_wire[31:0];
                  else if (st5_cond_met && ST5_opcode[4:1] == SHL[4:1]) mult_res[15:0] <= shift_res_wire;
            
                  // Stage 6
                  if (ST6_wr_reg) set_reg(ST6_reg, ST6_data);
                  ST7_wmul <= ST6_wmul;
            
                  // Stage 5
                  ST6_p1 <= ST6_wmul ? ST6_p1 : ST5_p1;
                  ST6_p2 <= ST6_wmul ? mult_res[31:16] : ST5_arg2;
                  ST6_mul <= st5_cond_met && ST5_opcode == MUL;
                  ST6_smul <= st5_cond_met && ST5_opcode == MUL && ST5_reg[0];
                  ST6_wmul <= st5_cond_met && ST5_opcode == MUL && ST5_reg[1];
                  casez (ST5_opcode)
                        AND,TST: {st5_carry, st5_res} = {1'b0, ST5_arg1 & ST5_arg2};
                        OR: {st5_carry, st5_res} = {1'b0, ST5_arg1 | ST5_arg2};
                        XOR: {st5_carry, st5_res} = {1'b0, ST5_arg1 ^ ST5_arg2};
                        RGBSHR: {st5_carry, st5_res} = {2'b0, st5_mov_res[15:12], 1'b0, st5_mov_res[10:6], 1'b0, st5_mov_res[4:1]};
                        RGBADD: begin
                              st5_carry = 1'b0;
                              rgb_b = ST5_arg1[4:0] + ST5_arg2[4:0];
                              rgb_g = ST5_arg1[10:5] + ST5_arg2[10:5];
                              rgb_r = ST5_arg1[15:11] + ST5_arg2[15:11];
                              st5_res[4:0] = rgb_b[5] ? '1 : rgb_b[4:0];
                              st5_res[10:5] = rgb_g[6] ? '1 : rgb_g[5:0];
                              st5_res[15:11] = rgb_r[5] ? '1 : rgb_r[4:0];
                        end
                        5'b11???: {st5_carry, st5_res} = ST5_arg1 + ST5_arg2 + ST5_add_carry;
                        default: begin st5_res = st5_mov_res; st5_carry = 1'b0; end
                  endcase
                  cache_wdata <= st5_res;
                  ST6_wr_reg <= st5_cond_met & ST5_wr_reg;
                  ST6_data <= st5_res;
                  ST6_reg <= ST5_reg;
                  if (st5_cond_met) begin
                        if (ST5_set_flags) begin
                              if (ST5_peripheral_operation) begin
                                    flagN <= ~ST5_peripheral_success;
                                    flagZ <= 0;
                                    flagV <= 0;
                                    flagC <= 0;
                              end else begin
                                    flagN <= st5_res[15];
                                    flagZ <= ~|st5_res;
                                    flagV <= st5_res[15] ^ ST5_arg1[15] ^ ST5_arg2[15] ^ st5_carry;
                                    flagC <= st5_carry;
                              end
                        end
                        if (ST5_wr_sreg) sreg_out(ST5_reg, st5_mov_res /*ST5_arg2*/);
                  end
                  
                  // Stage 4
                  ST5_cond <= ST4_command[31:28];
                  ST5_opcode <= ST4_command[27:23];
                  ST5_add_carry <= ST4_command[25] ? st5_carry : |ST4_command[24:23];
                  ST5_mov_arg1 <= ST4_mov_arg1;
                  
                  if (ST4_bsreg) st4_rb = sreg_in(ST4_sreg_num);
                  else if (st5_cond_met && ST4_res_to_p1) st4_rb = st5_res;
                  else if (ST6_wr_reg && ST4_b == ST6_reg) st4_rb = ST6_data;
                  else st4_rb = ST4_b[3] ? hi_rb : lo_regs[ST4_b[2:0]];
                  
                  if (ST6_wr_reg && ST4_d == ST6_reg) st4_rd = ST6_data;
                  else st4_rd = ST4_d[3] ? hi_rd : lo_regs[ST4_d[2:0]];
                  
                  ST5_p1 <= st4_rb;
                  ST5_inv1 <= ST4_inv1;
                  ST5_inv2 <= ST4_inv2;
                  
                  casez (ST4_p2type)
                        2'b00: st4_p2 = {8'b0, peripheral_in};
                        2'b01: st4_p2 = st4_rd;
                        2'b10: st4_p2 = sreg_in(ST4_sreg_num);
                        2'b11: st4_p2 = ST4_const;
                  endcase                  
                  if (~ST4_rd_cache) ST5_p2 <= st4_p2;
                  
                  if (MAIN_PU) begin
                        // Stage 5
                        if (st5_cond_met && ST5_call && ~ST5_wr_sreg) mem_addr <= ip_for_return;
                        cache_waddr <= ST5_waddr;
                        // Stage 4
                        ST5_waddr <= ST4_waddr;
                        // Stage 3
                        ST4_waddr <= ST3_reg_r + ST3_addr_offset;
                        // Stage 2
                        if (st5_cond_met && (ST5_wr_reg && ST5_reg == st2_r))
                              ST3_reg_r <= st5_res;
                        else if (ST6_wr_reg && ST6_reg == st2_r)
                              ST3_reg_r <= ST6_data;
                        else if (~st2_r[3])
                              ST3_reg_r <= lo_regs[st2_r[2:0]];
                        else
                              ST3_reg_r <= hi_regs_out[st2_r[2:0]];
                  end else ST3_reg_r <= lo_regs[st2_r[2:0]];
                  
            end
      end

endmodule
