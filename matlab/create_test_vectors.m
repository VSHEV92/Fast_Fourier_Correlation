%%% ----------------------------------------------------------
%%% ----- Скрипт создания входных и референсных векторов -----
%%% ----------------------------------------------------------

clc
clear

%%% -------------------------------------
%%% создание новой папки для тестовых векторов
if exist('../test_vectors', 'dir')    
    rmdir '../test_vectors' s
    mkdir('../test_vectors')
else
    mkdir('../test_vectors')
end

if exist('../tcl/test_params', 'dir')    
    rmdir '../tcl/test_params' s
    mkdir('../tcl/test_params')
else
    mkdir('../tcl/test_params')
end


%%% -------------------------------------------------------------------
F1_samples_numb = [12 45 64 46 82 128 75 161 256 398 512 988 1024 1935 2048 3953 4096];
F2_samples_numb = [8 34 64 35 70 128 67 130 256 253 512 799 1024 1689 2048 2646 4096];
correlations_numb = [10 10 10 10 10 10 6 6 6 6 6 4 4 3 3 3 3];
NFFT = [128 128 128 256 256 256 512 512 512 1024 1024 2048 2048 4096 4096 8192 8192];

%%% -------------------------------------
%%% создание тестового набора
for k = 1:length(F1_samples_numb)
    vector_name = strcat('_nfft_', num2str(NFFT(k)), '_f1_', num2str(F1_samples_numb(k)),'_f2_', num2str(F2_samples_numb(k)), '_corrnumb_', num2str(correlations_numb(k)));
    create_test_vectors_func(vector_name, NFFT(k), F1_samples_numb(k), F2_samples_numb(k), correlations_numb(k));
    create_tcl_file_func(vector_name, NFFT(k), F1_samples_numb(k), F2_samples_numb(k), correlations_numb(k));
    fprintf('Test nfft_%d_f1_%d_f2_%d_corrnumb_%d generated \n', NFFT(k), F1_samples_numb(k), F2_samples_numb(k), correlations_numb(k));
end


%%% -------------------------------------
%%% скрипт для создания тестовых векторов
function create_test_vectors_func(vector_name, NFFT, F1_samples_numb, F2_samples_numb, correlations_numb)
  
    for k = 1:correlations_numb
           %%% создание отсчетов для функции F1
           F1_samples_re = filter(ones(1,5), 1, rand(1, F1_samples_numb)-0.5);
           F1_samples_im = filter(ones(1,5), 1, rand(1, F1_samples_numb)-0.5);
           F1_samples = F1_samples_re + i .* F1_samples_im;
           F1_samples = F1_samples.*7.*10^3;
           dlmwrite(strcat('../test_vectors/', 'f1_samp_re', vector_name, '.txt'), real(F1_samples)', 'newline', 'pc', '-append');
           dlmwrite(strcat('../test_vectors/', 'f1_samp_im', vector_name, '.txt'), imag(F1_samples)', 'newline', 'pc', '-append');

           %%% создание отсчетов для функции F2
           rand_shift = ceil(rand*F2_samples_numb*0.3);
           F2_samples = [zeros(1,rand_shift) F1_samples(1:F2_samples_numb-rand_shift)];
           dlmwrite(strcat('../test_vectors/', 'f2_samp_re', vector_name, '.txt'), real(F2_samples)', 'newline', 'pc', '-append');
           dlmwrite(strcat('../test_vectors/', 'f2_samp_im', vector_name, '.txt'), imag(F2_samples)', 'newline', 'pc', '-append');

           %%% дополнение f1 нулями
           F1_extend = zeros(1, NFFT);
           F1_extend(1:F1_samples_numb) = F1_samples;
           dlmwrite(strcat('../test_vectors/', 'f1_extend_re', vector_name, '.txt'), real(F1_extend)', 'newline', 'pc', '-append');
           dlmwrite(strcat('../test_vectors/', 'f1_extend_im', vector_name, '.txt'), imag(F1_extend)', 'newline', 'pc', '-append');

           %%% дополнение f2 нулями и сопряжение
           F2_extend = zeros(1, NFFT);
           F2_extend(1:F2_samples_numb) = fliplr(conj(F2_samples));
           dlmwrite(strcat('../test_vectors/', 'f2_extend_re', vector_name, '.txt'), real(F2_extend)', 'newline', 'pc', '-append');
           dlmwrite(strcat('../test_vectors/', 'f2_extend_im', vector_name, '.txt'), imag(F2_extend)', 'newline', 'pc', '-append');
           
           %%% преобразование фурье от f1
           F1_FFT = fft(F1_extend);
           dlmwrite(strcat('../test_vectors/', 'f1_fft_re', vector_name, '.txt'), real(F1_FFT)', 'newline', 'pc', '-append');
           dlmwrite(strcat('../test_vectors/', 'f1_fft_im', vector_name, '.txt'), imag(F1_FFT)', 'newline', 'pc', '-append');
           
           %%% преобразование фурье от f2
           F2_FFT = fft(F2_extend);
           dlmwrite(strcat('../test_vectors/', 'f2_fft_re', vector_name, '.txt'), real(F2_FFT)', 'newline', 'pc', '-append');
           dlmwrite(strcat('../test_vectors/', 'f2_fft_im', vector_name, '.txt'), imag(F2_FFT)', 'newline', 'pc', '-append');

           %%% произведение спектров
           Corr_FFT = F1_FFT.*F2_FFT;
           dlmwrite(strcat('../test_vectors/', 'corr_fft_re', vector_name, '.txt'), real(Corr_FFT)', 'newline', 'pc', '-append');
           dlmwrite(strcat('../test_vectors/', 'corr_fft_im', vector_name, '.txt'), imag(Corr_FFT)', 'newline', 'pc', '-append');

           %%% корреляционная функция
           Corr = ifft(Corr_FFT);
           Corr = Corr(1:F1_samples_numb+F2_samples_numb-1);
           dlmwrite(strcat('../test_vectors/', 'corr_time_re', vector_name, '.txt'), real(Corr)', 'newline', 'pc', '-append');
           dlmwrite(strcat('../test_vectors/', 'corr_time_im', vector_name, '.txt'), imag(Corr)', 'newline', 'pc', '-append');
    end
end

%%% ----------------------------------------
%%% создание набора tcl файлов с параметрами 
function create_tcl_file_func(vector_name, NFFT, F1_samples_numb, F2_samples_numb, correlations_numb)
    fileID = fopen(strcat('../tcl/test_params/', vector_name, '.tcl'),'w');
    
    switch NFFT
        case 128
            IFFT_SHIFT = 1;
        case 256
            IFFT_SHIFT = 1;
        case 512
            IFFT_SHIFT = 2;
        case 1024
            IFFT_SHIFT = 2;
        case 2048
            IFFT_SHIFT = 2;
        case 4096
            IFFT_SHIFT = 2;    
        case 8192
            IFFT_SHIFT = 2;    
    end
    
    fprintf(fileID,'set IFFT_SHIFT %d\n', IFFT_SHIFT);
    fprintf(fileID,'set NFFT %d\n', NFFT);
    fprintf(fileID,'set N1 %d\n', F1_samples_numb);
    fprintf(fileID,'set N2 %d\n', F2_samples_numb);
    fprintf(fileID,'set CORRS %d\n', correlations_numb);
    fclose(fileID);
end
