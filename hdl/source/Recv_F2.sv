// ---------------------------------------------------
// -----------  Блок считывания сигнала F2  ----------
// ---------------------------------------------------

module Recv_F2 
(
    input  logic aclk,
    input  logic aresetn,
    input  logic [12:0] N2,
    input  logic start,
    output logic done,

    AXIS_intf.Slave indata,

    output logic [31:0] bram_data,
    output logic [12:0] bram_addr,
    output logic        bram_we 
);

    enum {IDLE, READ} state;

    logic signed [15:0] re_bram;
    logic signed [15:0] im_bram;
    logic [12:0] counter; 

    // автомат управления
    always_ff @(posedge aclk)
        if (!aresetn)
            state <= IDLE;
        else 
            unique case (state)
                IDLE: state <= start ? READ : IDLE;
                READ: state <= (indata.tvalid && (counter == 0)) ? IDLE : READ;
            endcase

    // счетчик выданных отсчетов
    always_ff @(posedge aclk)
        if (!aresetn || state == IDLE)
            counter <= N2-1;
        else if (indata.tvalid)
            counter <= counter - 1;

    // промежуточные сигналы 
    assign re_bram = indata.tdata[15:0];
    assign im_bram = - $signed(indata.tdata[31:16]);
     
    // выходные сигналы
    assign indata.tready = (state == READ);
    assign bram_data = {im_bram, re_bram};
    assign bram_we = indata.tvalid & (state == READ);
    assign bram_addr = counter;
    assign done = indata.tvalid & (counter == 0);

endmodule