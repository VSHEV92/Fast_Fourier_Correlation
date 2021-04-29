// ---------------------------------------------------
// -------- Мультиплексор AXI-Stream портов  ---------
// ---------------------------------------------------

module axis_mux
(
    input logic [1:0] Mux_Sel, 
    AXIS_intf.Slave indata_1,
    AXIS_intf.Slave indata_2,
    AXIS_intf.Slave indata_3,
    AXIS_intf.Slave indata_4,
    AXIS_intf.Master outdata
);

`define axis_connect(out_port, in_port) \
    out_port.tdata = in_port.tdata; \
    out_port.tvalid = in_port.tvalid; \
    in_port.tready = out_port.tready;

always_comb
    unique case(Mux_Sel)
        2'b00: begin
            `axis_connect(outdata, indata_1)
            indata_2.tready = 1'b0;
            indata_3.tready = 1'b0;
            indata_4.tready = 1'b0;
        end
        2'b01: begin
            `axis_connect(outdata, indata_2)
            indata_1.tready = 1'b0;
            indata_3.tready = 1'b0;
            indata_4.tready = 1'b0;
        end
        2'b10: begin
            `axis_connect(outdata, indata_3)
            indata_1.tready = 1'b0;
            indata_2.tready = 1'b0;
            indata_4.tready = 1'b0;
        end
        2'b11: begin
            `axis_connect(outdata, indata_4)
            indata_1.tready = 1'b0;
            indata_2.tready = 1'b0;
            indata_3.tready = 1'b0;
        end
    endcase

endmodule