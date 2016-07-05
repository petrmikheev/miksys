module ps2_controller (
            input wire reset,
            input clock,
            slowIO_interface.slave io_bus,
            inout ps2_clock,
            inout ps2_data,
            output wire [7:0] debug
      );
      
      reg wr = 0;
      reg [3:0] state = 0;
      
      reg [11:0] data = 0;
      reg [3:0] clock_out = 0;
      reg [4:0] reset_counter = 0;
      assign ps2_clock = clock_out ? 1'b0 : 1'bz;
      assign ps2_data = (wr & ~data[0]) ? 1'b0 : 1'bz;
      
      assign io_bus.data_read = data[9:2];
      initial io_bus.read_odd = 0;
      initial io_bus.write_odd = 0;
      
      reg [9:0] counter = 10'd1;
      reg [9:0] sum_clock = 0;
      reg [9:0] sum_data = 0;
      reg avg_clock = 1;
      reg parity_read = 0;
      
      assign debug = {state, sum_data[9], avg_clock, ps2_data, ps2_clock};
      
      always @(posedge clock) begin
            if (reset) begin
                  clock_out <= 0;
                  io_bus.read_odd <= 0;
                  io_bus.write_odd <= 0;
                  wr <= 0;
                  data <= 0;
                  state <= 0;
                  counter <= 10'd1;
                  sum_clock <= 0;
                  sum_data <= 0;
                  avg_clock <= 1;
                  reset_counter <= 0;
            end else begin
            
                  counter <= counter + 1'b1;
                  if (counter == 0) begin
                        if (clock_out) clock_out <= clock_out - 1'b1;
                        sum_clock <= 0;
                        sum_data <= 0;
                        avg_clock <= sum_clock[9];
                        
                        if (io_bus.write_odd != io_bus.write_odd_request && state == 0 && ~wr && sum_clock[9]) begin
                              io_bus.write_odd <= ~io_bus.write_odd;
                              clock_out <= 4'd10;
                              wr <= 1;
                              data <= {1'b1, ~^io_bus.data_write, io_bus.data_write, 2'b01};
                              reset_counter <= 0;
                        end else if (avg_clock & ~sum_clock[9]) begin
                              data <= {sum_data[9], data[11:1]};
                              parity_read <= state == 0 ? 1'b0 : parity_read ^ sum_data[9];
                              if (state == 4'd10 && ~wr) begin
                                    if (parity_read) io_bus.read_odd <= ~io_bus.read_odd;
                                    state <= 0;
                              end else if (state == 4'd11 && wr) begin
                                    state <= 0;
                                    wr <= 0;
                              end else state <= state + 1'b1;
                              reset_counter <= 0;
                        end else begin
                              reset_counter <= reset_counter + 1'b1;
                              if (&reset_counter) begin
                                    state <= 0;
                                    wr <= 0;
                              end
                        end
                        
                  end else begin
                        if (ps2_clock === 1) sum_clock <= sum_clock + 1'b1;
                        if (ps2_data === 1) sum_data <= sum_data + 1'b1;
                  end
            end
      end
endmodule
