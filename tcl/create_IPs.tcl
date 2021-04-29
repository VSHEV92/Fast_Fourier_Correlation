# ------------------------------------------------------
# -------- Cкрипт для создания IP-ядер Xilinx ----------
# ------------------------------------------------------

# если папка уже существует удаляем её
if { [file exists IPs] != 0 } { 
	file delete -force IPs
	file mkdir IPs
} else {
    file mkdir IPs
}

# возможные длины преобразования Фурье
set NFFT_list [list 128 256 512 1024 2048 4096 8192]

# создания ядра комплексного умножителя
create_ip -name cmpy -vendor xilinx.com -library ip -version 6.0 -module_name complex_mult -dir ./IPs
set_property -dict [list CONFIG.FlowControl {Blocking} CONFIG.ARESETN {true} CONFIG.MinimumLatency {9}] [get_ips complex_mult]
generate_target {instantiation_template} [get_files ./IPs/complex_mult/complex_mult.xci]
generate_target {simulation} [get_files ./IPs/complex_mult/complex_mult.xci]


# создание ядер BRAM
foreach NFFT $NFFT_list {
    set BRAM_Mem_Name BRAM_Mem_${NFFT}
    create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name $BRAM_Mem_Name -dir ./IPs
    set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Assume_Synchronous_Clk {true} CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A [expr $NFFT/2] CONFIG.Read_Width_A {32} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Operating_Mode_B {READ_FIRST} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips $BRAM_Mem_Name]
    generate_target {instantiation_template} [get_files ./IPs/${BRAM_Mem_Name}/${BRAM_Mem_Name}.xci]
    generate_target {simulation} [get_files ./IPs/${BRAM_Mem_Name}/${BRAM_Mem_Name}.xci]
}

# создание ядер FIFO_1
foreach NFFT $NFFT_list {
    set FIFI_1_Name FIFO_1_${NFFT}
    create_ip -name axis_data_fifo -vendor xilinx.com -library ip -version 2.0 -module_name $FIFI_1_Name -dir ./IPs
    set_property -dict [list CONFIG.TDATA_NUM_BYTES {4} CONFIG.FIFO_DEPTH $NFFT] [get_ips $FIFI_1_Name]
    generate_target {instantiation_template} [get_files ./IPs/${FIFI_1_Name}/${FIFI_1_Name}.xci]
    generate_target {simulation} [get_files ./IPs/${FIFI_1_Name}/${FIFI_1_Name}.xci]
}

# создание ядер FIFO_2
foreach NFFT $NFFT_list {
    set FIFI_2_Name FIFO_2_${NFFT}
    create_ip -name axis_data_fifo -vendor xilinx.com -library ip -version 2.0 -module_name $FIFI_2_Name -dir ./IPs
    set_property -dict [list CONFIG.TDATA_NUM_BYTES {4} CONFIG.FIFO_DEPTH $NFFT] [get_ips $FIFI_2_Name]
    generate_target {instantiation_template} [get_files ./IPs/${FIFI_2_Name}/${FIFI_2_Name}.xci]
    generate_target {simulation} [get_files ./IPs/${FIFI_2_Name}/${FIFI_2_Name}.xci]
}

# создание ядер FFT
foreach NFFT $NFFT_list {
    set FFT_Name FFT_${NFFT}
    create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name $FFT_Name -dir ./IPs
    set_property -dict [list CONFIG.transform_length $NFFT CONFIG.implementation_options {radix_2_lite_burst_io} CONFIG.scaling_options {block_floating_point} CONFIG.aresetn {true} CONFIG.output_ordering {natural_order} CONFIG.butterfly_type {use_xtremedsp_slices} CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {0}] [get_ips $FFT_Name]
    generate_target {instantiation_template} [get_files ./IPs/${FFT_Name}/${FFT_Name}.xci]
    generate_target {simulation} [get_files ./IPs/${FFT_Name}/${FFT_Name}.xci]
}