module Fast_Fourier_Correlation_top
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

    input  logic [31:0] func_1_tdata,
    input  logic func_1_tvalid,
    output logic func_1_tready,

    input  logic [31:0] func_2_tdata,
    input  logic func_2_tvalid,
    output logic func_2_tready,

    output logic [31:0] corr_tdata,
    output logic corr_tvalid,
    input  logic corr_tready
    );

Fast_Fourier_Correlation
#(
    .NFFT(NFFT)
)
(
    .aclk(aclk),
    .aresetn(aresetn),
    .N1(N1),
    .N2(N2),
    .IFFT_Shift(IFFT_Shift),
    .start(start),
    .idle(idle),
    .overflow(overflow),
    .func_1_tdata(func_1.tdata),
    .func_1_tvalid(func_1.tvalid),
    .func_1_tready(func_1.tready),
    .func_2_tdata(func_2.tdata),
    .func_2_tvalid(func_2.tvalid),
    .func_2_tready(func_2.tready),
    .corr_tdata(corr.tdata),
    .corr_tvalid(corr.tvalid),
    .corr_tready(corr.tready) 
);

endmodule
