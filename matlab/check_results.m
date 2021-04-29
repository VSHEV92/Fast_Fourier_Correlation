%%% ----------------------------------------------------------
%%% ------- —крипт имитации данных моделировани€ €дра --------
%%% ----------------------------------------------------------

clc
clear

%%% автоматическа€ проверка результатов
epsilon = 10^-2; %% максимальна€ ошибка
error = check_vectors(epsilon);

%%% вывод рузультата верификации
if error == 1
    disp('VERIFICATION FAIL')
else
    disp('VERIFICATION PASS')
end

%%% функци€ дл€ автоматической проверки результатов
function result = check_vectors(epsilon)

    error_flag = 0;
    pass_counter = 0;
    fail_counter = 0;
    %%% сравнение результатов
    result_files = dir('../ip_vectors/');

    for k = 1:length(result_files)-2
        %%% считывание файлов
        result_name = result_files(2+k).name;
        
        %%% находим входные параметры 
        nfft_idx = strfind(result_name, '_nfft_');
        f1_idx = strfind(result_name, '_f1_');
        f2_idx = strfind(result_name, '_f2_');
        corrnumb_idx = strfind(result_name, '_corrnumb_');
        NFFT = str2num(result_name(nfft_idx+6:f1_idx-1)); 
        N1 = str2num(result_name(f1_idx+4:f2_idx-1));
        N2 = str2num(result_name(f2_idx+4:corrnumb_idx-1));
        corrnumb = str2num(result_name(corrnumb_idx+10:length(result_name)-4));
        
        %%% определение длины вектора дл€ одной коррел€ции
        if (contains(result_name, 'f1_samp'))
            vector_len = N1;
        elseif (contains(result_name, 'f2_samp'))
            vector_len = N2;
        elseif (contains(result_name, 'corr_time'))
            vector_len = N1+N2-1;
        else    
            vector_len = NFFT;
        end
        
        test_data = dlmread(strcat('../test_vectors/', result_name));
        result_data = dlmread(strcat('../ip_vectors/', result_name));
        
        for n = 1:corrnumb
            test_vector = test_data(1+(n-1)*vector_len:n*vector_len);
            result_vector = result_data(1+(n-1)*vector_len:n*vector_len);
            
            %%% нормировка
            test_vector = test_vector./sqrt(sum(abs(test_vector).^2));
            result_vector = result_vector./sqrt(sum(abs(result_vector).^2));
            error = sum(abs(result_vector - test_vector));
            
            %%% вывод результата
            if error < epsilon
                pass_counter = pass_counter + 1;
            else
                fprintf('Result: FAIL; \t Error: %8.5f \tVector: %s \tCorr Number: %d \n', error, result_name, n);
                fail_counter = fail_counter + 1;
                error_flag = 1;
            end
        end
    end

    result = error_flag;
    fprintf('Vectors passed: %d \n', pass_counter);
    fprintf('Vectors failed: %d \n', fail_counter);
end