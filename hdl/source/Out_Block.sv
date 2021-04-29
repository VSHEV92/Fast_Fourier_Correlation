// ------------------------------------------------------
// --------  Блок отбрасывания нулевых отсчетов  --------
// ------------------------------------------------------

module Out_Block 
#(
    parameter NFFT = 256
)
(
    input  logic aclk,
    input  logic aresetn,
    input  logic [12:0] N1,
    input  logic [12:0] N2,
    input  logic start,
    output logic done,
    AXIS_intf.Slave indata,
    AXIS_intf.Master outdata 
);

    enum {IDLE, WRITE, TRUNC} state;
    logic [13:0] counter;
    
    // автомат управления
    always_ff @(posedge aclk)
        if (!aresetn)
            state <= IDLE;
        else 
            unique case (state)
                IDLE:  state <= start ? WRITE : IDLE;
                WRITE: state <= (indata.tvalid && indata.tready && (counter == N1+N2-2)) ? TRUNC : WRITE;
                TRUNC: state <= (indata.tvalid && indata.tready && (counter == NFFT-1)) ? IDLE : TRUNC;
            endcase

    // счетчик полученных отсчетов
    always_ff @(posedge aclk)
        if (!aresetn || state == IDLE)
            counter <= 0;
        else if (indata.tready && indata.tvalid)
            counter <= counter + 1;

    // выходные сигналы
    assign indata.tready = (outdata.tready & (state == WRITE)) | (state == TRUNC);
    assign outdata.tdata = (state != WRITE) ? 0 : indata.tdata;
    assign done = indata.tready & indata.tvalid & (counter == NFFT-1);

    always_comb
        unique case(state)
            IDLE:  outdata.tvalid = 0;
            WRITE: outdata.tvalid = indata.tvalid;
            TRUNC: outdata.tvalid = 0;
        endcase

endmodule