// ----------------------------------------------------------------------
// ---------- Ядро вычисления взаимной корреляционной функции  ----------
// ----------------------------------------------------------------------
module Fast_Fourier_Correlation
#(
    parameter NFFT = 256
)
(
    input  logic aclk,
    input  logic aresetn,
    input  logic [12:0] N1,
    input  logic [12:0] N2,
    input  logic [3:0] IFFT_Shift,
    input  logic start,
    output logic idle,
    output logic overflow,
    AXIS_intf.Slave func_1,
    AXIS_intf.Slave func_2,
    AXIS_intf.Master corr 
);

// интерфейсы для соединения блоков

AXIS_intf #(32) Null_intf();
AXIS_intf #(8) fft_config_out();
AXIS_intf #(32) demux_out_1();
AXIS_intf #(32) demux_out_2();
AXIS_intf #(32) demux_out_3();
AXIS_intf #(32) fifo_1_out();
AXIS_intf #(32) fifo_2_out();
AXIS_intf #(32) Recv_F1_out();
AXIS_intf #(32) Read_BRAM_out();
AXIS_intf #(32) mult_shift_out();
AXIS_intf #(32) mux_out();
AXIS_intf #(32) fft_out();

logic fwd_inv;
logic FFT_IP_tlast;
logic FFT_Config_Start;
logic FFT_Config_Done;
logic Recv_F1_Start;
logic Recv_F2_Start;
logic Recv_F2_Done;
logic Read_BRAM_Start;
logic Read_BRAM_Done;
logic Out_Block_Start;
logic Out_Block_Done;
logic [1:0] Mux_Sel;
logic [1:0] Demux_Sel;

logic [31:0] bram_data_in;
logic [31:0] bram_data_out;
logic [12:0] bram_addr_in;
logic [12:0] bram_addr_out;
logic        bram_we; 

logic overflow_mult_shift;

// -------- Автомат управления ядром ------
Control_FSM Control_FSM_inst(.*);

// --------  Блок конфигурирования ядра FFT ------
FFT_Config FFT_Config_inst(.*, .start(FFT_Config_Start), .done(FFT_Config_Done), .config_out(fft_config_out));

// --------  Блок считывания сигнала F1 ------
Recv_F1 #(.NFFT(NFFT)) Recv_F1_inst (.*, .start(Recv_F1_Start), .done(), .indata(func_1), .outdata(Recv_F1_out));

// --------  Блок считывания сигнала F2 ------
Recv_F2 Recv_F2_inst (.*, .start(Recv_F2_Start), .done(Recv_F2_Done), .indata(func_2), .bram_data(bram_data_in), .bram_addr(bram_addr_in), .bram_we(bram_we));

// --------  Блок считывания BRAM ------
Read_BRAM #(.NFFT(NFFT)) Read_BRAM_inst (.*, .start(Read_BRAM_Start), .done(Read_BRAM_Done), .outdata(Read_BRAM_out), .bram_data(bram_data_out), .bram_addr(bram_addr_out));

// --------  Блок умножения и сдвига ------
Mult_Shift Mult_Shift_inst  (.*, .overflow(overflow_mult_shift), .indata_1(fifo_1_out), .indata_2(demux_out_3), .outdata(mult_shift_out));

// --------  Блок отбрасывания нулевых отсчетов ------
Out_Block #(.NFFT(NFFT)) Out_Block_inst (.*, .start(Out_Block_Start), .done(Out_Block_Done), .indata(demux_out_1), .outdata(corr));

// -------- Мультиплексор --------
axis_mux axis_mux_inst(.*, .indata_1(Null_intf), .indata_2(Recv_F1_out), .indata_3(Read_BRAM_out), .indata_4(fifo_2_out), .outdata(mux_out));

// -------- Демультиплексор --------
axis_demux axis_demux_inst(.*, .indata(fft_out), .outdata_1(demux_out_1), .outdata_2(demux_out_2), .outdata_3(demux_out_3));


// создание интерфейса с нулевыми данными
assign Null_intf.tvalid = 1'b0;
assign Null_intf.tdata = 0;

// обработка флага переполнения 
always_ff @(posedge aclk)
    if (!aresetn | (idle & start))
        overflow <= 0;
    else if (overflow_mult_shift)
        overflow <= 1;    


