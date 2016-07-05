`include "opcodes.sv"

module CU(
            // external interface
            input wire reset,
            input wire clock,
            input wire enabled,
            output wire [20:0] command_addr,
            input wire [31:0] next_command,
            
            output wire cache_ren,
            output reg cache_wen,
            output reg sdram_start_operation,
            output reg sdram_wren,
            output reg [1:0] parallel_mode,
            
            output reg [2:0] peripheral_address,
            output wire peripheral_read_request,
            output wire peripheral_write_request,
            input wire peripheral_read_ready,
            input wire peripheral_write_ready,
            
            // interface to proccess unit
            output reg ST5_wr_reg,
            output reg ST5_wr_sreg,
            output reg [3:0] ST5_reg,
            output reg ST5_set_flags,
            output wire ST5_peripheral_operation,
            output wire ST5_peripheral_success,
            output reg ST4_rd_cache,
            output reg ST4_mov_arg1,
            output reg ST5_call,
            output reg [6:0] ST3_addr_offset,
            output reg [3:0] ST4_b,
            output reg [3:0] ST4_d,
            output reg [3:0] ST4_sreg_num,
            output reg [1:0] ST4_p2type,
            output reg ST4_bsreg,
            output reg ST4_inv1,
            output reg ST4_inv2,
            output reg [15:0] ST4_const,
            output reg [31:0] ST4_command,
            output wire [3:0] st2_r,
            output reg [31:0] ST3_command,
            output wire [31:0] ip_for_return,
            input wire [21:0] sdram_mem_addr,
            input wire [31:0] ST5_ret_addr,
            input wire st5_cond_met,
            output reg ST4_res_to_p1
      );
      
      initial peripheral_address = 3'b0;
      initial parallel_mode = 2'b11;
      initial ST5_call = 0;
      initial ST5_wr_reg = 0;
      initial sdram_start_operation = 0;
      
      reg [20:0] ip = '1;
      reg [20:0] next_ip;
      wire [20:0] ip_plus_1 = ip + 1'b1;
      assign command_addr = next_ip;
      assign ip_for_return = {10'b0, ip_plus_1, 1'b0};
      
      // Stage 1 -> Stage 2
      reg [31:0] ST2_command = 0;
      assign st2_r = ST2_command[11:8];
      
      // Stage 2 -> Stage 3
      initial ST3_command = 0;
      initial ST4_command = 0;
      reg [15:0] ST3_reg_r;
      reg [15:0] ST3_const;
      reg [3:0] ST3_reg_num;
      reg [1:0] ST3_p2type;
      reg ST3_rd_cache = 0;
      reg ST3_rd_peripheral = 0;
      reg ST3_mov_arg1;

      // Stage 4 -> Stage 5
      reg [20:0] ST5_ip_plus_const = '0;
      reg ST5_jmp = 0, ST5_jmp_ret = 0, ST5_wr_cache = 0, ST5_wr_peripheral = 0, ST4_wr_peripheral = 0;
      reg ST5_rw = 0, ST5_rw_write = 0, ST5_rd_peripheral = 0, ST5_rd_peripheral_success = 0;
      //reg [31:0] ST5_command = 0;
      
      // Temporary variables
      reg [4:0] st2_opcode;
      reg [3:0] st2_a;
      reg st2_mov;
      
      reg [4:0] st3_opcode;
      reg st3_bsreg;
      reg [3:0] st3_b, st3_b2;
      
      reg [4:0] st4_opcode;
      reg st4_jump, st4_mov, st4_jmp_reg, st4_jmp_ret, st4_inv1, st4_inv2;
      reg st4_wr_reg;
      
      reg drop_line = 0;

      // Assigments
      assign cache_ren = ST3_rd_cache;
      assign peripheral_read_request = ST3_rd_peripheral;
      assign peripheral_write_request = ST4_wr_peripheral;
      assign ST5_peripheral_operation = ST5_wr_peripheral | ST5_rd_peripheral;
      assign ST5_peripheral_success = (ST5_rd_peripheral & ST5_rd_peripheral_success) | (ST5_wr_peripheral & peripheral_write_ready);
      assign cache_wen = ST5_wr_cache;
      
      always @(*) begin
            if (ST5_jmp & st5_cond_met) begin
                  if (ST5_jmp_ret) next_ip = sdram_mem_addr[21:1];
                  else next_ip = ST5_ip_plus_const;
            end else next_ip = ip_plus_1;
      end

      always @(posedge clock) begin
            if (reset) begin
                  ip <= '1;
                  ST2_command <= 0;
                  ST3_command <= 0;
                  ST3_rd_peripheral <= 0;
                  ST4_command <= 0;
                  //ST5_command <= 0;
                  ST5_jmp <= 0;
                  ST5_jmp_ret <= 0;
                  ST5_call <= 0;
                  ST5_wr_reg <= 0;
                  ST5_wr_sreg <= 0;
                  ST4_wr_peripheral <= 0;
                  ST5_wr_peripheral <= 0;
                  ST5_set_flags <= 0;
                  ST5_wr_cache <= 0;
                  sdram_start_operation <= 0;
                  peripheral_address <= '0;
                  ST5_ip_plus_const <= '0;
                  drop_line = 0;
            end else if (enabled) begin
                  // Stage 5
                  sdram_wren <= ST5_rw_write;
                  sdram_start_operation <= ST5_rw && st5_cond_met;
                  
                  // Stage 4
                  //ST5_command <= ST4_command;
                  st4_opcode = ST4_command[27:23];
                  st4_jump = st4_opcode == JUMP || st4_opcode == DJUMP;
                  st4_mov = st4_opcode == MOV;
                  ST5_jmp <= st4_jump;
                  ST5_jmp_ret <= st4_jump && ~|ST4_command[22:21];
                  ST5_call <= st4_jump && &ST4_command[22:21];
                  ST5_set_flags <= st4_opcode[4] & ST4_command[22];
                  ST5_reg <= ST4_command[19:16];
                  ST5_wr_peripheral <= ST4_wr_peripheral;
                  if (st4_opcode[4] & st4_opcode[2:0] != 3'b011 & |ST4_command[21:20]) begin
                        if (st4_mov) begin
                              ST5_wr_sreg <= ST4_command[13:12] == 2'd1;
                              st4_wr_reg = ~ST4_command[12];
                        end else begin
                              st4_wr_reg = ST4_command[21:20] != 2'd3 || ~ST4_command[5];
                              ST5_wr_sreg <= !st4_wr_reg;
                        end
                  end else if (st4_opcode == CMOV) begin
                        st4_wr_reg = ~ST4_command[20];
                        ST5_wr_sreg <= ST4_command[20];
                  end else begin
                        st4_wr_reg = 0;
                        ST5_wr_sreg <= 0;
                  end
                  ST5_wr_reg <= st4_wr_reg;
                  /*if (st4_opcode == CMOV)
                        parallel_mode <= {~ST4_command[22], ST4_command[21]};
                  else if (st4_opcode == CCMOV)
                        parallel_mode <= 2'b10;
                  else
                        parallel_mode <= {1'b1, ST4_command[7]};*/
                  parallel_mode[0] <= ST4_command[7] && st4_opcode[4];
                  ST5_rd_peripheral <= st4_mov && ST4_command[13:12] == 2'b10;
                  ST5_rd_peripheral_success <= peripheral_read_ready;
                  ST5_wr_cache <= (st4_opcode[4] & ~|ST4_command[21:20]) | st4_opcode == CCMOV;
                  ST5_ip_plus_const <= ip + ST4_command[20:0] + 1'b1;
                  ST5_rw <= st4_opcode == RW;
                  ST5_rw_write <= ST4_command[22];
                  
                  // Stage 3
                  st3_opcode = ST3_command[27:23];
                  parallel_mode[1] <= ST3_command[7] && st3_opcode[4];
                  ST4_command <= ST3_command;
                  ST4_p2type <= ST3_p2type;
                  ST4_d <= ST3_reg_num;
                  ST4_rd_cache <= ST3_rd_cache;                  
                  st3_b = ST3_command[15:12];
                  ST4_mov_arg1 <= ST3_mov_arg1;
                  st4_inv1 = st3_opcode[4:3] == 2'b11 && st3_opcode[1:0] == 2'b01;
                  st4_inv2 = st3_opcode[4] & ((st3_opcode[3]&st3_opcode[1]) ^ (&ST3_command[21:20]&ST3_command[7]));
                  ST4_inv2 <= st4_inv2;
                  if (ST3_mov_arg1) begin
                        st3_bsreg = ST3_p2type == 2'b10;
                        st3_b2 = ST3_reg_num;
                        ST4_sreg_num = ST3_reg_num;
                        ST4_inv1 <= st4_inv2;
                  end else begin
                        st3_bsreg = ST3_command[21:20] == 2'b10 && ST3_command[9];
                        ST4_sreg_num <= st3_bsreg ? st3_b : ST3_reg_num;
                        st3_b2 = st3_b;
                        ST4_inv1 <= st4_inv1;
                  end
                  ST4_b <= st3_b2;
                  ST4_bsreg <= st3_bsreg;                  
                  ST4_const <= ST3_const;
                  ST4_res_to_p1 <= st4_wr_reg && st3_b2 == ST4_command[19:16];
                  ST4_wr_peripheral <= st3_opcode == MOV && ST3_command[13:12] == 2'd3;

                  // Stage 2
                  ST3_command <= ST2_command;
                  st2_a = ST2_command[19:16];
                  st2_opcode = ST2_command[27:23];
                  st2_mov = st2_opcode == MOV;
                  ST3_mov_arg1 <= st2_mov && ST2_command[21] == ST2_command[20] && ST2_command[13:12] != 2'b10;
                  if (st2_opcode == CCMOV)
                        ST3_addr_offset <= {4'b0, ST2_command[22:20]};
                  else
                        ST3_addr_offset <= ST2_command[6:0];
                  ST3_rd_peripheral <= st2_mov && ST2_command[13:12] == 2'b10;
                  ST3_reg_num <= &ST2_command[21:20] ? st2_r : st2_a;
                  if (st2_mov && ST2_command[13])
                        peripheral_address <= (&ST2_command[21:20] & ~ST2_command[12]) ? st2_r[2:0] : st2_a[2:0];
                  ST3_rd_cache <= |st2_opcode[4:3] && ST2_command[21:20] == 2'b01;
                  
                  if (st2_mov && ST2_command[13:12] == 2'b10) ST3_p2type <= 2'b00;
                  else if (|st2_opcode[4:3]) begin
                        case (ST2_command[21:20])
                              2'b00: ST3_p2type <= (st2_mov & ST2_command[12]) ? 2'b10 : 2'b01;
                              2'b10: begin
                                    ST3_p2type <= 2'b11;
                                    case (ST2_command[11:10])
                                          2'b00: ST3_const <= {7'b0, ST2_command[8:0]};
                                          2'b01: ST3_const <= {ST2_command[8:0], 7'b0};
                                          2'b10: ST3_const <= {7'h7f, ST2_command[8:0]};
                                          2'b11: ST3_const <= {ST2_command[8:0], 7'h7f};
                                    endcase
                              end
                              2'b11: ST3_p2type <= ST2_command[4] ? 2'b10 : 2'b01;
                        endcase
                  end else begin
                        ST3_p2type <= 2'b11;
                        ST3_const <= {st2_opcode == CCMOV ? ST2_command[19:12] : ST2_command[15:8], ST2_command[7:0]};
                  end

                  // Stage 1
                  ST2_command[31:28] <= next_command[31:28];
                  ST2_command[27:23] <= drop_line ? NOP : next_command[27:23];
                  ST2_command[22:0] <= next_command[22:0];
                  
                  /*if (ST5_jmp || (~drop_line && next_command[27:23] != DJUMP)) ip <= next_ip;
                  if (drop_line) begin
                        if (ST5_jmp) drop_line <= 0;
                  end else
                        drop_line <= next_command[27:23] == DJUMP;*/
                  
                  if (ST5_jmp) begin
                        ip <= next_ip;
                        drop_line <= 0;
                  end else if (~drop_line && next_command[27:23] != DJUMP)
                        ip <= next_ip;
                  else
                        drop_line <= 1;
                  
            end else
                  sdram_start_operation <= 0;
            
      end

endmodule
