# ------------------------------------------------------
# ---- Cкрипт для автоматического создания проекта -----
# ------------------------------------------------------

# -----------------------------------------------------------
set Project_Name Fast_Fourier_Correlation_Project

# если проект с таким именем существует удаляем его
close_project -quiet
if { [file exists $Project_Name] != 0 } { 
	file delete -force $Project_Name
}

# создаем проект
create_project $Project_Name ./$Project_Name -part xcku060-ffva1156-2-e

# настройка IP-cache
config_ip_cache -import_from_project -use_cache_location ./IPs_cache

# создание IP-ядре Xilinx
if { [file exists IPs] != 0 } { 
	set pattern ./IPs/*/*.xci
	add_files [glob -nocomplain -- $pattern]
} else {
    source ./tcl/create_IPs.tcl
}

# добавляем исходники к проекту
#add_files ./hdl/source/*.v
add_files [glob -nocomplain -- ./hdl/source/*.sv]
add_files [glob -nocomplain -- ./hdl/package/*.sv]

# добавляем файлы для тестирования к проекту
add_files ./hdl/tests/Environment.svh
add_files -fileset sim_1 ./hdl/tests/Fast_Fourier_Correlation_tb.sv