// ------------------------------------------------------------------------------------
// ---------------------------- генерация IP-ядер Xilixn ------------------------------
generate
if (NFFT == 128) begin
    BRAM_Mem_128 BRAM_Mem (
        .clka(aclk),    
        .wea(bram_we),      
        .addra(bram_addr_in),  
        .dina(bram_data_in),    
        .clkb(aclk),    
        .addrb(bram_addr_out),  
        .doutb(bram_data_out)  
    );
    FIFO_1_128 FIFO_1 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(demux_out_2.tvalid),    
        .s_axis_tready(demux_out_2.tready),    
        .s_axis_tdata(demux_out_2.tdata),     
        .m_axis_tvalid(fifo_1_out.tvalid),    
        .m_axis_tready(fifo_1_out.tready),    
        .m_axis_tdata(fifo_1_out.tdata)      
    );
    FIFO_2_128 FIFO_2 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(mult_shift_out.tvalid),    
        .s_axis_tready(mult_shift_out.tready),    
        .s_axis_tdata(mult_shift_out.tdata),     
        .m_axis_tvalid(fifo_2_out.tvalid),    
        .m_axis_tready(fifo_2_out.tready),    
        .m_axis_tdata(fifo_2_out.tdata)      
    );
    FFT_128 FFT_Core (
        .aclk(aclk),                                                
        .aresetn(aresetn),                                          
        .s_axis_config_tdata(fft_config_out.tdata),                  
        .s_axis_config_tvalid(fft_config_out.tvalid),                
        .s_axis_config_tready(fft_config_out.tready),
        .s_axis_data_tdata(mux_out.tdata),  
        .s_axis_data_tvalid(mux_out.tvalid),     
        .s_axis_data_tready(mux_out.tready),  
        .s_axis_data_tlast(1'b0),           
        .m_axis_data_tdata(fft_out.tdata),                     
        .m_axis_data_tvalid(fft_out.tvalid),                    
        .m_axis_data_tready(fft_out.tready),                   
        .m_axis_data_tlast(FFT_IP_tlast),                      
        .m_axis_status_tready(1'b1)                    
    );
end
if (NFFT == 256) begin
    BRAM_Mem_256 BRAM_Mem (
        .clka(aclk),    
        .wea(bram_we),      
        .addra(bram_addr_in),  
        .dina(bram_data_in),    
        .clkb(aclk),    
        .addrb(bram_addr_out),  
        .doutb(bram_data_out)  
    );
    FIFO_1_256 FIFO_1 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(demux_out_2.tvalid),    
        .s_axis_tready(demux_out_2.tready),    
        .s_axis_tdata(demux_out_2.tdata),     
        .m_axis_tvalid(fifo_1_out.tvalid),    
        .m_axis_tready(fifo_1_out.tready),    
        .m_axis_tdata(fifo_1_out.tdata)      
    );
    FIFO_2_256 FIFO_2 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(mult_shift_out.tvalid),    
        .s_axis_tready(mult_shift_out.tready),    
        .s_axis_tdata(mult_shift_out.tdata),     
        .m_axis_tvalid(fifo_2_out.tvalid),    
        .m_axis_tready(fifo_2_out.tready),    
        .m_axis_tdata(fifo_2_out.tdata)      
    );
    FFT_256 FFT_Core (
        .aclk(aclk),                                                
        .aresetn(aresetn),                                          
        .s_axis_config_tdata(fft_config_out.tdata),                  
        .s_axis_config_tvalid(fft_config_out.tvalid),                
        .s_axis_config_tready(fft_config_out.tready),
        .s_axis_data_tdata(mux_out.tdata),  
        .s_axis_data_tvalid(mux_out.tvalid),     
        .s_axis_data_tready(mux_out.tready),  
        .s_axis_data_tlast(1'b0),           
        .m_axis_data_tdata(fft_out.tdata),                     
        .m_axis_data_tvalid(fft_out.tvalid),                    
        .m_axis_data_tready(fft_out.tready),                   
        .m_axis_data_tlast(FFT_IP_tlast),                      
        .m_axis_status_tready(1'b1)                    
    );    
end
if (NFFT == 512) begin
    BRAM_Mem_512 BRAM_Mem (
        .clka(aclk),    
        .wea(bram_we),      
        .addra(bram_addr_in),  
        .dina(bram_data_in),    
        .clkb(aclk),    
        .addrb(bram_addr_out),  
        .doutb(bram_data_out)  
    );
    FIFO_1_512 FIFO_1 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(demux_out_2.tvalid),    
        .s_axis_tready(demux_out_2.tready),    
        .s_axis_tdata(demux_out_2.tdata),     
        .m_axis_tvalid(fifo_1_out.tvalid),    
        .m_axis_tready(fifo_1_out.tready),    
        .m_axis_tdata(fifo_1_out.tdata)      
    );
    FIFO_2_512 FIFO_2 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(mult_shift_out.tvalid),    
        .s_axis_tready(mult_shift_out.tready),    
        .s_axis_tdata(mult_shift_out.tdata),     
        .m_axis_tvalid(fifo_2_out.tvalid),    
        .m_axis_tready(fifo_2_out.tready),    
        .m_axis_tdata(fifo_2_out.tdata)      
    );
    FFT_512 FFT_Core (
        .aclk(aclk),                                                
        .aresetn(aresetn),                                          
        .s_axis_config_tdata(fft_config_out.tdata),                  
        .s_axis_config_tvalid(fft_config_out.tvalid),                
        .s_axis_config_tready(fft_config_out.tready),
        .s_axis_data_tdata(mux_out.tdata),  
        .s_axis_data_tvalid(mux_out.tvalid),     
        .s_axis_data_tready(mux_out.tready),  
        .s_axis_data_tlast(1'b0),           
        .m_axis_data_tdata(fft_out.tdata),                     
        .m_axis_data_tvalid(fft_out.tvalid),                    
        .m_axis_data_tready(fft_out.tready),                   
        .m_axis_data_tlast(FFT_IP_tlast),                      
        .m_axis_status_tready(1'b1)                    
    );
end
if (NFFT == 1024) begin
    BRAM_Mem_1024 BRAM_Mem (
        .clka(aclk),    
        .wea(bram_we),      
        .addra(bram_addr_in),  
        .dina(bram_data_in),    
        .clkb(aclk),    
        .addrb(bram_addr_out),  
        .doutb(bram_data_out)  
    );
    FIFO_1_1024 FIFO_1 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(demux_out_2.tvalid),    
        .s_axis_tready(demux_out_2.tready),    
        .s_axis_tdata(demux_out_2.tdata),     
        .m_axis_tvalid(fifo_1_out.tvalid),    
        .m_axis_tready(fifo_1_out.tready),    
        .m_axis_tdata(fifo_1_out.tdata)      
    );
    FIFO_2_1024 FIFO_2 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(mult_shift_out.tvalid),    
        .s_axis_tready(mult_shift_out.tready),    
        .s_axis_tdata(mult_shift_out.tdata),     
        .m_axis_tvalid(fifo_2_out.tvalid),    
        .m_axis_tready(fifo_2_out.tready),    
        .m_axis_tdata(fifo_2_out.tdata)      
    );
    FFT_1024 FFT_Core (
        .aclk(aclk),                                                
        .aresetn(aresetn),                                          
        .s_axis_config_tdata(fft_config_out.tdata),                  
        .s_axis_config_tvalid(fft_config_out.tvalid),                
        .s_axis_config_tready(fft_config_out.tready),
        .s_axis_data_tdata(mux_out.tdata),  
        .s_axis_data_tvalid(mux_out.tvalid),     
        .s_axis_data_tready(mux_out.tready),  
        .s_axis_data_tlast(1'b0),           
        .m_axis_data_tdata(fft_out.tdata),                     
        .m_axis_data_tvalid(fft_out.tvalid),                    
        .m_axis_data_tready(fft_out.tready),                   
        .m_axis_data_tlast(FFT_IP_tlast),                      
        .m_axis_status_tready(1'b1)                    
    );
end
if (NFFT == 2048) begin
    BRAM_Mem_2048 BRAM_Mem (
        .clka(aclk),    
        .wea(bram_we),      
        .addra(bram_addr_in),  
        .dina(bram_data_in),    
        .clkb(aclk),    
        .addrb(bram_addr_out),  
        .doutb(bram_data_out)  
    );
    FIFO_1_2048 FIFO_1 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(demux_out_2.tvalid),    
        .s_axis_tready(demux_out_2.tready),    
        .s_axis_tdata(demux_out_2.tdata),     
        .m_axis_tvalid(fifo_1_out.tvalid),    
        .m_axis_tready(fifo_1_out.tready),    
        .m_axis_tdata(fifo_1_out.tdata)      
    );
    FIFO_2_2048 FIFO_2 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(mult_shift_out.tvalid),    
        .s_axis_tready(mult_shift_out.tready),    
        .s_axis_tdata(mult_shift_out.tdata),     
        .m_axis_tvalid(fifo_2_out.tvalid),    
        .m_axis_tready(fifo_2_out.tready),    
        .m_axis_tdata(fifo_2_out.tdata)      
    );
    FFT_2048 FFT_Core (
        .aclk(aclk),                                                
        .aresetn(aresetn),                                          
        .s_axis_config_tdata(fft_config_out.tdata),                  
        .s_axis_config_tvalid(fft_config_out.tvalid),                
        .s_axis_config_tready(fft_config_out.tready),
        .s_axis_data_tdata(mux_out.tdata),  
        .s_axis_data_tvalid(mux_out.tvalid),     
        .s_axis_data_tready(mux_out.tready),  
        .s_axis_data_tlast(1'b0),           
        .m_axis_data_tdata(fft_out.tdata),                     
        .m_axis_data_tvalid(fft_out.tvalid),                    
        .m_axis_data_tready(fft_out.tready),                   
        .m_axis_data_tlast(FFT_IP_tlast),                      
        .m_axis_status_tready(1'b1)                    
    );
end
if (NFFT == 4096) begin
    BRAM_Mem_4096 BRAM_Mem (
        .clka(aclk),    
        .wea(bram_we),      
        .addra(bram_addr_in),  
        .dina(bram_data_in),    
        .clkb(aclk),    
        .addrb(bram_addr_out),  
        .doutb(bram_data_out)  
    );
    FIFO_1_4096 FIFO_1 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(demux_out_2.tvalid),    
        .s_axis_tready(demux_out_2.tready),    
        .s_axis_tdata(demux_out_2.tdata),     
        .m_axis_tvalid(fifo_1_out.tvalid),    
        .m_axis_tready(fifo_1_out.tready),    
        .m_axis_tdata(fifo_1_out.tdata)      
    );
    FIFO_2_4096 FIFO_2 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(mult_shift_out.tvalid),    
        .s_axis_tready(mult_shift_out.tready),    
        .s_axis_tdata(mult_shift_out.tdata),     
        .m_axis_tvalid(fifo_2_out.tvalid),    
        .m_axis_tready(fifo_2_out.tready),    
        .m_axis_tdata(fifo_2_out.tdata)      
    );
    FFT_4096 FFT_Core (
        .aclk(aclk),                                                
        .aresetn(aresetn),                                          
        .s_axis_config_tdata(fft_config_out.tdata),                  
        .s_axis_config_tvalid(fft_config_out.tvalid),                
        .s_axis_config_tready(fft_config_out.tready),
        .s_axis_data_tdata(mux_out.tdata),  
        .s_axis_data_tvalid(mux_out.tvalid),     
        .s_axis_data_tready(mux_out.tready),  
        .s_axis_data_tlast(1'b0),           
        .m_axis_data_tdata(fft_out.tdata),                     
        .m_axis_data_tvalid(fft_out.tvalid),                    
        .m_axis_data_tready(fft_out.tready),                   
        .m_axis_data_tlast(FFT_IP_tlast),                      
        .m_axis_status_tready(1'b1)                    
    );
end
if (NFFT == 8192) begin
    BRAM_Mem_8192 BRAM_Mem (
        .clka(aclk),    
        .wea(bram_we),      
        .addra(bram_addr_in),  
        .dina(bram_data_in),    
        .clkb(aclk),    
        .addrb(bram_addr_out),  
        .doutb(bram_data_out)  
    );
    FIFO_1_8192 FIFO_1 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(demux_out_2.tvalid),    
        .s_axis_tready(demux_out_2.tready),    
        .s_axis_tdata(demux_out_2.tdata),     
        .m_axis_tvalid(fifo_1_out.tvalid),    
        .m_axis_tready(fifo_1_out.tready),    
        .m_axis_tdata(fifo_1_out.tdata)      
    );
    FIFO_2_8192 FIFO_2 (
        .s_axis_aresetn(aresetn), 
        .s_axis_aclk(aclk),        
        .s_axis_tvalid(mult_shift_out.tvalid),    
        .s_axis_tready(mult_shift_out.tready),    
        .s_axis_tdata(mult_shift_out.tdata),     
        .m_axis_tvalid(fifo_2_out.tvalid),    
        .m_axis_tready(fifo_2_out.tready),    
        .m_axis_tdata(fifo_2_out.tdata)      
    );
    FFT_8192 FFT_Core (
        .aclk(aclk),                                                
        .aresetn(aresetn),                                          
        .s_axis_config_tdata(fft_config_out.tdata),                  
        .s_axis_config_tvalid(fft_config_out.tvalid),                
        .s_axis_config_tready(fft_config_out.tready),
        .s_axis_data_tdata(mux_out.tdata),  
        .s_axis_data_tvalid(mux_out.tvalid),     
        .s_axis_data_tready(mux_out.tready),  
        .s_axis_data_tlast(1'b0),           
        .m_axis_data_tdata(fft_out.tdata),                     
        .m_axis_data_tvalid(fft_out.tvalid),                    
        .m_axis_data_tready(fft_out.tready),                   
        .m_axis_data_tlast(FFT_IP_tlast),                      
        .m_axis_status_tready(1'b1)                    
    );
end
endgenerate

endmodule
