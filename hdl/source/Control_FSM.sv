// ---------------------------------------------------
// -------------  Автомат управления ядром  ----------
// ---------------------------------------------------

module Control_FSM 
(
    input  logic aclk,
    input  logic aresetn,
    input  logic start,
    output logic fwd_inv,

    input  logic FFT_IP_tlast,

    output logic FFT_Config_Start,
    input  logic FFT_Config_Done,

    output logic Recv_F1_Start,

    output logic Recv_F2_Start,
    input  logic Recv_F2_Done,

    output logic Read_BRAM_Start,
    input  logic Read_BRAM_Done,

    output logic Out_Block_Start,
    input  logic Out_Block_Done,

    output logic [1:0] Mux_Sel,
    output logic [1:0] Demux_Sel,

    output logic idle
);

    enum {IDLE, CONFIG_FWD, TRAN_F1_READ_F2, TRAN_F1_DONE, READ_F2_DONE, TRAN_F2, RD_BRAM_DONE, CONFIG_INV, OUT_DATA} state;

    // автомат управления
    always_ff @(posedge aclk)
        if (!aresetn)
            state <= IDLE;
        else 
            unique case (state)

                IDLE: 
                    state <= start ? CONFIG_FWD : IDLE;
               
                CONFIG_FWD:
                    state <= FFT_Config_Done ? TRAN_F1_READ_F2 : CONFIG_FWD;

                TRAN_F1_READ_F2:
                    if (Recv_F2_Done && !FFT_IP_tlast)
                        state <= READ_F2_DONE;
                    else if (!Recv_F2_Done && FFT_IP_tlast)
                        state <= TRAN_F1_DONE;
                    else if (Recv_F2_Done && FFT_IP_tlast)
                        state <= TRAN_F2;

                READ_F2_DONE:
                    state <= FFT_IP_tlast ? TRAN_F2 : READ_F2_DONE;

                TRAN_F1_DONE:
                    state <= Recv_F2_Done ? TRAN_F2 : TRAN_F1_DONE;

                TRAN_F2:
                    state <= Read_BRAM_Done ? RD_BRAM_DONE : TRAN_F2;

                RD_BRAM_DONE:
                    state <= FFT_IP_tlast ? CONFIG_INV : RD_BRAM_DONE;
   
                CONFIG_INV:
                    state <= FFT_Config_Done ? OUT_DATA : CONFIG_INV;

                OUT_DATA:
                    state <= Out_Block_Done ? IDLE : OUT_DATA;            
                       
            endcase

    // формирование выходных сигналов
    assign fwd_inv = (state == CONFIG_FWD);
    assign FFT_Config_Start = (state == CONFIG_FWD) | (state == CONFIG_INV);
    assign Recv_F1_Start = (state == TRAN_F1_READ_F2);
    assign Recv_F2_Start = (state == TRAN_F1_READ_F2);
    assign Read_BRAM_Start = (state == TRAN_F2);
    assign Out_Block_Start = (state == OUT_DATA);
    assign idle = (state == IDLE);
    
    // формирование сигналов для мультиплексора
    always_comb
        unique case(state)
            IDLE, CONFIG_FWD, CONFIG_INV: Mux_Sel = 2'b00;
            TRAN_F1_READ_F2, READ_F2_DONE, TRAN_F1_DONE: Mux_Sel = 2'b01;
            TRAN_F2, RD_BRAM_DONE: Mux_Sel = 2'b10;
            OUT_DATA: Mux_Sel = 2'b11;
        endcase 

    // формирование сигналов для демультиплексора
    always_comb
        unique case(state)
            OUT_DATA: Demux_Sel = 2'b00;
            IDLE, CONFIG_FWD, TRAN_F1_READ_F2, READ_F2_DONE, TRAN_F1_DONE: Demux_Sel = 2'b01;
            CONFIG_INV, TRAN_F2, RD_BRAM_DONE: Demux_Sel = 2'b10;
        endcase 


endmodule