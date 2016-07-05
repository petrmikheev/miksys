`include "bus_interfaces.sv"
`include "hardware_interfaces.sv"

module vga_controller (
            input clock,
            input reset,
            input vga_clock,
            mem_interface.master mem_bus,
            peripheral_interface.slave peripheral_bus,
            VGA_INTERFACE.OUT I_VGA
          );
          
      parameter horz_front_porch = 24;
      parameter horz_sync = 95;
      parameter horz_back_porch = 48;
      parameter screen_width = 640;
      
      parameter hbegin = horz_sync+horz_back_porch;
      parameter hend = horz_sync+horz_back_porch+screen_width;
  
      parameter vert_front_porch = 10;
      parameter vert_sync = 2;
      parameter vert_back_porch = 33;
      parameter screen_height = 480;
      
      initial I_VGA.HSYNC = 0;
      initial I_VGA.VSYNC = 0;
      
      reg [7:0] frame = '1;
      reg [5:0][7:0] settings = {8'd128, 8'd0, 8'd0, 8'd128, 8'd0, 8'd0};
      reg [2:0] settings_byte = 0;
      reg [15:0] background = '0;
      wire [13:0] graphic_buffer_address = background[13:0];
      reg [13:0] text_buffer_address = '0;
      reg graphic_enabled = 0;
      reg text_enabled = 0;
      
      parameter VGA_ADDRESS = 3'd2;
      always @(posedge clock) begin
            if (reset) begin
                  settings_byte <= 0;
                  peripheral_bus.read_ready <= 0;
                  peripheral_bus.write_ready <= 0;
                  settings <= {8'd128, 8'd0, 8'd0, 8'd128, 8'd0, 8'd0};
            end else begin
                  peripheral_bus.data_read <= peripheral_bus.address == VGA_ADDRESS ? frame : '0;
                  peripheral_bus.read_ready <= peripheral_bus.address == VGA_ADDRESS;
                  peripheral_bus.write_ready <= peripheral_bus.address == VGA_ADDRESS && peripheral_bus.write_request;
                  if (peripheral_bus.write_ready) begin
                        if (settings_byte != 5) settings_byte <= settings_byte + 1'b1;
                        else settings_byte <= 0;
                        settings[settings_byte] <= peripheral_bus.data_write;
                  end
            end
      end
      
      wire [17:0] char_bitline;
      reg [6:0] charx_sync = 0;
      reg [5:0] chary_sync = 0;
      reg chary_odd = 1;
      reg [6:0] loading_char_number = 0;
      reg [6:0] charx_counter = 0;
      reg [5:0] chary_counter = 0;
      reg [2:0] char_bitx_counter = 0;
      reg [1:0] char_bitline_counter = 0;
      reg [3:0] char_bitline_offset = 0;
      reg char_bit;
      reg [7:0] current_char;
      reg [7:0] char_color;
      reg [7:0] char_color_b1;
      reg [7:0] char_color_b2;
      
      reg [7:0] pixel_number = 0;
      //reg [7:0] pixel_number_sync = 0;
      reg [18:0] loading_pixel_number = 0;
      reg [15:0] pixel_color;
      reg odd_screen_vga_clock = 0;
      reg odd_screen;
      wire [15:0] buf_q;
      reg buf_n = 0;
      
      reg [9:0] horz_counter = 0;
      reg [9:0] vert_counter = 0;
      reg vvisible = 0;
      reg vvisible_sync = 0;
      wire hvisible = (horz_counter >= hbegin) && (horz_counter < hend);
      wire visible = vvisible & hvisible;
      reg [15:0] out_color;
      reg [15:0] mem_bus_data_read_buf;
      reg mem_bus_ready_buf;
      reg [8:0] buffer_wraddr;
      reg read_pixel_mode = 1;
      always @(posedge clock) begin
            mem_bus_data_read_buf <= mem_bus.data_read;
            mem_bus_ready_buf <= mem_bus.ready;
            buffer_wraddr <= read_pixel_mode ? {1'b0, loading_pixel_number[7:0]} : {2'b10, loading_char_number};
      end
      RAM512x16_1R1W buffer(
            .clock(clock),
            .data(mem_bus_data_read_buf),
            .wraddress(buffer_wraddr),
            .wren(mem_bus_ready_buf),
            .rdaddress(buf_n ? {1'b0, pixel_number} : {2'b10, charx_sync} ),
            .q(buf_q)
      );
      CHARMAP charmap(
            .clock(clock),
            .address({current_char[6:0], char_bitline_counter}),
            .q(char_bitline)
      );
      reg load_odd_block = 0;
      reg load_odd_block_vga_clock = 0;
      reg next_pixel_request;
      reg next_char_request;
      reg next_read_pixel_mode;
      reg [18:0] next_loading_pixel_number;
      reg [6:0] next_loading_char_number;
      reg [21:0] next_read_char_address;
      reg [21:0] next_read_pixel_address;
      assign mem_bus.write_enable = 0;
      assign mem_bus.data_write = '0;
      initial mem_bus.request = 0;
      reg next_char_counter = 0;
      always @(posedge clock)
      begin
            //pixel_number_sync <= pixel_number;
            char_color <= char_color_b1;
            char_color_b1 <= char_color_b2;
            char_bit <= char_bitline[{1'b0, char_bitline_offset} + char_bitx_counter];
            charx_sync <= charx_counter;
            chary_sync <= chary_counter;
            vvisible_sync <= vvisible;
            odd_screen <= odd_screen_vga_clock;
            load_odd_block <= load_odd_block_vga_clock;
            buf_n <= ~buf_n;
            if (buf_n) begin
                  current_char <= buf_q[7:0];
                  char_color_b2 <= buf_q[15:8];
            end else
                  pixel_color <= graphic_enabled ? buf_q : background;
            next_read_pixel_mode = mem_bus.request ? read_pixel_mode : ~read_pixel_mode;
            read_pixel_mode <= next_read_pixel_mode;
            
            if (mem_bus.ready & read_pixel_mode) begin
                  next_loading_pixel_number = loading_pixel_number + 1'b1;
            end else if (frame[0] != odd_screen) begin
                  next_loading_pixel_number = '0;
                  frame <= frame + 1'b1;
                  if (~peripheral_bus.write_ready) begin
                        text_buffer_address <= {settings[1][5:0], settings[0]};
                        text_enabled <= ~settings[2][7];
                        background <= {settings[4], settings[3]};
                        graphic_enabled <= ~settings[5][7];
                  end
                  chary_odd <= 1;
            end
            loading_pixel_number <= next_loading_pixel_number;
            
            next_char_counter <= chary_odd != chary_sync[0];
            
            if (chary_odd != chary_sync[0] && next_char_counter) begin
                  next_loading_char_number = '0;
                  if (frame[0] == odd_screen) chary_odd <= ~chary_odd;
            end else if (mem_bus.ready & ~read_pixel_mode) begin
                  next_loading_char_number = loading_char_number + 1'b1;
            end else begin
                  next_loading_char_number = loading_char_number;
            end
            next_read_char_address = {text_buffer_address + chary_sync[5:1], chary_sync[0], next_loading_char_number};
            loading_char_number <= next_loading_char_number;
            mem_bus.last4 <= next_read_pixel_mode ? next_loading_pixel_number[6:0] == 122 : next_loading_char_number == 101;
            next_pixel_request = (next_loading_pixel_number[7] == load_odd_block) &&
                           (next_loading_pixel_number[18:12] < 7'h4b) && graphic_enabled;
            next_char_request = (vvisible_sync && next_loading_char_number < 107) && text_enabled;
            mem_bus.request <= next_read_pixel_mode ? next_pixel_request : next_char_request;
            next_read_pixel_address = {graphic_buffer_address + next_loading_pixel_number[18:8], next_loading_pixel_number[7:0]};
            mem_bus.address <= next_read_pixel_mode ? next_read_pixel_address : next_read_char_address;
      end
      
      always @(posedge vga_clock) begin
            if (visible)
                  if (text_enabled & char_bit)
                        out_color <= {char_color[7:5], char_color[7:6],
                                     char_color[4:2], char_color[4:2],
                                     char_color[1:0], char_color[1:0], char_color[1]};
                  else
                        out_color <= pixel_color;
            else
                  out_color <= '0;
      end
      assign I_VGA.RED = out_color[15:11];
      assign I_VGA.GREEN = out_color[10:5];
      assign I_VGA.BLUE = out_color[4:0];
	
      always @(posedge vga_clock)
      begin
            I_VGA.HSYNC <= (horz_counter < horz_sync);			  
            if (horz_counter < (horz_sync+horz_back_porch+screen_width+horz_front_porch) ) begin
                  horz_counter <= horz_counter + 1'b1;
                  if (visible) begin
                        if (char_bitx_counter == 5)
                              char_bitx_counter <= 0;
                        else
                              char_bitx_counter <= char_bitx_counter + 1'b1;
                        if (char_bitx_counter == 4)
                              charx_counter <= charx_counter + 1'b1;
                  end
            end else begin
                  horz_counter <= '0;
                  charx_counter <= '0;
                  char_bitx_counter <= '0;
                  I_VGA.VSYNC <= (vert_counter < vert_sync);
                  vvisible <= (vert_counter >= (vert_sync+vert_back_porch)) &&
                              (vert_counter < (vert_sync+vert_back_porch+screen_height));
                  if(vert_counter < (vert_sync+vert_back_porch+screen_height+vert_front_porch) ) begin
                        vert_counter <= vert_counter + 1'b1;
                        if (vvisible) begin
                              if (char_bitline_offset != 4'hc)
                                    char_bitline_offset <= char_bitline_offset + 3'd6;
                              else begin
                                    char_bitline_offset <= 0;
                                    char_bitline_counter <= char_bitline_counter + 1'b1;
                                    if (&char_bitline_counter) chary_counter <= chary_counter + 1'b1;
                              end
                        end
                  end else begin
                        vert_counter <= '0;
                        chary_counter <= '0;
                        char_bitline_counter <= '0;
                        char_bitline_offset <= '0;
                        pixel_number <= '0;
                        load_odd_block_vga_clock <= '0;
                        odd_screen_vga_clock <= ~odd_screen_vga_clock;
                  end
            end
                        
            if (visible) begin
                  pixel_number <= pixel_number + 1'b1;
                  if (pixel_number[6:0] == 0) load_odd_block_vga_clock <= ~load_odd_block_vga_clock;
            end
      end

endmodule
