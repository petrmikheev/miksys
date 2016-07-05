module cache #(CACHE_WIDTH = 4, CACHE_WIDTH_LOG = 2) (
            input wire clock,
            
            input wire core_ren,
            input wire [CACHE_WIDTH-1:0] core_wen,
            input wire [15:0] core_raddr,
            input wire [15:0] core_waddr,
            input wire [CACHE_WIDTH-1:0][15:0] core_wdata,
            output reg [CACHE_WIDTH-1:0][15:0] core_rdata,
            
            output wire sdram_en,
            input wire [3:0] sdram_wen,
            input wire [15:2] sdram_addr,
            input wire [3:0][15:0] sdram_wdata,
            output wire [3:0][15:0] sdram_rdata
      );

      assign sdram_en = ~(core_ren & |core_wen);
      reg l_sdram_pb;
      wire sdram_pb = ~|core_wen;
      wire sdram_pa = |core_wen & ~core_ren;
      wire [CACHE_WIDTH*16-1:0] q_a;
      wire [CACHE_WIDTH*16-1:0] q_b;
      wire [CACHE_WIDTH*16-1:0] q_sdram = l_sdram_pb ? q_b : q_a;
      assign sdram_rdata[0] = q_sdram[15:0];
      assign sdram_rdata[1] = q_sdram[31:16];
      assign sdram_rdata[2] = q_sdram[47:32];
      assign sdram_rdata[3] = q_sdram[63:48];
      
      wire [CACHE_WIDTH_LOG-1:0] wshift = core_waddr[CACHE_WIDTH_LOG-1:0];
      reg [CACHE_WIDTH_LOG-1:0] rshift = '0;
      reg [CACHE_WIDTH-1:0][15:0] core_shifted_wdata;
      wire [CACHE_WIDTH-1:0][15:0] core_shifted_rdata;
      wire [CACHE_WIDTH*16-1:0] core_prepared_wdata;
      wire [CACHE_WIDTH*16-1:0] sdram_prepared_wdata;
      reg [CACHE_WIDTH-1:0] core_shifted_wen;
      wire [CACHE_WIDTH-1:0] wen_sdram = sdram_wen;
      wire [CACHE_WIDTH*2-1:0] wen_pa;
      wire [CACHE_WIDTH*2-1:0] wen_pb;
      
      always @(posedge clock)
      begin
            l_sdram_pb <= sdram_pb;
            rshift <= core_raddr[CACHE_WIDTH_LOG-1:0];
      end
      
      always @(*) begin
            /*case (wshift)
                  2'd0: core_shifted_wdata = core_wdata;
                  2'd1: core_shifted_wdata = {core_wdata[2:0], core_wdata[3:3]};
                  2'd2: core_shifted_wdata = {core_wdata[1:0], core_wdata[3:2]};
                  2'd3: core_shifted_wdata = {core_wdata[0:0], core_wdata[3:1]};
            endcase
            case (wshift)
                  2'd0: core_shifted_wen = core_wen;
                  2'd1: core_shifted_wen = {core_wen[2:0], core_wen[3:3]};
                  2'd2: core_shifted_wen = {core_wen[1:0], core_wen[3:2]};
                  2'd3: core_shifted_wen = {core_wen[0:0], core_wen[3:1]};
            endcase
            case (rshift)
                  2'd0: core_rdata = core_shifted_rdata;
                  2'd1: core_rdata = {core_shifted_rdata[0:0], core_shifted_rdata[3:1]};
                  2'd2: core_rdata = {core_shifted_rdata[1:0], core_shifted_rdata[3:2]};
                  2'd3: core_rdata = {core_shifted_rdata[2:0], core_shifted_rdata[3:3]};
            endcase*/
            /*case (wshift)
                  2'd0: core_shifted_wdata = core_wdata;
                  2'd1: core_shifted_wdata = {16'b0, 16'b0, core_wdata[0], 16'b0};
                  2'd2: core_shifted_wdata = {16'b0, core_wdata[0], 16'b0, 16'b0};
                  2'd3: core_shifted_wdata = {core_wdata[0], 16'b0, 16'b0, 16'b0};
            endcase*/
            if (wshift == 0) core_shifted_wdata = core_wdata;
            else core_shifted_wdata = {4{core_wdata[0]}};
            case (wshift)
                  2'd0: core_shifted_wen = core_wen;
                  2'd1: core_shifted_wen = {2'b0, core_wen[0], 1'b0};
                  2'd2: core_shifted_wen = {1'b0, core_wen[0], 2'b0};
                  2'd3: core_shifted_wen = {core_wen[0], 3'b0};
            endcase
            core_rdata[0] = core_shifted_rdata[rshift];
            core_rdata[3:1] = core_shifted_rdata[3:1];
      end
      genvar i;
      generate
            for (i = 0; i < CACHE_WIDTH; i = i + 4) begin : sdram_wdata_generate
                  assign sdram_prepared_wdata[(i + 0)*16+15:(i + 0)*16] = sdram_wdata[0];
                  assign sdram_prepared_wdata[(i + 1)*16+15:(i + 1)*16] = sdram_wdata[1];
                  assign sdram_prepared_wdata[(i + 2)*16+15:(i + 2)*16] = sdram_wdata[2];
                  assign sdram_prepared_wdata[(i + 3)*16+15:(i + 3)*16] = sdram_wdata[3];
            end
            for (i = 0; i < CACHE_WIDTH; i = i + 1) begin : cw_generate
                  assign wen_pa[i*2+1:i*2] = {2{sdram_pa ? wen_sdram[i] : 1'b0}};
                  assign wen_pb[i*2+1:i*2] = {2{sdram_pb ? wen_sdram[i] : core_shifted_wen[i]}};
                  assign core_prepared_wdata[i*16+15:i*16] = core_shifted_wdata[i];
                  assign core_shifted_rdata[i] = q_a[i*16+15:i*16];
            end
      endgenerate
      
      RAM4096x64_2RW cache_ram (
            .address_a(sdram_pa ? sdram_addr[13:CACHE_WIDTH_LOG] : core_raddr[13:CACHE_WIDTH_LOG]),
            .address_b(sdram_pb ? sdram_addr[13:CACHE_WIDTH_LOG] : core_waddr[13:CACHE_WIDTH_LOG]),
            .byteena_a(wen_pa),
            .byteena_b(wen_pb),
            .clock(clock),
            .data_a(sdram_prepared_wdata),
            .data_b(sdram_pb ? sdram_prepared_wdata : core_prepared_wdata),
            .wren_a(|wen_pa),
            .wren_b(|wen_pb),
            .q_a(q_a),
            .q_b(q_b)
      );
      
endmodule
