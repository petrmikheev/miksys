module command_cache(
            input wire clock,
            input wire reset,
            //mem_interface.master mem_bus,
            mem_interface.monitor cache_to_mem_bus,
            output wire command_ready,
            input wire [20:0] command_addr,
            output wor [31:0] next_command
      );

      reg startup_ready = 0;
      reg page_ready = 0;
      always @(posedge clock) begin
            if (reset) begin
                  startup_ready <= 0;
                  page_ready <= 0;
            end else begin
                  startup_ready <= command_addr[20:9] == '0;
                  page_ready <= command_addr[20:9] != '0;
            end
      end
      assign command_ready = 1; //|page_ready || startup_ready;
      wire [31:0] startup_next_command;
      assign next_command = startup_ready ? startup_next_command : '0;
      STARTUP rom(
            .clock(clock),
            .address(command_addr[8:0]),
            .q(startup_next_command)
      );
      
      wire [31:0] local_next_command;
      assign next_command = page_ready ? local_next_command : '0;
      COMMAND_RAM command_ram(
            .clock(clock),
            .rdaddress(command_addr[10:0]),
            .q(local_next_command),
            .data(cache_to_mem_bus.data_write),
            .wraddress(cache_to_mem_bus.address[11:0]),
            .wren(cache_to_mem_bus.address[21:12] == 10'h100 && cache_to_mem_bus.request && cache_to_mem_bus.write_enable)
      );
      
      /*parameter PAGE_COUNT = 8;
      reg [PAGE_COUNT-1:0][12:0] page_addr;
      reg [PAGE_COUNT-1:0] page_loaded = '0;
      wire [PAGE_COUNT-1:0] page_ready;*/
      
      /*assign mem_bus.request = ?;
      assign mem_bus.address = ?;
      page_addr <= ?;
      page_loaded <= ?;*/
      
      /*assign mem_bus.data_write = '0;
      assign mem_bus.write_enable = 0;
      assign mem_bus.last4 = 0;
      
      genvar p;
      generate
            for (p = 0; p < PAGE_COUNT; p = p + 1) begin : PAGE_GENERATE
                  wire choosed = page_addr[p] == command_addr[20:8];
                  wire [31:0] local_next_command;
                  assign page_ready[p] = page_loaded[p] && choosed;
                  assign next_command = page_ready[p] ? local_next_command : '0;
                  COMMAND_PAGE page(
                        .clock(clock),
                        .rdaddress(command_addr[7:0]),
                        .q(local_next_command),
                        .data(mem_bus.data_read),
                        .wraddress(mem_bus.address[8:0]),
                        .wren(choosed & mem_bus.ready)
                  );
            end
      endgenerate*/
endmodule
