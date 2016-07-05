module peripheral_to_cache_connector(
            input wire reset,
            input wire clock,
            peripheral_interface.master peripheral_bus,
            
            output wire cache_ren,
            output wire [1:0] cache_wen,
            output wire [14:0] cache_addr,
            input wire [31:0] cache_rdata,
            output wire [31:0] cache_wdata,
            
            output wire is_running,
            input wire start_operation,
            input wire new_wren,
            input wire [2:0] new_peripheral_addr,
            input wire [15:0] new_cache_addr,
            input wire [15:0] new_count
            output wire [15:0] res_count;
      );

      /*reg [21:0] mem_addr;
      reg [15:0] cache_addr;
      reg [15:0] count = 0;
      assign is_running = |count;
      
      always @(posedge clock)
      begin
            if (reset) count <= 0;
            else if (is_running) begin
                  // TODO
            end
      end*/

endmodule
