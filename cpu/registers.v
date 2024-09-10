`include "fmt.v"

/*
What to query from registers per fetch?
- Execution parameters
    - reg1_code
    - reg2_code
    - reg1_val
    - reg2_val
*/

module registers(
    input re, 
    input we, 
    input [2:0] reg1,
    input [2:0] reg2,
    input [2:0] reg_write_code,
    input signed [`WORD-1:0] data_in, 
    output reg signed [`WORD-1:0] data_out1, 
    output reg signed [`WORD-1:0] data_out2,
    output reg signed [`WORD-1:0] SREG_read,
    input signed [`WORD-1:0] SREG_write, 
    input sp_write_tr,
    input [`WORD-1:0] sp_write,
    output reg [`WORD-1:0] sp_read,
    input rn_write_tr,
    input [`WORD-1:0] rn_write,
    output reg [`WORD-1:0] rn_read,
    input get_reg_en,
    input reg_write_back,
    input flag_update,
    input clk
);

    reg signed [`WORD-1:0] registers[`REGISTERS-1:0];

    reg [`WORD-1:0] disptemp;
    reg w_success;

    always @(posedge clk) begin
        if(get_reg_en) begin
            $display("REGISTER DATA FETCH");
            data_out1 = registers[reg1];
            data_out2 = registers[reg2];
            SREG_read = registers[`SREG];
            rn_read = registers[`rn];
            sp_read = registers[`sp];
            $display("status flag: %32b", registers[`SREG]);
            $display("register %3b data: %32b", reg1, data_out1);
            $display("register %3b data: %32b\n", reg2, data_out2);
        end
        if(reg_write_back) begin
            $display("\n<<<register write back enabled>>>");
            registers[reg_write_code] = data_in;
            $display("writing %32b into register %3b\n", data_in, reg_write_code);
        end
        if(sp_write_tr) begin
            $display("\n<<<updating stack pointer>>>");
            registers[`sp] = sp_write;
            $display("writing %32b into stack pointer\n", sp_write);
        end
        if(rn_write_tr) begin
            $display("\n<<<updating node register>>>");
            registers[`rn] = rn_write;
            $display("writing %32b into node register\n", rn_write);
        end
        // if(flag_update) begin
        //     registers[`SREG] = SREG_write;
        //     $display("writing into status flag: %16b", SREG_write);
        // end
    end

    // always @(posedge reg_write_done) begin
    //     $display("register inputted: %16b", registers[reg_write_code]);
    // end

    initial begin
        registers[`rn][30] = 1'b0;
        registers[`sp] = `STACK_OFFSET;
    end

endmodule
