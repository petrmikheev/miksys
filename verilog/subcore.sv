module subcore(
                  input wire reset,
                  input wire clock,
                  input wire enabled,
                  
                  output wire [20:0] command_addr,
                  input wire [31:0] next_command,
                  
                  output reg cache_ren,
                  output reg [1:0] cache_wen,
                  output reg [14:0] cache_raddr,
                  output reg [14:0] cache_waddr,
                  input wire [31:0] cache_rdata,
                  output reg [31:0] cache_wdata,
                  
                  input wire special_key,
                  input wire [15:0] time_ms4,
                  input wire [15:0] time_clock,
                  output reg [3:0] LED,
                  peripheral_interface.master peripheral_bus,
                  
                  input wire sdram_is_running,
                  output reg sdram_start_operation,
                  output reg sdram_wren,
                  output reg [21:0] sdram_mem_addr,
                  output reg [15:0] sdram_cache_addr,
                  output reg [15:0] sdram_word_count
            );
      
      enum reg [4:0] {
            NOP = 5'h0,
            JUMP = 5'h1,
            CMOV = 5'h2,
            CCMOV = 5'h3,
            
            MUL = 5'he,
            RW = 5'hf,
            OR = 5'h10,
            XOR = 5'h11,
            AND = 5'h12,
            TST = 5'h13,
            MOV = 5'h14,
            WMOV = 5'h15,
            ADD = 5'h18,
            RSB = 5'h19,
            SUB = 5'h1a,
            CMP = 5'h1b,
            ADC = 5'h1c,
            RSC = 5'h1d,
            SBC = 5'h1e
      } OPCODE;
      
      reg [15:0][15:0] regs;
      function [31:0] reg32;
            input [3:0] n;
            reg32 = {regs[{n[3:1], 1'b1}], regs[n]};
      endfunction
      
      reg flagZ;
      reg flagN;
      reg flagC;
      reg flagV;
      
      initial LED = 4'b0;
      initial peripheral_bus.address = 3'b0;
      
      reg [20:0] ip = '1;
      reg [20:0] next_ip;
      wire [20:0] ip_plus_1 = ip + 1'b1;
      assign command_addr = next_ip;
      
      reg last_enabled = 0;
      
      reg [31:0] mult_res;
      
      function [31:0] sreg_in;
            input [3:0] addr;
            case (addr)
                  4'd0: sreg_in = {26'b0, sdram_is_running, special_key, flagC, flagV, flagZ, flagN};
                  4'd1: sreg_in = {time_clock, time_ms4};
                  4'd2: sreg_in = mult_res;
                  4'd3: sreg_in = {16'b0, mult_res[31:16]};
                  default: sreg_in = 32'b0;
            endcase
      endfunction
      task sreg_out;
            input [3:0] addr;
            input [31:0] v;
            case (addr)
                  4'd0: LED <= v[3:0];
            endcase
      endtask
      
      // Stage 1 -> Stage 2
      reg [31:0] ST2_command = 0;
      
      // Stage 2 -> Stage 3
      reg [31:0] ST3_command = 0;
      reg [15:0] ST3_reg_r;
      reg [3:0] ST3_reg_num;
      reg [3:0] ST3_sreg_num;
      reg [3:0] ST3_p2type;
      reg ST3_rd_cache = 0;
      reg ST3_rd_peripheral = 0;
      reg ST3_r5;
      
      // Stage 3 -> Stage 4
      reg [31:0] ST4_command = 0;
      reg [15:0] ST4_reg_r;
      reg [3:0] ST4_reg_num;
      reg [3:0] ST4_sreg_num;
      reg [3:0] ST4_p2type;
      reg ST4_raddr0, ST4_rd_cache;
      reg ST4_b5, ST4_b6, ST4_r5, ST4_rnl5, ST4_rnl6, ST4_rnh5, ST4_rnh6;

      // Stage 4 -> Stage 5
      reg [4:0] ST5_opcode = 0;
      reg [3:0] ST5_cond;
      reg [3:0] ST5_reg;
      reg ST5_jmp = 0, ST5_jmp_ret = 0, ST5_jmp_call = 0, ST5_jmp_reg = 0, ST5_wr_reg = 0, ST5_wr_cache = 0, ST5_wr_sreg = 0, ST5_wr_peripheral = 0;
      reg ST5_inv2 = 0;
      reg ST5_set_flags = 0, ST5_rw_write, ST5_rd_peripheral, ST5_rd_peripheral_success, ST5_add_carry, ST5_wide;
      reg [31:0] ST5_ra32;
      reg [15:0] ST5_p1;
      reg [31:0] ST5_p2;
      reg [15:0] ST5_waddr;
      reg [15:0] ST5_sp;
      
      // Stage 5 -> Stage 6
      reg ST6_wr_reg;
      reg ST6_wide;
      reg [3:0] ST6_reg;
      reg [31:0] ST6_data;
      
      // Temporary variables
      reg [4:0] st2_opcode;
      reg [3:0] st2_a;
      reg [3:0] st2_r;
      reg [15:0] st2_raddr;
      reg st2_jump, st2_mov;
      
      reg [3:0] st3_r;
      reg [3:0] st3_b;
      
      reg [4:0] st4_opcode;
      reg st4_inv1, st4_inv2, st4_jump, st4_mov, st4_cmov, st4_ccmov, st4_test;
      reg st4_jmp_call, st4_jmp_reg, st4_jmp_ret;
      reg [3:0] st4_a;
      reg [3:0] st4_b;
      reg [7:0] st4_c;
      reg [31:0] st4_p2;
      reg [15:0] st4_rb;
      reg [15:0] st4_d32_hi;
      reg [15:0] st4_d32_lo;
      reg [15:0] st4_reg_r;
      reg [3:0] st4_reg;
      reg st4_wr_reg;
      
      wire [15:0] ST5_arg1 = ST5_p1;
      wire [15:0] ST5_arg2 = ST5_inv2 ? ~ST5_p2[15:0] : ST5_p2[15:0];
      reg [15:0] st5_res;
      reg st5_carry;
      reg st5_cond_met;
      
      wire [31:0] mult_res_wire;
      MULT mult(
            .dataa(ST5_p1),
            .datab(ST5_p2[15:0]),
            .result(mult_res_wire)
      );
      
      // Assigments
      assign peripheral_bus.read_request = ST3_rd_peripheral;
      wire [15:0] ST3_raddr = ST3_reg_r + ST3_command[7:0];
      assign cache_ren = ST3_rd_cache;
      assign cache_raddr = ST3_raddr[15:1];
      
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
                  4'd14: st5_cond_met = flagZ && flagN != flagV;
                  4'd15: st5_cond_met = 1'b0;
            endcase
            if (ST5_jmp & st5_cond_met) begin
                  if (ST5_jmp_ret) next_ip = ST5_p2[20:0];
                  else if (ST5_jmp_reg) next_ip = ST5_ra32[21:1];
                  else next_ip = ip + ST5_p2[20:0];
            end else next_ip = ip_plus_1;
      end
      
      always @(posedge clock) begin
            last_enabled <= enabled;
            if (reset) begin
                  ip <= '1;
                  ST2_command <= 0;
                  ST3_command <= 0;
                  ST3_rd_peripheral <= 0;
                  ST4_command <= 0;
                  ST5_opcode <= 0;
                  ST5_jmp <= 0;
                  ST5_jmp_ret <= 0;
                  ST5_jmp_call <= 0;
                  ST5_jmp_reg <= 0;
                  ST5_wr_reg <= 0;
                  ST5_wr_sreg <= 0;
                  ST5_wr_peripheral <= 0;
                  ST5_set_flags <= 0;
                  ST6_wr_reg <= 0;
                  cache_wen <= 0;
                  sdram_start_operation <= 0;
            end else if (enabled) begin
            
                  // Stage 6
                  if (ST6_wr_reg & ~&ST6_reg) begin
                        if (ST6_wide) begin
                              regs[{ST6_reg[3:1], 1'b0}] <= ST6_data[15:0];
                              regs[{ST6_reg[3:1], 1'b1}] <= ST6_data[31:16];
                        end else
                              regs[ST6_reg] <= ST6_data[15:0];
                  end
            
                  // Stage 5
                  ST6_wide <= ST5_wide;
                  casez (ST5_opcode)
                        AND,TST: {st5_carry, st5_res} = {1'b0, ST5_arg1 & ST5_arg2};
                        OR: {st5_carry, st5_res} = {1'b0, ST5_arg1 | ST5_arg2};
                        XOR: {st5_carry, st5_res} = {1'b0, ST5_arg1 ^ ST5_arg2};
                        5'b11???: {st5_carry, st5_res} = ST5_arg1 + ST5_arg2 + ST5_add_carry;
                        JUMP: begin st5_carry = 1'b0; st5_res = ST5_sp; end
                        default: begin st5_res = ST5_arg2; st5_carry = 1'b0; end
                  endcase
                  cache_waddr <= ST5_waddr[15:1];
                  if (ST5_wr_cache & st5_cond_met)
                        if (ST5_wide) cache_wen <= 2'b11;
                        else cache_wen <= ST5_waddr[0] ? 2'b10 : 2'b01;
                  else cache_wen <= 2'b0;
                  if (ST5_jmp_call) cache_wdata <= ip_plus_1;
                  else if (ST5_wide) cache_wdata <= ST5_p2;
                  else cache_wdata <= {st5_res, st5_res};
                  ST6_wr_reg <= st5_cond_met & ST5_wr_reg;
                  ST6_data[31:16] <= ST5_p2[31:16];
                  ST6_data[15:0] <= st5_res;
                  ST6_reg <= ST5_reg;
                  peripheral_bus.write_request <= st5_cond_met & ST5_wr_peripheral;
                  peripheral_bus.data_write <= ST5_arg2[7:0];
                  if (st5_cond_met) begin
                        if (ST5_wr_reg & &ST5_reg) regs[15] <= st5_res;
                        if (ST5_opcode == MUL) mult_res <= mult_res_wire;
                        if (ST5_set_flags) begin
                              flagZ <= ~|st5_res;
                              flagC <= st5_carry;
                              flagV <= st5_res[15] ^ ST5_arg1[15] ^ ST5_arg2[15] ^ st5_carry;
                              if (ST5_rd_peripheral | ST5_wr_peripheral)
                                    flagN <= ~((ST5_rd_peripheral & ST5_rd_peripheral_success) | (ST5_wr_peripheral & peripheral_bus.write_ready));
                              else
                                    flagN <= st5_res[15];
                        end
                        if (ST5_wr_sreg) sreg_out(ST5_reg, ST5_p2);
                  end
                  sdram_wren <= ST5_rw_write;
                  sdram_mem_addr <= ST5_ra32[21:0];
                  sdram_cache_addr <= ST5_p1;
                  sdram_word_count <= ST5_arg2;
                  sdram_start_operation <= ST5_opcode == RW && st5_cond_met;
                  
                  // Stage 4
                  st4_opcode = ST4_command[27:23];
                  ST5_cond <= ST4_command[31:28];
                  ST5_opcode <= st4_opcode;
                  st4_inv1 = st4_opcode[4:3] == 2'b11 && st4_opcode[1:0] == 2'b01;
                  st4_inv2 = st4_opcode[4:3] == 2'b11 && st4_opcode[1];
                  ST5_inv2 <= st4_inv2 ^ (st4_opcode[4] & &ST4_command[21:20] & ST4_command[7]);
                  ST5_add_carry <= (st4_opcode[4:2] == 3'b111 ? st5_carry : (st4_inv1 | st4_inv2));
                  st4_jump = st4_opcode == JUMP;
                  st4_mov = st4_opcode[4:1] == 4'ha;
                  st4_cmov = st4_opcode == CMOV;
                  st4_ccmov = st4_opcode == CCMOV;
                  st4_test = st4_opcode[4] && st4_opcode[2:0] == 3'b011;
                  st4_jmp_reg = st4_jump & ~ST4_command[21];
                  st4_jmp_call = st4_jump & ST4_command[22];
                  st4_jmp_ret = st4_jump && ST4_command[21:20] == 2'b01;
                  ST5_jmp_reg <= st4_jmp_reg;
                  st4_a = ST4_command[19:16];
                  st4_reg = st4_jump ? 4'd15 : st4_a;
                  ST5_reg <= st4_reg;
                  st4_b = ST4_command[15:12];
                  
                  if (st5_cond_met && ST4_b5) st4_rb = st5_res;
                  else if (ST4_b6) st4_rb = ST6_data[15:0];
                  else st4_rb = regs[st4_b];
                  
                  if (st5_cond_met && ST4_rnl5) st4_d32_lo = st5_res;
                  else if (ST4_rnl6) st4_d32_lo = ST6_data[15:0];
                  else
                        st4_d32_lo = regs[ST4_reg_num];
                  if (st5_cond_met && ST4_rnh5) st4_d32_hi = st5_res;
                  else if (ST4_rnh6) st4_d32_hi = ST6_data[15:0];
                  else
                        st4_d32_hi = regs[{ST4_reg_num[3:1],1'b1}];
                  if (st5_cond_met && ST4_r5)
                        st4_reg_r = st5_res;
                  else
                        st4_reg_r = ST4_reg_r;
                  
                  ST5_ra32 <= {st4_d32_hi, st4_d32_lo};
                  ST5_sp <= ST5_jmp_ret ? regs[15] + 2'd2 : regs[15] - 2'd2;
                  ST5_p1 <= st4_inv1 ? ~st4_rb : st4_rb;
                  ST5_rw_write <= ST4_command[22];
                  st4_c = ST4_command[7:0];
                  ST5_wr_cache <= (st4_opcode[4] & ~|ST4_command[21:20]) | st4_jmp_call | st4_ccmov;
                  ST5_wide <= st4_opcode == WMOV || st4_jump;
                  if (st4_jmp_call) ST5_waddr <= regs[15] - 2'd2;
                  else if (st4_ccmov) ST5_waddr <= ST4_reg_r + ST4_command[22:20];
                  else ST5_waddr <= ST4_reg_r + st4_c;
                  ST5_rd_peripheral <= st4_mov && ST4_command[13:12] == 2'b10;
                  ST5_rd_peripheral_success <= peripheral_bus.read_ready;
                  casez (ST4_p2type)
                        4'b0000: st4_p2 = {24'b0, peripheral_bus.data_read};
                        4'b0001: st4_p2 = {st4_d32_hi, st4_d32_lo};
                        4'b0010: st4_p2 = {11'b0, ST4_command[20:0]};
                        4'b0011: st4_p2 = {16'b0, ST4_command[19:12], ST4_command[7:0]};
                        4'b01??: st4_p2 = last_enabled ?
                                    { cache_rdata[31:16], ST4_raddr0 ? cache_rdata[31:16] : cache_rdata[15:0] } : ST5_p2;
                        4'b1000: st4_p2 = {22'b0, ST4_command[9:0]};
                        4'b1001: st4_p2 = {16'b0, ST4_command[9:0], 6'b0};
                        4'b1010: st4_p2 = {16'hffff, 6'h3f, ST4_command[9:0]};
                        4'b1011: st4_p2 = {16'hffff, ST4_command[9:0], 6'h3f};
                        4'b1100: st4_p2 = {st4_d32_hi, st4_reg_r};
                        4'b1101: st4_p2 = sreg_in(ST4_sreg_num);
                        4'b1110: st4_p2 = {16'b0, ST4_reg_r << ST4_command[3:0]};
                        4'b1111: st4_p2 = {16'b0, ST4_reg_r >> ST4_command[3:0]};
                  endcase
                  ST5_p2 <= st4_p2;
                  ST5_jmp <= st4_jump;
                  ST5_set_flags <= st4_opcode[4] & ST4_command[22];
                  ST5_jmp_call <= st4_jmp_call;
                  ST5_jmp_ret <= st4_jmp_ret;
                  if (st4_opcode[4] & ~st4_test & |ST4_command[21:20]) begin
                        ST5_wr_sreg <= st4_mov && ST4_command[13:12] == 2'd1;
                        ST5_wr_peripheral <= st4_mov && ST4_command[13:12] == 2'd3;
                        st4_wr_reg = ~st4_mov || ~ST4_command[12];
                  end else if (st4_cmov) begin
                        st4_wr_reg = ST4_command[21:20] == 2'b0;
                        ST5_wr_sreg <= ST4_command[20];
                        ST5_wr_peripheral <= ST4_command[21];
                  end else begin
                        st4_wr_reg = st4_jmp_ret | st4_jmp_call;
                        ST5_wr_sreg <= 0;
                        ST5_wr_peripheral <= 0;
                  end
                  ST5_wr_reg <= st4_wr_reg;
                  
                  // Stage 3
                  ST4_command <= ST3_command;
                  ST4_p2type <= ST3_p2type;
                  ST4_reg_num <= ST3_reg_num;
                  ST4_sreg_num <= ST3_sreg_num;
                  st3_b = ST3_command[15:12];
                  ST4_b5 <= st4_wr_reg && (st3_b==st4_reg);
                  ST4_b6 <= st5_cond_met && ST5_wr_reg && (st3_b==ST5_reg);
                  st3_r = ST3_command[11:8];
                  ST4_r5 <= st4_wr_reg && (st3_r==st4_reg);
                  ST4_rnl5 <= st4_wr_reg && (ST3_reg_num==st4_reg);
                  ST4_rnl6 <= st5_cond_met && ST5_wr_reg && (ST3_reg_num==ST5_reg);
                  ST4_rnh5 <= st4_wr_reg && ({ST3_reg_num[3:1], 1'b1}==st4_reg);
                  ST4_rnh6 <= st5_cond_met && ST5_wr_reg && ({ST3_reg_num[3:1], 1'b1}==ST5_reg);
                  if (st5_cond_met && ST3_r5)
                        ST4_reg_r <= st5_res;
                  else
                        ST4_reg_r <= ST3_reg_r;
                  ST4_raddr0 <= ST3_raddr[0];
                  ST4_rd_cache <= ST3_rd_cache;

                  // Stage 2
                  ST3_command <= ST2_command;
                  st2_r = ST2_command[11:8];
                  st2_a = ST2_command[19:16];
                  ST3_r5 <= st4_wr_reg && (st2_r==st4_reg);
                  if (st5_cond_met && ST5_wr_reg && ST5_reg == st2_r) ST3_reg_r <= st5_res;
                  else if (ST6_wr_reg && ST6_reg == st2_r) ST3_reg_r <= ST6_data[15:0];
                  else
                        ST3_reg_r <= regs[st2_r];
                  st2_opcode = ST2_command[27:23];
                  st2_jump = st2_opcode == JUMP;
                  st2_mov = st2_opcode[4:1] == 4'ha;
                  ST3_rd_peripheral <= st2_mov && ST2_command[13:12] == 2'b10;
                  ST3_reg_num <= (~&ST2_command[21:20] || st2_opcode == RW) ? st2_a : st2_r;
                  ST3_sreg_num <= ~&ST2_command[21:20] ? st2_a : st2_r;
                  if (st2_mov && ST2_command[13])
                        peripheral_bus.address <= (&ST2_command[21:20] & ~ST2_command[12]) ? st2_r[2:0] : st2_a[2:0];
                  else if (st2_opcode == CMOV && ST2_command[21])
                        peripheral_bus.address <= st2_a[2:0];
                  ST3_rd_cache <= (st2_opcode==JUMP | |ST2_command[27:26]) && ST2_command[21:20] == 2'b01;
                  if (st2_mov && ST2_command[13:12] == 2'b10) ST3_p2type <= 4'b0000;
                  else if (|st2_opcode[4:3]) begin
                        case (ST2_command[21:20])
                              2'b00:begin
                                    if (st2_mov & ST2_command[12]) ST3_p2type <= 4'b1101;
                                    else ST3_p2type <= 4'b0001;
                              end
                              2'b01: ST3_p2type <= 4'b0100;
                              2'b10: ST3_p2type <= {2'b10, ST2_command[11:10]};
                              2'b11: ST3_p2type <= {2'b11, ST2_command[5:4]};
                        endcase
                  end else if (st2_opcode == CCMOV) ST3_p2type <= 4'b0011;
                  else if (st2_jump && ST2_command[21:20] == 2'b01) ST3_p2type <= 4'b0100;
                  else ST3_p2type <= 4'b0010;
                  
                  // Stage 1
                  ST2_command <= next_command;
                  ip <= next_ip;
                  
            end else begin
                  sdram_start_operation <= 0;
                  if (last_enabled & ST4_rd_cache)
                        ST5_p2 <= { cache_rdata[31:16], ST4_raddr0 ? cache_rdata[31:16] : cache_rdata[15:0] };
            end
            
      end
      
endmodule
