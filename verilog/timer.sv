module timer(
            input wire clock,
            input wire reset,
            output reg [15:0] time_ms4,
            output reg [15:0] time_clock,
            output reg protected_reset
            );
      parameter SIMULATION = 0;
      initial protected_reset = SIMULATION ? 1'b0 : 1'b1;
      initial time_ms4 = '0;
      initial time_clock = '0;
      always @(posedge clock)
      begin
            if (reset) begin
                  protected_reset <= 1;
                  time_clock <= '0;
                  time_ms4 <= '0;
            end else if (time_clock < 16'd27000)
                  time_clock <= time_clock + 1'b1;
            else begin
                  time_clock <= 1'b1;
                  time_ms4 <= time_ms4 + 1'b1;
                  if (time_ms4[9]) protected_reset <= 0;
            end
      end
endmodule
