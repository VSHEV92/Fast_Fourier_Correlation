// ---------------------------------------------------
// --------  Блок конфигурирования ядра FFT  ---------
// ---------------------------------------------------

module FFT_Config (
    input  logic aclk,
    input  logic aresetn,
    input  logic fwd_inv,
    input  logic start,
    output logic done,
    AXIS_intf.Master config_out 
);

    enum {IDLE, WORK} state;

    // автомат управления
    always_ff @(posedge aclk)
        if (!aresetn)
            state <= IDLE;
        else 
            unique case (state)
                IDLE: state <= start ? WORK : IDLE;
                WORK: state <= config_out.tready ? IDLE : WORK;
            endcase

    // выходные сигналы
    assign config_out.tdata = fwd_inv ? 255 : 0;
    assign config_out.tvalid = (state == WORK);
    assign done = config_out.tready & config_out.tvalid;

endmodule