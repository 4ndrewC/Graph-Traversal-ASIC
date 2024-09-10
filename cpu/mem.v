`include "fmt.v"


/*
What to query from memory per fetch?
- Instruction at PC
- Execution parameters
    - immediate
    - data in memory[immedate]
*/


module mem(
    input re, 
    input we, 
    input signed [`WORD-1:0] data_in, 
    input signed [`WORD-1:0] data_in2,
    output reg signed [`WORD-1:0] data_out, 
    output reg [`WORD-1:0]instr,
    input [`WORD-1:0] read_addr,
    input [`WORD-1:0] write_addr,
    input [`WORD-1:0] write_addr2, 
    input [`WORD-1:0] fetch_addr,
    output reg signed [`WORD-1:0] imm,
    output reg signed [`WORD-1:0] imm2, 
    output reg signed [`WORD-1:0] edge_weight,
    input [`WORD-1:0] rn_in,
    input [`WORD-1:0] sp,
    output reg [`WORD-1:0] sp_node,
    input fetch,
    input write_back_en,
    input write_back_en2,
    input clk
);

    reg signed [`WORD-1:0] memory [`MEMSIZE-1:0];

    reg r_success;

    always @(posedge clk) begin
        if(fetch) begin
            instr <= memory[fetch_addr];
            imm = memory[fetch_addr+1];
            imm2 <= memory[fetch_addr+2];
            data_out <= memory[memory[fetch_addr+1]];
            sp_node <= memory[sp];
            $display("fetching weight from location %32b", rn_in[29:15]*`NODES + rn_in[14:0] + `NODES);
            $display("weight %32b", memory[rn_in[29:15]*`NODES + rn_in[14:0] + `NODES]);
            $display("fetching stack pointer node %32b from %32b", memory[sp], sp);
            edge_weight = memory[rn_in[29:15]*`NODES + rn_in[14:0] + `NODES];
            // $display("memory fetch data: %16b", data_out);
        end
        if(write_back_en) begin
            $display("\n<<<memory write back enabled>>>");
            $display("writing %32b into location %32b\n", data_in, write_addr);
            memory[write_addr] <= data_in;
        end
        if(write_back_en2) begin
            $display("\n<<<secondary memory write back enabled>>>");
            $display("writing %32b into location %32b\n", data_in2, write_addr2);
            memory[write_addr2] <= data_in2;
        end
    end

    reg [`WORD-1:0] i;
    //testing
    initial begin
        //LDI test
        // memory[0] <= 16'b0110011000000000;
        // memory[1] <= 16'b0000000000000001;
        // // LDW test
        // memory[2] <= 16'b0111011000000000;
        // memory[3] <= 16'b0000000000001000;
        // // LDA test
        // memory[4] <= 16'b0110110000000000;
        // memory[5] <= 16'b0000000000001000;
        // // RJMP test
        // memory[6] <= 16'b1000000000000000;
        // memory[7] <= 16'b0000000000000011;

        // // // JMP test
        // // memory[6] <= 16'b0111100000000000;
        // // memory[7] <= 16'b0000000000001001;
    
        // // LDI
        // memory[9] <= 16'b0110010100000000;
        // memory[10] <= 16'b0000000000001110;

        // // MOV
        // memory[11] <= 16'b1001001010100000;

        // ADDI
        // memory[2] <= 16'b0000111000000000;
        // memory[3] <= 16'b0000000000000011;
        i = 0;
        for(i=0;i<`MEMSIZE;i=i+1) begin
            memory[i]=32'b0;
        end
        $readmemb("input.txt", memory);
        
    end

endmodule
