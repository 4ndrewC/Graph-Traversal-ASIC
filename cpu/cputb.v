`timescale 1ns/1ns
`include "cpu.v"


module cputb;

    reg clk;
    reg [`WORD-1:0] cycles;
    reg [`WORD-1:0] PC;

    cpu uut(clk, cycles);

    always begin 
        clk = ~clk; #1;
    end

    always begin cycles = cycles + 1; #2; end


    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0, cputb);

        $display("\nSIMULATION BEGIN\n\n");
        
        cycles <= 0;
        clk <= 1'b1;
        PC <= 0;

        #240;
        
        $finish;
    end;


endmodule
