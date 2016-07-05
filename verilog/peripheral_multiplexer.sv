`include "bus_interfaces.sv"

module peripheral_multiplexer #(parameter PORT_COUNT = 2) (
            peripheral_interface.slave master,
            peripheral_interface.master port_list [PORT_COUNT-1:0]
      );
      
      wor [7:0] data_read;
      wor read_ready;
      wor write_ready;
      assign master.data_read = data_read;
      assign master.read_ready = read_ready;
      assign master.write_ready = write_ready;
      
      genvar i;
      generate
            for (i = 0; i < PORT_COUNT; i+=1) begin: p_generate
                  assign data_read = port_list[i].data_read;
                  assign read_ready = port_list[i].read_ready;
                  assign write_ready = port_list[i].write_ready;
                  assign port_list[i].data_write = master.data_write;
                  assign port_list[i].read_request = master.read_request;
                  assign port_list[i].write_request = master.write_request;
                  assign port_list[i].address = master.address;
            end
      endgenerate
      
endmodule
