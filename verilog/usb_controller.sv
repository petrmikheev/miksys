`include "bus_interfaces.sv"

module usb_controller(
            input wire reset,
            input wire clock,
            input wire [15:0] time_ms4,
            peripheral_interface.slave peripheral_bus,
            inout wire d_m,
            inout wire d_p
      );
      
      parameter SIMULATION = 0;
      
      parameter ADDR = 0;
      wire choosed = peripheral_bus.address == ADDR;
      initial peripheral_bus.write_ready = 0;
      initial peripheral_bus.read_ready = 0;
      initial peripheral_bus.data_read = '0;
      
      reg low_speed = 1;
      typedef enum reg [2:0] {HIZ=3'b000, SE0=3'b100, ST0=3'b101, ST1=3'b110} USB_STATE;
      wire [1:0] STK = low_speed ? 2'b10 : 2'b01;
      reg [2:0] usb_out = HIZ;
      assign d_p = usb_out[2] ? usb_out[1] : 1'bz;
      assign d_m = usb_out[2] ? usb_out[0] : 1'bz;
      wire [1:0] usb_in = {d_p===1 ? 1'b1 : 1'b0, d_m===1 ? 1'b1 : 1'b0};
      
      typedef enum reg [2:0] {IDLE=3'd0, PREPARE_DATA=3'd1, SENDING=3'd2, RECEIVING=3'd3,
                              DISCONNECTED=3'd4, RESET=3'd5} STATE;
      reg [2:0] state = DISCONNECTED;
      wire [6:0] clock_divider = low_speed ? 7'd71 : 7'd8;
      wire [6:0] clock_half_divider = low_speed ? 7'd15 : 7'd2; //7'd35 : 7'd3;
      wire [6:0] clock_fix_divider = low_speed ? 7'd87 : 7'd11; //7'd107 : 7'd12;
      reg [1:0] last_usb_in = '0;
      reg [1:0] last_usb_in_r = '0;
      reg [8:0] reset_counter_lo = '0;
      reg [11:0] reset_counter_hi = '0;
      reg fix_clock_counter = 0;
      reg [3:0] bit_state = '0;
      reg [6:0] stable_counter = '0;
      reg [6:0] clock_counter = '1;
      reg [7:0] current_byte = '0;
      reg [2:0] ones_counter = '0;
      reg rbit;
      
      reg odd_frame = 0;
      
      reg [6:0] buf_pointer = '0;
      reg [6:0] buf_pointer_prepare = '0;
      parameter BUF_SIZE = 64;
      reg [BUF_SIZE-1:0][7:0] buffer = '0;
      reg [7:0] type_in = '0;
      reg [7:0] type_out = '0;
      reg [1:0] hstate_in = '1; // 0 - size/SYNC, 1 - type, 2 - data, 3 - no data
      reg [1:0] hstate_out = '0; // 0 - type, 1 - data, 2 - crc, 3 - last_byte
      reg [6:0] block_size_in = '0;
      reg [6:0] block_size_out = '0;
      reg crc_error = 0;
      reg [15:0] crc = '0;
      reg [15:0] new_crc;
      reg [4:0] crc5 = '0;
      reg [4:0] new_crc5;
      reg prepare_type_out = 0;
      wire send_crc = type_out[1:0] == 2'b11;
      wire send_crc5 = type_out[1:0] == 2'b01;
      
      always @(posedge clock) begin
            if (reset) begin
                  peripheral_bus.write_ready <= 0;
                  peripheral_bus.read_ready <= 0;
                  peripheral_bus.data_read <= '0;
                  clock_counter <= '1;
                  usb_out <= HIZ;
                  state <= DISCONNECTED;
                  odd_frame <= 0;
                  reset_counter_lo <= '0;
                  fix_clock_counter <= 0;
                  hstate_in <= 2'd3;
            end else if (choosed) begin
                  peripheral_bus.write_ready <= peripheral_bus.write_request &&
                        (state == IDLE || (state == PREPARE_DATA &&
                        buf_pointer_prepare+peripheral_bus.write_ready+prepare_type_out <= block_size_out));
                  if (peripheral_bus.write_ready) begin
                        if (state == IDLE) begin
                              block_size_out <= peripheral_bus.data_write[6:0] - 1'b1;
                              prepare_type_out <= 0;
                              hstate_in <= 2'd3;
                              buf_pointer_prepare <= '0;
                              state <= peripheral_bus.data_write == 0 ? DISCONNECTED : PREPARE_DATA;
                              crc_error <= 0;
                              bit_state <= 4'd14;
                        end else if (state == PREPARE_DATA) begin
                              if (prepare_type_out == 0) begin
                                    type_out <= peripheral_bus.data_write;
                                    prepare_type_out <= 1;
                              end
                              buffer[buf_pointer_prepare] <= peripheral_bus.data_write;
                              buf_pointer_prepare <= buf_pointer_prepare + prepare_type_out;
                              if (buf_pointer_prepare + prepare_type_out >= block_size_out) state <= SENDING;
                        end
                  end
                  peripheral_bus.read_ready <= peripheral_bus.read_request && hstate_in != 2'd3 && state != RECEIVING;
                  if (peripheral_bus.read_request && hstate_in != 2'd3 && state != RECEIVING) begin
                        if (hstate_in == 2'd0) begin
                              hstate_in <= 2'd1;
                              peripheral_bus.data_read[7] <= crc_error;
                              peripheral_bus.data_read[6:0] <= block_size_in + 1'b1;
                        end else if (hstate_in == 2'd1) begin
                              peripheral_bus.data_read <= type_in;
                              hstate_in <= block_size_in != 0 ? 2'd2 : 2'd3;
                              buf_pointer_prepare <= '0;
                        end else begin
                              peripheral_bus.data_read <= buffer[buf_pointer_prepare];
                              buf_pointer_prepare <= buf_pointer_prepare + 1'b1;
                              if (buf_pointer_prepare + 1'b1 >= block_size_in) hstate_in <= 2'd3;
                        end
                  end
            end else begin
                  peripheral_bus.write_ready <= 0;
                  peripheral_bus.read_ready <= 0;
                  peripheral_bus.data_read <= '0;
            end
      
            last_usb_in <= usb_in;
            if (last_usb_in == usb_in)
                  stable_counter <= stable_counter + 1'b1;
            else
                  stable_counter <= '0;
            if (~reset) begin
                  if (state == DISCONNECTED) begin
                        if (|usb_in)
                              reset_counter_lo <= reset_counter_lo + 1'b1;
                        else
                              reset_counter_lo <= '0;
                        if (&reset_counter_lo) begin
                              state <= RESET;
                              reset_counter_hi <= SIMULATION ? 1'd1 : '1;
                              usb_out <= SE0;
                              low_speed <= usb_in[0];
                        end else usb_out <= HIZ;
                  end else
                  if (state == RESET) begin
                        reset_counter_lo <= reset_counter_lo + 1'b1;
                        if (reset_counter_hi == 0 && reset_counter_lo == 9'd367 && low_speed)
                              usb_out <= SE0;
                        if (&reset_counter_lo) begin
                              reset_counter_hi <= reset_counter_hi - 1'b1;
                              if (reset_counter_hi == 8) usb_out <= HIZ;
                              if (reset_counter_hi == 0) begin
                                    state <= IDLE;
                                    usb_out <= HIZ;
                                    hstate_in <= 2'd3;
                              end
                        end
                  end
                  if (state == IDLE && !(choosed && peripheral_bus.write_request)) begin
                        if (|usb_in)
                              reset_counter_lo <= '0;
                        else
                              reset_counter_lo <= reset_counter_lo + 1'b1;
                        if (&reset_counter_lo) begin
                              state <= DISCONNECTED;
                              hstate_in <= 2'd3;
                        end
                        else if (time_ms4[2] != odd_frame && (buf_pointer_prepare > 1 || hstate_in == 2'd3)) begin
                              odd_frame <= time_ms4[2];
                              state <= SENDING;
                              if (low_speed)
                                    bit_state <= 2'd3;
                              else begin
                                    type_out <= 8'ha5;
                                    block_size_out <= 2'd2;
                                    buffer[0] <= time_ms4[9:2];
                                    buffer[1] <= {5'b0, time_ms4[12:10]};
                                    bit_state <= 4'd14;
                              end
                        end else if (stable_counter >= clock_half_divider && last_usb_in === STK) begin
                              state <= RECEIVING;
                              ones_counter <= '0;
                              hstate_in <= 2'd0;
                              bit_state <= 4'd8;
                              clock_counter <= '0;
                              buf_pointer <= '0;
                        end
                  end else begin
                        if (fix_clock_counter) begin
                              fix_clock_counter <= 0;
                              clock_counter <= clock_fix_divider - stable_counter;
                        end if (clock_counter == 0)
                              clock_counter <= clock_divider;
                        else
                              clock_counter <= clock_counter - 1'b1;
                  end
                  if (clock_counter == 0 && (state == SENDING ||
                        (state == PREPARE_DATA && buf_pointer_prepare >= 4))) begin
                        // bitstate
                        // 12,13,14,[15] -> HIZ
                        // 4,5,6,7,8,9,11 -> send bit
                        // 2,3 -> SE0
                        // 1 -> HIZ, IDLE
                        if (buf_pointer > 0 && buf_pointer <= block_size_out) begin
                              new_crc = crc[0]^current_byte[0] ? {1'b1, crc[15:1]} : {1'b0, crc[15:1]^15'h2001};
                              new_crc5 = crc5[0]^current_byte[0] ? {1'b1, crc5[4:1]} : {1'b0, crc5[4:1]^4'h4};
                        end else begin
                              new_crc = crc;
                              new_crc5 = crc5;
                        end
                        if (^bit_state[3:2]) begin
                              if (ones_counter[2:1] == 3 || ~current_byte[0]) begin
                                    ones_counter <= '0;
                                    usb_out <= usb_in[1] ? ST0 : ST1;
                              end else ones_counter <= ones_counter + 1'b1;
                              if (ones_counter[2:1] != 3) begin
                                    if (hstate_out[0]) begin
                                          crc <= new_crc;
                                          crc5 <= new_crc5;
                                    end
                                    if (bit_state == 4) begin
                                          case (hstate_out)
                                                2'd0: begin
                                                      current_byte <= type_out;
                                                      hstate_out <= (block_size_out == 0 && ~send_crc) ? 2'd3 : 2'd1;
                                                      bit_state <= 4'd11;
                                                      crc <= '0;
                                                      crc5 <= '0;
                                                end
                                                2'd1: begin
                                                      if (send_crc) begin
                                                            if (buf_pointer == block_size_out) hstate_out <= 2'd2;
                                                      end else if (buf_pointer + 1'b1 == block_size_out)
                                                            hstate_out <= 2'd3;
                                                      current_byte <= buf_pointer == block_size_out ?
                                                            new_crc[7:0] : buffer[buf_pointer];
                                                      buf_pointer <= buf_pointer + 1'b1;
                                                      bit_state <= 4'd11;
                                                end
                                                2'd2: begin
                                                      current_byte <= crc[15:8];
                                                      bit_state <= 4'd11;
                                                      hstate_out <= 2'd3;
                                                end
                                                2'd3: bit_state <= 4'd3;
                                          endcase
                                    end else begin
                                          bit_state <= bit_state - 1'b1;
                                          if (bit_state == 9 && send_crc5 && buf_pointer[1])
                                                current_byte <= new_crc5;
                                          else current_byte <= {1'b0, current_byte[7:1]};
                                    end
                              end
                        end else begin
                              bit_state <= bit_state - 1'b1;
                              if (bit_state == 12) begin
                                    current_byte <= 8'h80;
                                    ones_counter <= '0;
                                    buf_pointer <= '0;
                                    hstate_out <= '0;
                              end else if (bit_state == 1) begin
                                    usb_out <= HIZ;
                                    state <= IDLE;
                                    reset_counter_lo <= '0;
                              end else if (bit_state == 3) usb_out <= SE0;
                        end
                  end
                  if (state == RECEIVING && clock_counter == 0) begin
                        reset_counter_lo <= '0;
                        last_usb_in_r <= usb_in;
                        rbit = bit_state[3] ? 1'b0 : last_usb_in_r == usb_in;
                        if (rbit)
                              ones_counter <= ones_counter + 1'b1;
                        else begin
                              ones_counter <= '0;
                              fix_clock_counter <= 1;
                        end
                        if (hstate_in[1] && ones_counter[2:1] != 3 && |usb_in)
                              crc <= crc[0]^rbit ? {1'b1, crc[15:1]} : {1'b0, crc[15:1]^15'h2001};
                        if (ones_counter[2:1] != 3 || usb_in == 2'b00) begin
                              current_byte <= {rbit, current_byte[7:1]};
                              if (bit_state > 0) begin
                                    bit_state <= bit_state - 1'b1;
                                    if (usb_in == 2'b00) begin
                                          hstate_in <= '0;
                                          if (type_in[2:0] == 3'h3 && buf_pointer > 1)
                                                block_size_in <= buf_pointer - 2'd2;
                                          else
                                                block_size_in <= buf_pointer;
                                          if (crc == 16'h4ffe && type_in[3:0] == ~type_in[7:4] &&
                                                      type_in[2:0] == 3'h3) begin
                                                crc_error <= 0;
                                                state <= SENDING; // send ACK
                                                bit_state <= 4'd14;
                                                type_out <= 8'hd2;
                                                block_size_out <= '0;
                                          end else begin
                                                crc_error <= type_in[2:0] == 3'h3 || type_in[3:0] != ~type_in[7:4];
                                                state <= IDLE;
                                          end
                                    end else if (&buf_pointer[6:5]) begin
                                          state <= IDLE;
                                          hstate_in <= 2'd3;
                                    end
                              end else begin
                                    bit_state <= 4'd7;
                                    case (hstate_in)
                                          2'd0: begin
                                                if (current_byte != 8'h80) begin
                                                      state <= IDLE;
                                                      hstate_in <= 2'd3;
                                                end else
                                                      hstate_in <= 2'd1;
                                          end
                                          2'd1: begin
                                                type_in <= current_byte;
                                                hstate_in <= 2'd2;
                                                buf_pointer <= '0;
                                                crc <= rbit ? 16'h8000 : 16'h2001;
                                          end
                                          2'd2: begin
                                                buffer[buf_pointer] <= current_byte;
                                                buf_pointer <= buf_pointer + 1'b1;
                                          end
                                    endcase
                              end
                        end
                  end
            end
      end
      
endmodule
