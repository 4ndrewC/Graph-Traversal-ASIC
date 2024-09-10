`include "fmt.v"

module execute(
    input [`OPSIZE-1:0] opcode,
    input [2:0] reg1_code,
    input [2:0] reg2_code,
    input signed [`WORD-1:0] imm,
    input signed [`WORD-1:0] imm2,
    input signed [`WORD-1:0] edge_weight,
    input [`NODE_BITS-1:0] next,
    input [`NODE_BITS-1:0] point,
    input [`WORD-1:0] SREG_in,
    output reg [`WORD-1:0] SREG_out,
    output reg flag_update,
    output reg signed [`WORD-1:0] mem_write_val,
    output reg signed [`WORD-1:0] mem_write_val2,
    output reg [`WORD-1:0] mem_write_addr,
    output reg [`WORD-1:0] mem_write_addr2,
    output reg signed [`WORD-1:0] reg_write_val,
    output reg [2:0] reg_write_code,
    input [`WORD-1:0] node_reg_in,
    output reg [`WORD-1:0] node_reg_out,
    input signed [`WORD-1:0] mem_read_data,
    input signed [`WORD-1:0] reg1_input_data,
    input signed [`WORD-1:0] reg2_input_data,
    output reg [`WORD-1:0] PC_jump_loc,
    output reg [`WORD-1:0] PC_jump_inc,
    input [`WORD-1:0] sp_in,
    output reg [`WORD-1:0] sp_out,
    output reg jump,
    output reg rjump,
    output reg mem_wb,
    output reg mem_wb2,
    output reg reg_wb,
    output reg sp_wb,
    output reg rn_wb,
    input dne_tr,
    input clk
);

    // alu variables
    reg has_imm;
    reg [`WORD-1:0] res;

    reg [`WORD-1:0] execution_cnt;
    reg [`WORD-1:0] visited_addr;
    reg [`WORD-1:0] visited_bit;
    reg [`WORD-1:0] edge_loc;

    initial begin execution_cnt <= 16'b0; end;

    always @(posedge clk) begin
        if(dne_tr) begin
            SREG_out = SREG_in;
            execution_cnt = execution_cnt + 1;
            $display("executing opcode: %6b", opcode);
            // $display("execution count: %0d", execution_cnt);
            reg_wb      = 1'b0;
            mem_wb      = 1'b0;
            mem_wb2     = 1'b0;
            sp_wb       = 1'b0;
            rn_wb       = 1'b0;
            jump        = 1'b0;
            rjump       = 1'b0;
            flag_update = 1'b0;
            
            if(opcode<=6'b001011) begin // ALU instructions
                case (opcode)
                    `ADD: begin res = reg1_input_data+reg2_input_data; has_imm = 1'b0; end
                    `ADDI: begin res = reg1_input_data+imm; has_imm = 1'b1; end
                    `SUB: begin res = reg1_input_data-reg2_input_data; has_imm = 1'b0; end
                    `SUBI: begin res = reg1_input_data-imm; has_imm = 1'b1; end
                    `AND: begin res = reg1_input_data&reg2_input_data; has_imm = 1'b0; end
                    `ANDI: begin res = reg1_input_data&imm; has_imm = 1'b1; end
                    `OR: begin res = reg1_input_data|reg2_input_data; has_imm = 1'b0; end
                    `ORI: begin res = reg1_input_data|imm; has_imm = 1'b1; end
                    `XOR: begin res = reg1_input_data^reg2_input_data; has_imm = 1'b0; end
                    `XORI: begin res = reg1_input_data^imm; has_imm = 1'b1; end
                    `CMP: begin res = reg2_input_data-reg1_input_data; has_imm = 1'b0; end
                    `CMPI: begin res = reg1_input_data-imm; has_imm = 1'b1; end
                    default: begin res = 0; has_imm = 1'b0; end
                endcase

                if(res==0) SREG_out[`Zf] = 1'b1;
                else SREG_out[`Zf] = 1'b0;
                

                if(opcode!=`CMP && opcode!=`CMPI) begin
                    reg_write_code = reg1_code;
                    reg_write_val = res;
                    reg_wb = 1'b1;
                    $display("ALU RES: %0d", res);
                end
                $display("Zero flag: %0d", res==0);
                
                // if(has_imm) begin
                //     PC_jump_inc = 2;
                // end
                // else PC_jump_inc = 1;
                flag_update = 1'b1;
                // rjump = 1'b1;
            end
            else if(opcode>=6'b010100 && opcode<=6'b011110) begin // flag modification instructions
                case (opcode)
                    `CLC: SREG_out[`Cf] = 1'b0;
                    `CLZ: SREG_out[`Zf] = 1'b0;
                    `CLN: SREG_out[`Nf] = 1'b0;
                    // `CLS: SREG_out[`Sf] = 1'b0;
                    `CLI: SREG_out[`If] = 1'b0;
                    `SLC: SREG_out[`Cf] = 1'b1;
                    `SLZ: SREG_out[`Zf] = 1'b1;
                    `SLN: SREG_out[`Nf] = 1'b1;
                    // `SLS: SREG_out[`Sf] = 1'b1;
                    `SLI: SREG_out[`If] = 1'b1;
                endcase
                // rjump = 1'b1;
                // PC_jump_inc = 1;
                flag_update = 1'b1;
            end
            else begin // other instructions
                case (opcode)
                    `LDI: begin
                        reg_write_code <= reg1_code;
                        reg_write_val <= imm;
                        reg_wb = 1'b1;
                        // PC_jump_inc = 2;
                        // rjump = 1'b1;
                    end
                    `LDA: begin
                        reg_write_code <= reg1_code;
                        reg_write_val <= mem_read_data;
                        reg_wb = 1'b1;
                        // PC_jump_inc = 2;
                        // rjump = 1'b1;
                    end
                    `LDW: begin
                        // $display("LDW instruction");
                        mem_write_addr <= imm;
                        mem_write_val <= reg1_input_data;
                        mem_wb = 1'b1;
                        // PC_jump_inc = 2;
                        // rjump = 1'b1;
                    end
                    `JMP: begin
                        PC_jump_loc = imm;
                        PC_jump_inc = 0;
                        jump = 1'b1;
                    end
                    `RJMP: begin
                        // $display("RJMP");
                        PC_jump_inc = imm;
                        rjump = 1'b1;
                    end
                    `MOV: begin
                        // $display("MOV EXECUTED");
                        reg_write_code <= reg1_code;
                        reg_write_val <= reg2_input_data;
                        reg_wb = 1'b1;
                        // PC_jump_inc = 1;
                        // rjump = 1'b1;
                    end
                    `BREQ: begin
                        if(SREG_in[`Zf]) begin
                            $display("branch");
                            PC_jump_loc = imm;
                            PC_jump_inc = 0;
                            jump = 1'b1;
                        end
                        else begin
                            $display("don't branch");
                            // PC_jump_inc = 2;
                        end
                    end
                    `CLR: begin
                        reg_write_code <= reg1_code;
                        reg_write_val <= 0;
                        reg_wb = 1'b1;
                        // PC_jump_inc = 2;
                        // rjump = 1'b1;
                    end
                    // ------------ GRAPH INSTRUCTIONS -------------
                    `STRN: begin
                        mem_write_val <= reg1_input_data;
                        mem_write_addr <= imm;
                        mem_wb = 1'b1;
                    end
                    `SVS: begin
                        $display("SVS Excecuting");
                        // $display("data %32b", mem_read_data);
                        visited_addr = `VIS_OFFSET+(imm);
                        // visited_bit = imm%32;
                        // mem_write_val = mem_read_data | 1<<visited_bit;
                        mem_write_val = 1;
                        mem_write_addr = visited_addr;
                        mem_wb = 1'b1;
                    end
                    `CVS: begin
                        visited_addr = `VIS_OFFSET+(imm);
                        // visited_bit = imm%32;
                        // mem_write_val = mem_read_data | 0<<visited_bit;
                        mem_write_val = 1;
                        mem_write_addr = visited_addr;
                        mem_wb = 1'b1;
                    end
                    `STW: begin
                        $display("ADG EXEUCTE");
                        $display("setting weight at location %32b", point*`NODES + next + `NODES);
                        // edge_loc = point*next + `NODES;
                        edge_loc = imm[29:15]*`NODES + imm[14:0] + `NODES;
                        mem_write_addr = edge_loc;
                        mem_write_val = imm2;
                        mem_wb = 1'b1;
                        rjump = 1'b1;
                        PC_jump_inc = 1;
                    end
                    `RDG: begin
                        $display("RDG EXEUCTE");
                        edge_loc = point*next + `NODES;
                        mem_write_addr = edge_loc;
                        mem_write_val = 0;
                        mem_wb = 1'b1;
                    end
                    `LDWR: begin
                        $display("LDWR EXECUTE");
                        $display("using weight from location %32b", point*`NODES + next + `NODES);
                        reg_write_code <= reg1_code;
                        reg_write_val <= edge_weight;
                        reg_wb = 1'b1;
                    end
                    `SCN: begin
                        $display("SCN EXECUTE");
                        reg_write_code = `rn;
                        reg_write_val = {node_reg_in[31:30], imm[14:0], 15'b0}; // concantenate first bit and last 15 bits
                        reg_wb = 1'b1;
                    end
                    `STYP: begin
                        $display("STYP EXECUTE");
                        reg_write_code = `rn;
                        reg_write_val = {imm[0], node_reg_in[30:0]};
                        reg_wb = 1'b1;
                    end
                    `STEP: begin
                        $display("STEP EXECUTE");
                        $display("%32b", node_reg_in);
                        // check if edge is 0
                        if(edge_weight==0 && node_reg_in[14:0]<`NODES) begin
                            $display("option 1");
                            // reg_write_code = `rn;
                            // reg_write_val = {node_reg_in[31:15], node_reg_in[14:0]+1'b1};
                            // reg_wb = 1'b1;
                            node_reg_out = {node_reg_in[31:15], node_reg_in[14:0]+1'b1};
                            rn_wb = 1'b1;
                        end
                        else if(node_reg_in[14:0]>=`NODES) begin
                            $display("no way");
                            sp_out <= sp_in - 1;
                            sp_wb = 1'b1;
                            
                            mem_write_addr <= sp_in;
                            mem_write_val <= 0;
                            mem_wb = 1'b1;


                        end
                        else if(edge_weight!=0) begin // add stack
                            $display("TRAVERSE");
                            // reg_write_code <= `rn;
                            // reg_write_val <= {node_reg_in[31:30], node_reg_in[14:0], 15'b0};
                            // reg_wb = 1'b1;
                            node_reg_out = {node_reg_in[31:30], node_reg_in[14:0], 15'b0};
                            rn_wb = 1'b1;
                            mem_write_val <= 1'b1; // mark visited
                            mem_write_addr <= {node_reg_in[31:30], node_reg_in[14:0], 15'b0} + `VIS_OFFSET;
                            mem_wb = 1'b1;
                            // update stack pointer
                            sp_out <= sp_in + 1;
                            sp_wb = 1'b1;
                            mem_write_val2 <= node_reg_in;
                            mem_write_addr2 <= sp_in + 1;
                            mem_wb2 = 1'b1;
                            // $display("%32b", reg_write_val);
                        end
                    end
                endcase
            end
        end
    end



endmodule


// 00000000100000000010000000000001
// 00000000010000000001000000000001