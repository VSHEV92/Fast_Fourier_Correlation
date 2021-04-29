%%% ----------------------------------------------------------
%%% ------- ������ �������� ������ ������������� ���� --------
%%% ----------------------------------------------------------

clc
clear

%%% -------------------------------------
%%% �������� ����� ����� ��� ����������� �������� ��������
if exist('../ip_vectors', 'dir')    
    rmdir '../ip_vectors' s
    mkdir('../ip_vectors')
else
    mkdir('../ip_vectors')
end

%%% ��������� �������� �������� �� ���������
mult_values = 5;
shift_vectors(mult_values)

function shift_vectors(mult_values)
    %%% �������� ����� ������
    files = dir('../test_vectors/');
    for k = 1:length(files)-2
        test_name = files(2+k).name;
        data = dlmread(strcat('../test_vectors/', test_name));
        data = data.*mult_values;
        dlmwrite(strcat('../ip_vectors/', test_name), data, 'newline', 'pc', '-append');
    end
end