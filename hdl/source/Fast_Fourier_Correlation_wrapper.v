module Fast_Fourier_Correlation_wrapper
#(
    parameter NFFT = 256
)
(
    input  aclk,
    input  aresetn,
    input  [12:0] N1,
    input  [12:0] N2,
    input  [3:0] IFFT_Shift,
    input  start,
    output idle,
    output overflow,

    input  [31:0] func_1_tdata,
    input  func_1_tvalid,
    output func_1_tready,

    input  [31:0] func_2_tdata,
    input  func_2_tvalid,
    output func_2_tready,

    output [31:0] corr_tdata,
    output corr_tvalid,
    input  corr_tready
    );

Fast_Fourier_Correlation_top
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
    .func_1_tdata(func_1_tdata),
    .func_1_tvalid(func_1_tvalid),
    .func_1_tready(func_1_tready),
    .func_2_tdata(func_2_tdata),
    .func_2_tvalid(func_2_tvalid),
    .func_2_tready(func_2_tready),
    .corr_tdata(corr_tdata),
    .corr_tvalid(corr_tvalid),
    .corr_tready(corr_tready) 
);

endmodule
