// ---------------------------------------------------
// функция для поиска пути расположения тестового файла
function automatic string find_file_path(input string file_full_name);
    int str_len = file_full_name.len();
    str_len--;
    while (file_full_name.getc(str_len) != "/") begin
        str_len--;
    end
    return file_full_name.substr(0, str_len); 
endfunction

// ---------------------------------------------------
// -----------------  Транзакция  --------------------
// ---------------------------------------------------
class Transaction;

    rand logic [31:0] data;
    int unsigned count;

    // выдача данных транзакции
    function logic [31:0] get_data();
        return data;        
    endfunction

    // выдача номера транзакции
    function int unsigned get_count();
        return count;        
    endfunction

    // запись данных транзакции
    function void set_data(logic [31:0] data);
        this.data = data;        
    endfunction

    // запись номера транзакций
    function void set_count(int count);
        this.count = count;    
    endfunction    
    
    // запись в лог 
    function void print(string tag="");
        $display("%s: time = %t, transaction number = %0d, value = %h", tag, $time, count, data);
    endfunction

endclass

// ---------------------------------------------------
// --------------  Генератор данных  -----------------
// ---------------------------------------------------
class Generator;

    int unsigned delay;     // случайная задержка генератор
    int gen_max_delay_ns;   // максимальная задержка генератора в нс
    Transaction trans;
    
    int file_ID_real;
    int file_ID_imag;
    
    mailbox mb_driver;
    mailbox mb_scoreboard;
    
    //конструктор класс
    function new(int gen_max_delay_ns);
        this.gen_max_delay_ns = gen_max_delay_ns;
    endfunction

    // передача случайных данных в mailbox
    task send_data_to_mb(int count);
        bit [15:0] data_r;
        bit [15:0] data_i; 
        string line;
        
        trans = new;
        $fgets(line, file_ID_real);
        data_r = $rtoi(line.atoreal());
        $fgets(line, file_ID_imag);
        data_i = $rtoi(line.atoreal());

        trans.set_data({data_i, data_r});
        trans.set_count(count);
        delay = $urandom_range(0, gen_max_delay_ns);
        # delay; // случайная задержка
        mb_driver.put(trans);
        mb_scoreboard.put(trans);
        trans.print("Generator");      
    endtask

    // создать заданное число транзакций
    task run(input int trans_numb);
        for (int count = 1; count <= trans_numb; count++)
            send_data_to_mb(count);    
        $display("Generator Done.");    
    endtask

endclass    

// ---------------------------------------------------
// ------------------  Драйвер  ----------------------
// ---------------------------------------------------
class Driver;

    mailbox mb_driver;
    Transaction trans;
    virtual AXIS_intf #(32) axis;
    virtual Aclk_Aresetn_intf aclk_aresetn;
    
    //конструктор класс
    function new();
        trans = new;
    endfunction

    // принимает данные из mailbox и передает их по axis  
    task run(int trans_numb);
        bit have_data = 0;
        int count = 0;
        forever begin
            wait (aclk_aresetn.aresetn);

            @(posedge aclk_aresetn.aclk)
            if (!(axis.tvalid  && !axis.tready)) begin
                if(mb_driver.try_get(trans)) begin
                    axis.tvalid <= 1'b1;
                    axis.tdata <= trans.get_data();
                    trans.print("Driver");
                end else
                    axis.tvalid <= 1'b0;
                if(axis.tready && axis.tvalid) begin
                    count++;  // увеличение счетчика переданных данных
                    if (count == trans_numb) // завершение работы драйвера
                        break;   
                end
            end       
        end
        axis.tvalid <= 1'b0;
        $display("Driver Done.");        
    endtask

endclass


// ---------------------------------------------------
// ------------------  Монитор  ----------------------
// ---------------------------------------------------
class Monitor;

    mailbox mb_monitor;
    Transaction trans;
    virtual AXIS_intf #(32) axis;
    virtual Aclk_Aresetn_intf aclk_aresetn;

    int unsigned delay;     // случайная задержка монитора
    int mon_max_delay_ns;   // максимальная задержка монитора в нс
    
    //конструктор класс
    function new(int mon_max_delay_ns);
        this.mon_max_delay_ns = mon_max_delay_ns;
    endfunction

    // принимает данные из mailbox и передает их по axis  
    task run(int trans_numb);
        int count = 0;
        forever begin
            wait (aclk_aresetn.aresetn);
            @(posedge aclk_aresetn.aclk)
            if(!axis.tready) 
                axis.tready <= 1;    
            // если данные валидны, скадем их в mailbox
            else if(axis.tvalid) begin
                axis.tready <= 0;
                count++;
                trans = new;
                trans.set_data(axis.tdata);
                trans.set_count(count);
                trans.print("Monitor");
                delay = $urandom_range(0, mon_max_delay_ns);
                # delay; // случайная задержка
                mb_monitor.put(trans);
                if (count == trans_numb) // завершение работы драйвера
                    break;   
            end           
        end
        axis.tready <= 1'b0;
        $display("Monitor Done.");
    endtask

