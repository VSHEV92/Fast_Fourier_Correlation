// ---------------------------------------------------
// --------------  Блок умножения и сдвига  ----------
// ---------------------------------------------------

module Mult_Shift 
(
    input  logic aclk,
    input  logic aresetn,
    input  logic [3:0] IFFT_Shift,
    
    AXIS_intf.Slave indata_1,
    AXIS_intf.Slave indata_2,
    AXIS_intf.Master outdata,

    output logic overflow 
);

    // ---------------------------------------------------------------------------------------------
    localparam logic signed [32:0] MAX_VALUE = 2**32 - 1;
    localparam logic signed [32:0] MIN_VALUE = -2**32;

    // функция обработки округления и переполнения
    function logic signed [15:0] trunc_and_satur (input logic signed [49:0] in_value);
         logic signed [15:0] out_value;

        if (in_value > MAX_VALUE)
            out_value = MAX_VALUE;
        else if (in_value < MIN_VALUE)
            out_value = MIN_VALUE;
        else   
            out_value = in_value[32:17];
        
        return out_value;
    endfunction

    // функция обнаружения переполнения
    function logic get_overflow (input logic signed [49:0] in_value);
        if ( (in_value > MAX_VALUE) || (in_value < MIN_VALUE))
            return 1'b1;
        else 
            return 1'b0;
    endfunction 

    // ---------------------------------------------------------------------------------------------
    logic [79:0] mult_out;
    logic mult_out_valid;

    logic signed [49:0] extened_mult_re;
    logic signed [49:0] extened_mult_im;

    logic signed [49:0] shifted_mult_re;
    logic signed [49:0] shifted_mult_im;
    
    // ---------------------------------------------------------------------------------------------
    // экземпляр комплексного умножителя 
    complex_mult complex_mult_inst (
        .aclk(aclk),                              
        .aresetn(aresetn),                        
        .s_axis_a_tvalid(indata_1.tvalid),        
        .s_axis_a_tready(indata_1.tready),        
        .s_axis_a_tdata(indata_1.tdata),          
        .s_axis_b_tvalid(indata_2.tvalid),        
        .s_axis_b_tready(indata_2.tready),        
        .s_axis_b_tdata(indata_2.tdata),          
        .m_axis_dout_tvalid(mult_out_valid),  
        .m_axis_dout_tready(1'b1),  
        .m_axis_dout_tdata(mult_out)    
    );

    // расширение сигналов с выхода умножителя
    assign extened_mult_re = 50'(signed'(mult_out[39:0]));
    assign extened_mult_im = 50'(signed'(mult_out[79:40]));

    // сдвиг сигналов на заданное число бит
    assign shifted_mult_re = extened_mult_re << IFFT_Shift;
    assign shifted_mult_im = extened_mult_im << IFFT_Shift;

    // формирование выходных сигналов
    always_ff @(posedge aclk)
        if (!aresetn)
            outdata.tdata <= 0;
        else 
           outdata.tdata <= {trunc_and_satur(shifted_mult_im), trunc_and_satur(shifted_mult_re)};

    always_ff @(posedge aclk)
        if (!aresetn)
           overflow <= 0;
        else 
           overflow <= get_overflow(shifted_mult_im) | get_overflow(shifted_mult_re);       

    always_ff @(posedge aclk)
        if (!aresetn)
           outdata.tvalid <= 0;
        else 
           outdata.tvalid <= mult_out_valid;   

endmodule