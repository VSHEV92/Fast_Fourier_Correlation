// ---------------------------------------------------
// -----------  Блок считывания сигнала F1  ----------
// ---------------------------------------------------

module Recv_F1 
#(
    parameter NFFT = 256
)
(
    input  logic aclk,
    input  logic aresetn,
    input  logic [12:0] N1,
    input  logic start,
    output logic done,
    AXIS_intf.Slave indata,
    AXIS_intf.Master outdata 
);

    enum {IDLE, READ, PAD} state;
    logic [13:0] counter;
    
    // автомат управления
    always_ff @(posedge aclk)
        if (!aresetn)
            state <= IDLE;
        else 
            unique case (state)
                IDLE: state <= start ? READ : IDLE;
                READ: state <= (outdata.tvalid && outdata.tready && (counter == N1-1)) ? PAD : READ;
                PAD: state <= (outdata.tvalid && outdata.tready && (counter == NFFT-1)) ? IDLE : PAD;
            endcase

    // счетчик выданных отсчетов
    always_ff @(posedge aclk)
        if (!aresetn || state == IDLE)
            counter <= 0;
        else if (outdata.tready && outdata.tvalid)
            counter <= counter + 1;

    // выходные сигналы
    assign indata.tready = outdata.tready & (state == READ);
    assign outdata.tdata = (state != READ) ? 0 : indata.tdata;
    assign done = outdata.tready & outdata.tvalid & (counter == NFFT-1);

    always_comb
        unique case(state)
            IDLE: outdata.tvalid = 0;
            READ: outdata.tvalid = indata.tvalid;
            PAD:  outdata.tvalid = 1;
        endcase

endmodule