endclass

// ---------------------------------------------------
// ------------  Вычисление результата  --------------
// ---------------------------------------------------
class Scoreboard;

    mailbox mb_monitor;
    mailbox mb_driver_f1;
    mailbox mb_driver_f2;
    
    Transaction monintor_trans;
    Transaction driver_f1_trans;
    Transaction driver_f2_trans;
    
    //конструктор класс
    function new();
        monintor_trans = new;
        driver_f1_trans = new;
        driver_f2_trans = new;
    endfunction

    // принимает данные из mailbox и передает их по axis  
    task run(int trans_numb_f1, int trans_numb_f2, int trans_numb_corr);
        fork
            repeat(trans_numb_corr * (trans_numb_f1+trans_numb_f2-1)) begin
                mb_monitor.get(monintor_trans);
                monintor_trans.print("Score Monitor");
            end

            repeat(trans_numb_f1*trans_numb_corr) begin    
                mb_driver_f1.get(driver_f1_trans);
                driver_f1_trans.print("Score Driver F1");
            end
            
            repeat(trans_numb_f2*trans_numb_corr) begin    
                mb_driver_f2.get(driver_f2_trans);
                driver_f2_trans.print("Score Driver F2");
            end
        join

        $display("Scoreboard Done.");        
    endtask

endclass

// ---------------------------------------------------
// ------------  Тестовое окружение  -----------------
// ---------------------------------------------------
class Environment;

    int trans_numb_f1;   // число транзакций F1
    int trans_numb_f2;   // число транзакций F2
    int trans_numb_corr;   // число транзакций корреляционной функции

    Generator gen_f1;
    Driver dr_f1;
    Generator gen_f2;
    Driver dr_f2;
    Monitor mon;
    Scoreboard score;

    int file_ID_f1_real;
    int file_ID_f1_imag;
    int file_ID_f2_real;
    int file_ID_f2_imag;

    mailbox mb_driver_f1;
    mailbox mb_driver_f2;
    mailbox mb_scoreboard_f1;
    mailbox mb_scoreboard_f2;
    mailbox mb_monitor;

    virtual AXIS_intf #(32) axis_f1;
    virtual AXIS_intf #(32) axis_f2;
    virtual AXIS_intf #(32) axis_corr;
    virtual Aclk_Aresetn_intf aclk_aresetn;

    // конструктор класса
    function new (int gen_max_delay_ns, int mon_max_delay_ns);
        mb_driver_f1 = new();
        mb_driver_f2 = new();
        mb_scoreboard_f1 = new();
        mb_scoreboard_f2 = new();
        mb_monitor = new();
        gen_f1 = new(gen_max_delay_ns);
        dr_f1 = new();
        gen_f2 = new(gen_max_delay_ns);
        dr_f2 = new();
        mon = new(mon_max_delay_ns);
        score = new();
    endfunction 

    // запуск тестового окружения
    task run();
        
        gen_f1.mb_driver = mb_driver_f1;
        gen_f1.mb_scoreboard = mb_scoreboard_f1;
        gen_f1.file_ID_real = file_ID_f1_real;
        gen_f1.file_ID_imag = file_ID_f1_imag;

        gen_f2.mb_driver = mb_driver_f2;
        gen_f2.mb_scoreboard = mb_scoreboard_f2;
        gen_f2.file_ID_real = file_ID_f2_real;
        gen_f2.file_ID_imag = file_ID_f2_imag;

        dr_f1.axis = axis_f1;
        dr_f1.aclk_aresetn = aclk_aresetn;
        dr_f1.mb_driver = mb_driver_f1;

        dr_f2.axis = axis_f2;
        dr_f2.aclk_aresetn = aclk_aresetn;
        dr_f2.mb_driver = mb_driver_f2;
           
        mon.axis = axis_corr;
        mon.mb_monitor = mb_monitor;
        mon.aclk_aresetn = aclk_aresetn;

        score.mb_monitor = mb_monitor;
        score.mb_driver_f1 = mb_scoreboard_f1;
        score.mb_driver_f2 = mb_scoreboard_f2;

        fork
            gen_f1.run(trans_numb_f1*trans_numb_corr);
            gen_f2.run(trans_numb_f2*trans_numb_corr);
            dr_f1.run(trans_numb_f1*trans_numb_corr);
            dr_f2.run(trans_numb_f2*trans_numb_corr);
            mon.run((trans_numb_f1+trans_numb_f2-1) * trans_numb_corr);
        join
        
        //score.run(trans_numb_f1, trans_numb_f2, trans_numb_corr); 
        
        $finish;
       
    endtask
endclass


