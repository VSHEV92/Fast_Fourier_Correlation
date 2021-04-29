// ---------------------------------------------------
// --------------  AXIS интерфейс  -------------------
// ---------------------------------------------------
interface AXIS_intf
    #(
        parameter int TDATA_WIDTH = 32
    )
    ();

    bit tready;
    bit tvalid;
    bit [TDATA_WIDTH-1:0] tdata;
    
    modport Master (
        output tdata, tvalid,
        input  tready
    );

    modport Slave (
        input  tdata, tvalid,
        output tready
    );

endinterface

interface Aclk_Aresetn_intf(
    input bit aclk,
    input bit aresetn
);

endinterface