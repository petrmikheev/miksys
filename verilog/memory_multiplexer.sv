`include "bus_interfaces.sv"

module memory_multiplexer #(parameter PORT_COUNT = 2) (
            input clock,
            input switch,
            mem_interface.master resource,
            mem_interface.slave port_list [PORT_COUNT-1:0]
      );

      reg [PORT_COUNT-1:0] current = 1;
      reg [PORT_COUNT-1:0] last_current = 1;
      wor [15:0] data_write;
      wor [21:0] address;
      wor request;
      wor write_enable;
      wor last4;
      assign resource.data_write = data_write;
      assign resource.address = address;
      assign resource.request = request;
      assign resource.write_enable = write_enable;
      assign resource.last4 = last4;
      genvar i;
      generate
            for (i = 0; i < PORT_COUNT; i+=1) begin: port_generate
                  assign port_list[i].data_read = resource.data_read;
                  assign port_list[i].ready = current[i] ? (resource.ready && port_list[i].request) : 1'b0;
                  assign data_write = last_current[i] ? port_list[i].data_write : 16'b0;
                  assign address = current[i] ? port_list[i].address : 22'b0;
                  assign request = current[i] ? port_list[i].request : 1'b0;
                  assign last4 = current[i] ? port_list[i].last4 : 1'b0;
                  assign write_enable = current[i] ? port_list[i].write_enable : 1'b0;
            end
      endgenerate
      
      always @(posedge clock) begin
            if (~request | switch) current <= {current[PORT_COUNT-2:0], current[PORT_COUNT-1]};
            last_current <= current;
      end

endmodule
