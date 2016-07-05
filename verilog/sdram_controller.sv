`include "bus_interfaces.sv"
`include "hardware_interfaces.sv"

module sdram_controller (
                  input clock, input clock_shifted,
                  input reset,
                  mem_interface.slave data_bus,
                  output last_word,
                  peripheral_interface.slave peripheral_bus,
                  SDRAM_INTERFACE.OUT I_SDRAM
            );
	
      assign I_SDRAM.CLK = clock_shifted;
      assign I_SDRAM.LDQM = 0;
      assign I_SDRAM.UDQM = 0;
      
      reg [7:0] stats_idle = 0;
      reg [7:0] stats_work = 0;
      reg stats_send_idle = 0;
      reg [23:0] stats_counter = 0;
      reg [23:0] idle_counter = 0;
      reg [23:0] work_counter = 0;
      
      parameter STATS_ADDRESS = 3'b001;
      assign peripheral_bus.write_ready = 0;
      
      reg dq_out_mode = 0;
      reg [15:0] data_write;
      assign I_SDRAM.DQ = dq_out_mode ? data_write : 'z;
      
      parameter SIMULATION = 0;
      reg [4:0] state_hi = SIMULATION ? 5'b1 : '1;
      reg [8:0] state = 0;
      
      reg write_enable;
      reg jump5;
      reg burst = 0;
      reg [7:0] column_address;
      reg [7:0] initial_column_address;
      reg [2:0] delay = 0;
      reg [2:0] new_delay;
      reg new_ready;
      reg [10:0] refresh_counter = 0;
      assign data_bus.ready = data_bus.request & burst & new_ready;
      initial peripheral_bus.data_read = '0;
      assign last_word = state == 1;
      
      always @(posedge clock) begin
            if (reset) begin
                  stats_send_idle <= 0;
                  peripheral_bus.data_read <= '0;
            end else begin
                  peripheral_bus.read_ready <= peripheral_bus.address == STATS_ADDRESS;
                  if (peripheral_bus.address == STATS_ADDRESS && peripheral_bus.read_request) begin
                        stats_send_idle <= ~stats_send_idle;
                        peripheral_bus.data_read <= stats_send_idle ? stats_idle : stats_work;
                  end else peripheral_bus.data_read <= '0;
            end
            stats_counter <= stats_counter + 1'b1;
            if (&stats_counter) begin
                  stats_idle <= idle_counter[23:16];
                  stats_work <= work_counter[23:16];
                  idle_counter <= 0;
                  work_counter <= 0;
            end else begin
                  if (state == 0) idle_counter <= idle_counter + 1'b1;
                  if (data_bus.ready) work_counter <= work_counter + 1'b1;
            end
      end
      
      always @(posedge clock) begin
            if (reset) state_hi <= '1;
            else if (|state_hi) begin
                  dq_out_mode <= 0;
                  I_SDRAM.RAS <= 1;  // NOP
                  I_SDRAM.CAS <= 1;
                  I_SDRAM.WE <= 1;
                  state <= state - 1'b1;
                  if (state == 0) state_hi <= state_hi - 1'b1;
                  burst <= 0;
            end else begin
                  data_bus.data_read <= I_SDRAM.DQ;
                  data_write <= data_bus.data_write;
                  dq_out_mode <= write_enable && data_bus.ready;
                  if (state > 1 && state < 261) begin
                        if (delay < 4) new_delay = delay + 1'b1;
                  end else new_delay = 0;
                  delay <= new_delay;
                  if (~data_bus.request) burst <= 0;
                  if (state > 5) begin
                        if (state <= 261) begin
                              column_address <= column_address + 1'b1;
                              jump5 = &column_address || (~write_enable && data_bus.last4 && state < 261);
                        end else jump5 = 0;
                  end else jump5 = 0;
                  if (|refresh_counter) refresh_counter <= refresh_counter - 1'b1;
            
                  if (state == 468)
                        state <= 0;
                  else if (~data_bus.request && burst && state > 4 && state <= 262)
                        state <= 4;
                  else if (jump5)
                        state <= 5;
                  else if (state <= 1 && ~|refresh_counter)
                        state <= 476;
                  else if (|state)
                        state <= state - 1'b1;
                  new_ready <= write_enable ? (6 < state && state < 263 && ~jump5) : (1 < state && new_delay > 3);
                  if (state == 4 + write_enable || (~data_bus.request && burst && state > 4)) begin
                        I_SDRAM.RAS <= 1;  // burst terminate
                        I_SDRAM.CAS <= 1;
                        I_SDRAM.WE <= 0;
                        I_SDRAM.A[10] <= 1;
                  end else
                  if (state == 511 || state == 3) begin
                        I_SDRAM.RAS <= 0;  // precharge all
                        I_SDRAM.CAS <= 1;
                        I_SDRAM.WE <= 0;
                        I_SDRAM.A[10] <= 1;
                  end else
                  if (state == 506 || state == 495 || state == 476) begin
                        I_SDRAM.RAS <= 0;  // auto refresh
                        I_SDRAM.CAS <= 0;
                        I_SDRAM.WE <= 1;
                        refresh_counter <= 11'd2000;
                  end else
                  if (state == 484) begin
                        I_SDRAM.RAS <= 0;  // load mode register
                        I_SDRAM.CAS <= 0;
                        I_SDRAM.WE <= 0;
                        I_SDRAM.BA0 <= 0;
                        I_SDRAM.BA1 <= 0;
                        I_SDRAM.A <= 12'b000000110111; // L=3, BL=full
                  end else
                  if (state == 261) begin
                        I_SDRAM.RAS <= 1;
                        I_SDRAM.CAS <= 0;
                        I_SDRAM.WE <= ~write_enable; // read or write burst
                        I_SDRAM.A <= {4'b0, initial_column_address};
                  end else
                  if (|refresh_counter && data_bus.request && state==0) begin
                        I_SDRAM.RAS <= 0;   // handle new command
                        I_SDRAM.CAS <= 1;
                        I_SDRAM.WE <= 1;    // active
                        I_SDRAM.A <= data_bus.address[19:8];
                        I_SDRAM.BA0 <= data_bus.address[20];
                        I_SDRAM.BA1 <= data_bus.address[21];
                        column_address <= data_bus.address[7:0];
                        initial_column_address <= data_bus.address[7:0];
                        write_enable <= data_bus.write_enable;
                        state <= 9'd263;
                        burst <= 1;
                  end else begin
                        I_SDRAM.RAS <= 1;  // NOP
                        I_SDRAM.CAS <= 1;
                        I_SDRAM.WE <= 1;
                  end
            end
      end
      
endmodule
