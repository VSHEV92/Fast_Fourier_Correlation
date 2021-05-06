# ------------------------------------------------------
# ----- Cкрипт для автоматического запуска тестов ------
# ------------------------------------------------------

# удаляем старые результаты моделирования
set ip_vectors_dir ip_vectors
if { [file exists $ip_vectors_dir] != 0 } { 
	file delete -force $ip_vectors_dir
    file mkdir $ip_vectors_dir
} else {
    file mkdir $ip_vectors_dir
}

# создаем проект
source ./tcl/create_project.tcl

# обновляем иерархию файлов проекта
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# создаем список тестов 
set NFFT_128_tests [glob -nocomplain -path ./tcl/test_params/ _nfft_128_*]
set NFFT_256_tests [glob -nocomplain -path ./tcl/test_params/ _nfft_256_*]
set NFFT_512_tests [glob -nocomplain -path ./tcl/test_params/ _nfft_512_*]
set NFFT_1024_tests [glob -nocomplain -path ./tcl/test_params/ _nfft_1024_*]
set NFFT_2048_tests [glob -nocomplain -path ./tcl/test_params/ _nfft_2048_*]
set NFFT_4096_tests [glob -nocomplain -path ./tcl/test_params/ _nfft_4096_*]
set NFFT_8192_tests [glob -nocomplain -path ./tcl/test_params/ _nfft_8192_*]
set tests_list [concat $NFFT_128_tests $NFFT_256_tests $NFFT_512_tests $NFFT_1024_tests $NFFT_2048_tests $NFFT_4096_tests $NFFT_8192_tests]

# создаем файл, куда будут записываться завершенные тесты
set fileID [open Verification_Results.txt w]

# устанавливаем максимальное время моделирования 
set_property -name {xsim.simulate.runtime} -value {100s} -objects [get_filesets sim_1]

# запуск тестов
foreach test $tests_list {
    source ${test}
    set_property generic "IFFT_SHIFT=$IFFT_SHIFT NFFT=$NFFT N1=$N1 N2=$N2 CORR_NUMB=$CORRS" [get_filesets sim_1]
    launch_simulation
	close_sim -quiet
    puts $fileID "Test ${test} done"
} 

close $fileID

