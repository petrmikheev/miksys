`include "bus_interfaces.sv"

module memory_to_cache_connector(
            input wire reset,
            input wire clock,
            mem_interface.master mem_bus,
            
            input wire cache_en,
            output reg [3:0] cache_wen,
            output reg [15:2] cache_addr,
            input wire [3:0][15:0] cache_rdata,
            output wire [3:0][15:0] cache_wdata,
            
            output wire is_running,
            input wire start_operation,
            input wire new_wren,
            input wire [21:0] new_mem_addr,
            input wire [15:0] new_cache_addr,
            input wire [15:0] new_count
      );

      initial cache_wen = 4'b0;
      reg [21:0] mem_addr;
      reg [15:0] count = 0;
      reg [3:0][15:0] buf0, buf1;
      reg [1:0] bi;
      reg [3:0] wen1;
      reg [1:0] write_wait_to_start = 0;
      reg read_wait_to_start;
      reg read_reload_buf;
      reg sdram_is_running = 0;
      assign mem_bus.request = sdram_is_running & ~|write_wait_to_start;
      assign mem_bus.address = mem_addr;
      assign mem_bus.data_write = buf0[bi];
      
      assign is_running = sdram_is_running | |wen1 | |cache_wen | start_operation;
      assign cache_wdata = buf0;
      
      always @(posedge clock)
      begin
            if (reset) begin
                  count <= 0;
                  cache_wen <= 4'b0;
                  wen1 <= 4'b0;
            end else if (start_operation) begin
                  cache_wen <= 4'b0;
                  mem_addr <= new_mem_addr;
                  cache_addr <= new_cache_addr[15:2];
                  bi <= new_cache_addr[1:0];
                  count <= new_count;
                  sdram_is_running <= 1;
                  mem_bus.last4 <= count <= 3'd5;
                  mem_bus.write_enable <= new_wren;
                  write_wait_to_start <= {new_wren, 1'b0};
                  read_wait_to_start <= 1'b1;
                  wen1 <= 4'b0;
                  read_reload_buf <= new_cache_addr[2];
            end else if (|write_wait_to_start) begin
                  if (cache_en & write_wait_to_start[1]) begin
                        write_wait_to_start <= 2'b1;
                        cache_addr <= cache_addr + 1'b1;
                  end else if (write_wait_to_start[0]) begin
                        write_wait_to_start <= 2'b0;
                        buf0 <= cache_rdata;
                  end
            end else begin
                  if (mem_bus.ready) begin
                        mem_addr <= mem_addr + 1'b1;
                        count <= count - 1'b1;
                        bi <= bi + 1'b1;
                        mem_bus.last4 <= count <= 3'd5;
                        sdram_is_running <= |count[15:1];
                  end
                  if (mem_bus.write_enable) begin
                        if (cache_en) buf1 <= cache_rdata;
                        if (mem_bus.ready & &bi) begin
                              buf0 <= buf1;
                              cache_addr <= cache_addr + 1'b1;
                        end
                  end else begin
                        if (mem_bus.ready) begin
                              buf1[bi] <= mem_bus.data_read;
                              read_wait_to_start <= 1'b0;
                              if (bi == 0 && ~read_wait_to_start) begin
                                    wen1 <= 4'b1;
                                    read_reload_buf <= ~read_reload_buf;
                              end else
                                    wen1[bi] <= 1'b1;
                        end
                        if (cache_addr[2] == read_reload_buf) begin
                              buf0 <= buf1;
                              cache_wen <= wen1;
                              if (~mem_bus.ready & cache_en) wen1 <= 1'b0;
                        end else if (cache_en) begin
                              buf0 <= buf1;
                              cache_wen <= wen1;
                              cache_addr <= cache_addr + 1'b1;
                        end
                        
                  end

            end
      end

endmodule
