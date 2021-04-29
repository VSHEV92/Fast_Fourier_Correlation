// ---------------------------------------------------
// --------------  Блок считывания BRAM  -------------
// ---------------------------------------------------
module Read_BRAM 
#(
    parameter NFFT = 256
)
(
    input  logic aclk,
    input  logic aresetn,
    input  logic [12:0] N2,
    input  logic start,
    output logic done,
    
    AXIS_intf.Master outdata,

    input  logic [31:0] bram_data,
    output logic [12:0] bram_addr 
);

    enum {IDLE, READ, PAD} state;
    logic [12:0] addr; 
    logic [12:0] next_addr; 
    logic [12:0] pad_cout; 
    
    // автомат управления
    always_ff @(posedge aclk)
        if (!aresetn)
            state <= IDLE;
        else 
            unique case (state)
                IDLE: state <= start ? READ : IDLE;
                READ: state <= (outdata.tvalid && outdata.tready && (addr == N2-1)) ? PAD : READ;
                PAD: state <= (outdata.tvalid && outdata.tready && (pad_cout == NFFT-N2-1)) ? IDLE : PAD;
            endcase

    // счетчик текущего адреса
    always_ff @(posedge aclk)
        if (!aresetn || state != READ)
            addr <= 0;
        else if (outdata.tready && outdata.tvalid)
            addr <= addr + 1;

     // счетчик следующего адреса
    always_ff @(posedge aclk)
        if (!aresetn || state != READ)
            next_addr <= 1;
        else if (outdata.tready && outdata.tvalid)
            next_addr <= next_addr + 1;

    // счетчик добавленных отсчетов
    always_ff @(posedge aclk)
        if (!aresetn || state != PAD)
            pad_cout <= 0;
        else if (outdata.tready && outdata.tvalid)
            pad_cout <= pad_cout + 1;
                
    // выходные сигналы
    assign outdata.tvalid = (state != IDLE);
    assign outdata.tdata = (state != READ) ? 0 : bram_data;
    assign done = outdata.tready & outdata.tvalid & (pad_cout == NFFT-N2-1);
    assign bram_addr = ((state != READ) | !outdata.tready) ? addr : next_addr;
    
endmodule