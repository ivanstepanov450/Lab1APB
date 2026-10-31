`timescale 1ns/1ps
module tb;
    logic pclk, presetn, start, done;

    top DUT (
        .pclk(pclk), .presetn(presetn),
        .start(start), .done(done)
    );

    always #10 pclk = ~pclk;

    initial begin
        pclk = 0; presetn = 0; start = 0;
        
        // Сброс
        repeat(5) @(posedge pclk);
        @(negedge pclk) presetn = 1;
        repeat(2) @(posedge pclk);
        
        // Запуск теста
        @(negedge pclk) start = 1;
        @(negedge pclk) start = 0;

        // Ждем окончания
        wait(done == 1'b1);
        @(posedge pclk);
        $finish;
    end
endmodule