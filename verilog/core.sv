`include "bus_interfaces.sv"

module core(
            input wire reset,
            input wire clock,
            input wire [15:0] time_ms4,
            input wire [15:0] time_clock,
            input wire special_key,
            output wire [3:0] LED,
            mem_interface mem_bus,
            //mem_interface.master command_mem_bus,
            peripheral_interface.master peripheral_bus
      );
      localparam PU_COUNT = 4;
      
      // Command cache
      wire [20:0] command_addr;
      wire [31:0] next_command;
      wire command_ready;
      command_cache c_cache(
            .clock(clock),
            .reset(reset),
            //.mem_bus(command_mem_bus),
            .cache_to_mem_bus(mem_bus),
            .command_ready(command_ready),
            .command_addr(command_addr),
            .next_command(next_command)
      );
      
      wire sdram_is_running;
      wire sdram_start_operation;
      wire sdram_wren;
      wire [21:0] sdram_mem_addr;
      wire [15:0] p1;
      wire [15:0] p2;
      
      wire core_cache_ren, core_cache_wen;
      reg [PU_COUNT-1:0] cache_wen;
      wire [PU_COUNT-1:0][15:0] core_cache_rdata;
      wire [PU_COUNT-1:0][15:0] core_cache_wdata;
      wire [15:0] core_cache_raddr;
      wire [15:0] core_cache_waddr;
      wire [1:0] parallel_mode;
      
      wire ST5_wr_reg;
      wire ST5_wr_sreg;
      wire ST4_inv1;
      wire ST4_inv2;
      wire [3:0] ST5_reg;
      wire ST5_set_flags;
      wire [31:0] ST5_ret_addr;
      wire ST4_rd_cache;
      wire ST5_call;
      wire [6:0] ST3_addr_offset;
      wire [3:0] ST4_b;
      wire [3:0] ST4_d;
      wire [3:0] ST4_sreg_num;
      wire [1:0] ST4_p2type;
      wire [15:0] ST4_const;
      wire ST4_bsreg;
      wire [31:0] ST4_command;
      wire [31:0] ST3_command;
      wire [3:0] st2_r;
      wire [31:0] ip_for_return;
      wire st5_cond_met;
      wire ST5_peripheral_operation;
      wire ST5_peripheral_success;
      wire ST4_mov_arg1;
      wire ST4_res_to_p1;

      CU control_unit(
            // external interface
            .reset(reset),
            .clock(clock),
            .enabled(command_ready),
            .command_addr(command_addr),
            .next_command(next_command),
            .cache_ren(core_cache_ren),
            .cache_wen(core_cache_wen),
            .sdram_start_operation(sdram_start_operation),
            .sdram_wren(sdram_wren),
            .parallel_mode(parallel_mode),
            
            .peripheral_address(peripheral_bus.address),
            .peripheral_read_request(peripheral_bus.read_request),
            .peripheral_write_request(peripheral_bus.write_request),
            .peripheral_read_ready(peripheral_bus.read_ready),
            .peripheral_write_ready(peripheral_bus.write_ready),
            
            // interface to proccess unit
            .ST3_command(ST3_command),
            .ST5_ret_addr(ST5_ret_addr),
            .ST5_wr_reg(ST5_wr_reg),
            .ST5_wr_sreg(ST5_wr_sreg),
            .ST5_reg(ST5_reg),
            .ST5_set_flags(ST5_set_flags),
            .ST5_call(ST5_call),
            .ST4_rd_cache(ST4_rd_cache),
            .ST3_addr_offset(ST3_addr_offset),
            .ST4_b(ST4_b),
            .ST4_d(ST4_d),
            .ST4_sreg_num(ST4_sreg_num),
            .ST4_bsreg(ST4_bsreg),
            .ST4_p2type(ST4_p2type),
            .ST4_inv1(ST4_inv1),
            .ST4_inv2(ST4_inv2),
            .ST4_command(ST4_command),
            .ST4_const(ST4_const),
            .ST4_mov_arg1(ST4_mov_arg1),
            .ST4_res_to_p1(ST4_res_to_p1),
            .st2_r(st2_r),
            .ip_for_return(ip_for_return),
            .st5_cond_met(st5_cond_met),
            .ST5_peripheral_operation(ST5_peripheral_operation),
            .ST5_peripheral_success(ST5_peripheral_success),
            .sdram_mem_addr(sdram_mem_addr)
      );
      
      reg [7:0][15:0] hi_regs;
      genvar pu_index;
      generate
            for (pu_index = 0; pu_index < PU_COUNT; pu_index = pu_index + 1) begin : PU_GENERATE
                  wire [7:0][15:0] hi_regs_out;
                  wire [15:0] ST3_reg_r;
                  wire [15:0] cache_waddr;
                  wire [15:0] local_time_ms4;
                  wire [15:0] local_time_clock;
                  wire [3:0] local_LED;
                  wire [15:0] local_p1;
                  wire [15:0] local_p2;
                  wire [31:0] local_mem_addr;
                  wire [7:0] local_peripheral_in;
                  wire [7:0] local_peripheral_out;
                  wire local_st5_cond_met;
                  wire local_ST5_peripheral_operation;
                  wire local_ST5_peripheral_success;
                  always @(posedge clock) begin
                        cache_wen[pu_index] <= core_cache_wen && local_st5_cond_met && (pu_index == 0 || parallel_mode[0]);
                  end
                  if (pu_index == 0) begin
                        always @(posedge clock) begin
                              hi_regs <= hi_regs_out;
                        end
                        assign core_cache_raddr = ST3_reg_r + ST3_command[6:0];
                        assign core_cache_waddr = cache_waddr;
                        assign local_time_ms4 = time_ms4;
                        assign local_time_clock = time_clock;
                        assign LED = local_LED;
                        assign p1 = local_p1;
                        assign p2 = local_p2;
                        assign sdram_mem_addr = local_mem_addr[21:0];
                        assign local_peripheral_in = peripheral_bus.data_read;
                        assign peripheral_bus.data_write = local_peripheral_out;
                        assign st5_cond_met = local_st5_cond_met;
                        assign local_ST5_peripheral_operation = ST5_peripheral_operation;
                        assign local_ST5_peripheral_success = ST5_peripheral_success;
                  end else begin
                        assign local_time_ms4 = '0;
                        assign local_time_clock = '0;
                        assign local_peripheral_in = '0;
                        assign local_ST5_peripheral_operation = 0;
                        assign local_ST5_peripheral_success = 0;
                  end
                  PU #(pu_index, 1, 1) processing_unit(
                        .clock(clock),
                        .enabled(command_ready),
                        .hi_rb(pu_index == 0 ? hi_regs_out[ST4_b[2:0]] : hi_regs[ST4_b[2:0]]),
                        .hi_rd(pu_index == 0 ? hi_regs_out[ST4_d[2:0]] : hi_regs[ST4_d[2:0]]),
                        .hi_regs_out(hi_regs_out),
                        
                        .cache_waddr(cache_waddr),
                        .cache_rdata(parallel_mode[1] ? core_cache_rdata[pu_index] : core_cache_rdata[0]),
                        .cache_wdata(core_cache_wdata[pu_index]),
                        
                        // control wires
                        .ST5_wr_reg(ST5_wr_reg),
                        .ST5_wr_sreg(ST5_wr_sreg),
                        .ST5_reg(ST5_reg),
                        .ST5_set_flags(ST5_set_flags),
                        .ST4_rd_cache(ST4_rd_cache),
                        .ST5_call(ST5_call),
                        .ST3_addr_offset(ST3_addr_offset),
                        .ST4_b(ST4_b),
                        .ST4_d(ST4_d),
                        .ST4_sreg_num(ST4_sreg_num),
                        .ST4_p2type(ST4_p2type),
                        .ST4_bsreg(ST4_bsreg),
                        .ST4_inv1(ST4_inv1),
                        .ST4_inv2(ST4_inv2),
                        .ST4_command(ST4_command),
                        .ST4_const(ST4_const),
                        .ST4_mov_arg1(ST4_mov_arg1),
                        .ST4_res_to_p1(ST4_res_to_p1),
                        .st2_r(st2_r),
                  
                        // output
                        .ST5_p1(local_p1),
                        .ST5_p2(local_p2),
                        .ST3_reg_r(ST3_reg_r),
                        .st5_cond_met(local_st5_cond_met),
                  
                        // special in
                        .special_key(special_key),
                        .sdram_is_running(sdram_is_running),
                        .time_ms4(local_time_ms4),
                        .time_clock(local_time_clock),
                        .ip_for_return(ip_for_return),
                        .peripheral_in(local_peripheral_in),
                        .ST5_peripheral_operation(local_ST5_peripheral_operation),
                        .ST5_peripheral_success(local_ST5_peripheral_success),
                  
                        // special out
                        .LED(local_LED),
                        .mem_addr(local_mem_addr),
                        .peripheral_out(local_peripheral_out)
                  );
            end
      endgenerate
      
      // Cache
      wire cache_sdram_en;
      wire [3:0] cache_sdram_wen;
      wire [15:2] cache_sdram_addr;
      wire [3:0][15:0] cache_sdram_rdata;
      wire [3:0][15:0] cache_sdram_wdata;
      
      cache data_cache(
            .clock(clock),
            
            .core_ren(core_cache_ren),
            .core_wen(cache_wen),
            .core_raddr(core_cache_raddr),
            .core_waddr(core_cache_waddr),
            .core_wdata(core_cache_wdata),
            .core_rdata(core_cache_rdata),

            .sdram_en(cache_sdram_en),
            .sdram_wen(cache_sdram_wen),
            .sdram_addr(cache_sdram_addr),
            .sdram_rdata(cache_sdram_rdata),
            .sdram_wdata(cache_sdram_wdata)
      );
      
      reg [15:0] sdram_new_cache_addr;
      reg [15:0] sdram_new_count;
      always @(posedge clock) begin
            sdram_new_cache_addr <= p1;
            sdram_new_count <= p2;
      end
      memory_to_cache_connector sdram_connector(
            .clock(clock),
            .reset(reset),
            .mem_bus(mem_bus),
            
            .cache_en(cache_sdram_en),
            .cache_wen(cache_sdram_wen),
            .cache_addr(cache_sdram_addr),
            .cache_rdata(cache_sdram_rdata),
            .cache_wdata(cache_sdram_wdata),
            
            .is_running(sdram_is_running),
            .start_operation(sdram_start_operation),
            .new_wren(sdram_wren),
            .new_mem_addr(sdram_mem_addr),
            .new_cache_addr(sdram_new_cache_addr),
            .new_count(sdram_new_count)
      );
      
endmodule
