`timescale 1ns / 1ps

`include "Environment.svh"

module Fast_Fourier_Correlation_tb
#(
    parameter int N1,
    parameter int N2,
    parameter int NFFT,
    parameter int IFFT_SHIFT,
    parameter int CORR_NUMB
)();

int file_IDs[20]; 

bit aclk = 0;
bit aresetn = 0;
bit start = 0;

bit idle, overflow;

AXIS_intf #(32) axis_f1();
AXIS_intf #(32) axis_f2();
AXIS_intf #(32) axis_out();

Aclk_Aresetn_intf Aclk_Aresetn(aclk, aresetn);

Environment env;
    
// --------------------------------------------------------------------------------------------
// тактовый сигнал
initial forever
    #2 aclk = ~aclk; 

// сигнал сброса
initial 
	#100 aresetn = 1;

// сигнал сброса
initial 
	#200 start = 1;

// открытие файлов для записи
initial begin
    automatic string file_path = find_file_path(`__FILE__);
     
    file_IDs[0] = $fopen({file_path, "../../ip_vectors/", "f1_samp_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[1] = $fopen({file_path, "../../ip_vectors/", "f1_samp_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[2] = $fopen({file_path, "../../ip_vectors/", "f2_samp_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[3] = $fopen({file_path, "../../ip_vectors/", "f2_samp_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");

    file_IDs[4] = $fopen({file_path, "../../ip_vectors/", "f1_extend_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[5] = $fopen({file_path, "../../ip_vectors/", "f1_extend_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[6] = $fopen({file_path, "../../ip_vectors/", "f2_extend_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[7] = $fopen({file_path, "../../ip_vectors/", "f2_extend_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");

    file_IDs[8] = $fopen({file_path, "../../ip_vectors/", "f1_fft_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[9] = $fopen({file_path, "../../ip_vectors/", "f1_fft_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[10] = $fopen({file_path, "../../ip_vectors/", "f2_fft_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[11] = $fopen({file_path, "../../ip_vectors/", "f2_fft_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");

    file_IDs[12] = $fopen({file_path, "../../ip_vectors/", "corr_fft_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[13] = $fopen({file_path, "../../ip_vectors/", "corr_fft_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[14] = $fopen({file_path, "../../ip_vectors/", "corr_time_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");
    file_IDs[15] = $fopen({file_path, "../../ip_vectors/", "corr_time_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "w");

    file_IDs[16] = $fopen({file_path, "../../test_vectors/", "f1_samp_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "r");
    file_IDs[17] = $fopen({file_path, "../../test_vectors/", "f1_samp_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "r");
    file_IDs[18] = $fopen({file_path, "../../test_vectors/", "f2_samp_re_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "r");
    file_IDs[19] = $fopen({file_path, "../../test_vectors/", "f2_samp_im_nfft_", $sformatf("%0d", NFFT), "_f1_", $sformatf("%0d", N1), "_f2_", $sformatf("%0d", N2), "_corrnumb_", $sformatf("%0d", CORR_NUMB), ".txt"}, "r");

end   

// закрытие файлов для записи
final begin
    for (int i = 0; i < 20; i++) 
        $fclose(file_IDs[i]);
end

// тестовое окружение
initial begin
    #150;
    env = new(200, 100);
    env.axis_f1 = axis_f1;
    env.axis_f2 = axis_f2;
    env.axis_corr = axis_out;
    env.aclk_aresetn = Aclk_Aresetn;

    env.trans_numb_f1 = N1;
    env.trans_numb_f2 = N2;
    env.trans_numb_corr = CORR_NUMB;

    env.file_ID_f1_real = file_IDs[16];
    env.file_ID_f1_imag = file_IDs[17];
    env.file_ID_f2_real = file_IDs[18];
    env.file_ID_f2_imag = file_IDs[19];

    env.run();
end

// завершение проекта по тайм-ауту
initial begin 
    #1000_000_000;
    $display("time = %t: Simulation timeout!", $time);
    $finish;
end    

// DUT
Fast_Fourier_Correlation #(NFFT) DUT 
(
    .aclk(aclk),
    .aresetn(aresetn),
    .N1(N1),
    .N2(N2),
    .IFFT_Shift(IFFT_SHIFT),
    .start(start),
    .idle(idle),
    .overflow(overflow),
    .func_1(axis_f1),
    .func_2(axis_f2),
    .corr(axis_out) 
);

// обнаружение переполнений после сдвига в накопителе
property overflow_detector;
    @(posedge aclk) (overflow == 1'b0 || overflow == 1'bx);
endproperty
assert property (overflow_detector) else begin $display("ERROR! Overflow detected!"); $stop; end

// запись результатов в файлы
property write_f1_samp;
    @(posedge aclk) (axis_f1.tvalid && axis_f1.tready) |-> 1'b1;
endproperty
assert property (write_f1_samp) $fdisplay(file_IDs[0], "%f", $itor($signed(axis_f1.tdata[15:0])));
assert property (write_f1_samp) $fdisplay(file_IDs[1], "%f", $itor($signed(axis_f1.tdata[31:16])));

property write_f2_samp;
    @(posedge aclk) (axis_f2.tvalid && axis_f2.tready) |-> 1'b1;
endproperty
assert property (write_f2_samp) $fdisplay(file_IDs[2], "%f", $itor($signed(axis_f2.tdata[15:0])));
assert property (write_f2_samp) $fdisplay(file_IDs[3], "%f", $itor($signed(axis_f2.tdata[31:16])));

property write_f1_extend;
    @(posedge aclk) (DUT.Recv_F1_out.tvalid && DUT.Recv_F1_out.tready) |-> 1'b1;
endproperty
assert property (write_f1_extend) $fdisplay(file_IDs[4], "%f", $itor($signed(DUT.Recv_F1_out.tdata[15:0])));
assert property (write_f1_extend) $fdisplay(file_IDs[5], "%f", $itor($signed(DUT.Recv_F1_out.tdata[31:16])));

property write_f2_extend;
    @(posedge aclk) (DUT.Read_BRAM_out.tvalid && DUT.Read_BRAM_out.tready) |-> 1'b1;
endproperty
assert property (write_f2_extend) $fdisplay(file_IDs[6], "%f", $itor($signed(DUT.Read_BRAM_out.tdata[15:0])));
assert property (write_f2_extend) $fdisplay(file_IDs[7], "%f", $itor($signed(DUT.Read_BRAM_out.tdata[31:16])));

property write_f1_NFFT;
    @(posedge aclk) (DUT.demux_out_2.tvalid && DUT.demux_out_2.tready) |-> 1'b1;
endproperty
assert property (write_f1_NFFT) $fdisplay(file_IDs[8], "%f", $itor($signed(DUT.demux_out_2.tdata[15:0])));
assert property (write_f1_NFFT) $fdisplay(file_IDs[9], "%f", $itor($signed(DUT.demux_out_2.tdata[31:16])));

property write_f2_NFFT;
    @(posedge aclk) (DUT.demux_out_3.tvalid && DUT.demux_out_3.tready) |-> 1'b1;
endproperty
assert property (write_f2_NFFT) $fdisplay(file_IDs[10], "%f", $itor($signed(DUT.demux_out_3.tdata[15:0])));
assert property (write_f2_NFFT) $fdisplay(file_IDs[11], "%f", $itor($signed(DUT.demux_out_3.tdata[31:16])));

property write_corr_NFFT;
    @(posedge aclk) (DUT.fifo_2_out.tvalid && DUT.fifo_2_out.tready) |-> 1'b1;
endproperty
assert property (write_corr_NFFT) $fdisplay(file_IDs[12], "%f", $itor($signed(DUT.fifo_2_out.tdata[15:0])));
assert property (write_corr_NFFT) $fdisplay(file_IDs[13], "%f", $itor($signed(DUT.fifo_2_out.tdata[31:16])));

property write_corr;
    @(posedge aclk) (axis_out.tvalid && axis_out.tready) |-> 1'b1;
endproperty
assert property (write_corr) $fdisplay(file_IDs[14], "%f", $itor($signed(axis_out.tdata[15:0])));
assert property (write_corr) $fdisplay(file_IDs[15], "%f", $itor($signed(axis_out.tdata[31:16])));

endmodule
