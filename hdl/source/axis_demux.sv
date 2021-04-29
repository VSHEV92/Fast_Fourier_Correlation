// ---------------------------------------------------
// ------- Демультиплексор AXI-Stream портов  --------
// ---------------------------------------------------

module axis_demux
(
    input logic [1:0] Demux_Sel, 
    AXIS_intf.Slave indata,
    AXIS_intf.Master outdata_1,
    AXIS_intf.Master outdata_2,
    AXIS_intf.Master outdata_3
);

`define axis_connect(out_port, in_port) \
    out_port.tdata = in_port.tdata; \
    out_port.tvalid = in_port.tvalid; \
    in_port.tready = out_port.tready;

logic aclk;
logic aresetn;

AXIS_intf #(32) Null_out_intf_1();
AXIS_intf #(32) Null_out_intf_2();

assign Null_out_intf_1.tdata = 0;
assign Null_out_intf_1.tvalid = 1'b0;
assign Null_out_intf_2.tdata = 0;
assign Null_out_intf_2.tvalid = 1'b0;

always_comb
    unique case(Demux_Sel)
        2'b00: begin
            `axis_connect(outdata_1, indata)
            `axis_connect(outdata_2, Null_out_intf_1)
            `axis_connect(outdata_3, Null_out_intf_2)
        end
        2'b01: begin
            `axis_connect(outdata_1, Null_out_intf_1)
            `axis_connect(outdata_2, indata)
            `axis_connect(outdata_3, Null_out_intf_2)
        end
        2'b10: begin
            `axis_connect(outdata_1, Null_out_intf_1)
            `axis_connect(outdata_2, Null_out_intf_2)
            `axis_connect(outdata_3, indata)
        end
    endcase
    
endmodule