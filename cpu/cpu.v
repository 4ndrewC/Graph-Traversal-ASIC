`include "fmt.v"
`include "mem.v"
`include "registers.v"
`include "PC.v"
`include "execute.v"

module cpu(
    input clk,
    input [`WORD-1:0] cycles
);
  
    reg fetch_tr, dne_tr, reg_tr, mem_tr, PC_fetch, PC_wb_tr, reset_tr, sp_write_tr, rn_tr; // stages and triggers
    reg reg_wb_tr, mem_wb_tr, mem_wb_tr2, flag_update_tr;

    // PC variables
    wire jump, rjump, PC_done, PC_fetch_done;
    wire [`WORD-1:0] jump_loc;
    // wire [`WORD-1:0] PC;
    reg [`WORD-1:0] PC;
    wire signed [`WORD-1:0] jump_inc;

    // memory and register variables
    reg mem_read, mem_write, reg_read, reg_write;
    wire signed [`WORD-1:0] mem_data_in, mem_data_in2, reg_data_in;
    wire [2:0] reg1_code, reg2_code, reg_write_code;
    wire [`WORD-1:0] mem_write_addr, mem_write_addr2, mem_read_addr; // memory address (read/write, no PC fetch), never changes
    wire signed [`WORD-1:0] mem_data_out, reg1_data_out, reg2_data_out;

    wire [`NODE_BITS-1:0] next, point;
    wire [`WORD-1:0] edge_weight;
    wire [`WORD-1:0] instr, imm, imm2;// never changes on its own
    wire [`OPSIZE-1:0] opcode; // never changes on its own

    
    wire [`WORD-1:0] SREG_read, SREG_write; // status flag register

    // execution write back triggers (for syncing)
    wire reg_write_en, mem_write_en, mem_write_en2, flag_update_en, rn_update_en;


    mem mem_inst(
        .re(mem_read),
        .we(mem_write),
        .data_in(mem_data_in),
        .data_in2(mem_data_in2),
        .data_out(mem_data_out),
        .instr(instr),
        .read_addr(mem_read_addr),
        .write_addr(mem_write_addr),
        .write_addr2(mem_write_addr2),
        .fetch_addr(PC),
        .imm(imm),
        .imm2(imm2),
        .edge_weight(edge_weight),
        .rn_in(node_reg),
        .sp(sp_reg),
        .sp_node(sp_node),
        .fetch(fetch_tr),
        .write_back_en(mem_wb_tr),
        .write_back_en2(mem_wb_tr2),
        .clk(clk)
    );

    assign opcode = instr[31:26];
    assign reg1_code = instr[25:23];
    assign reg2_code = instr[22:20];
    // graph assigns
    assign next = imm[29:15];
    assign point = imm[14:0];

    execute ex_inst(
        .opcode(opcode),
        .reg1_code(reg1_code),
        .reg2_code(reg2_code),
        .imm(imm),
        .imm2(imm2),
        .edge_weight(edge_weight),
        .next(next),
        .point(point),
        .SREG_in(SREG_read),
        .SREG_out(SREG_write),
        .flag_update(flag_update_en),
        .mem_write_val(mem_data_in),
        .mem_write_val2(mem_data_in2),
        .mem_write_addr(mem_write_addr),
        .mem_write_addr2(mem_write_addr2),
        .reg_write_val(reg_data_in),
        .reg_write_code(reg_write_code),
        .node_reg_in(rn_out),
        .node_reg_out(rn_in),
        .mem_read_data(mem_data_out),
        .reg1_input_data(reg1_data_out),
        .reg2_input_data(reg2_data_out),
        .PC_jump_loc(jump_loc),
        .PC_jump_inc(jump_inc),
        .sp_in(sp_out),
        .sp_out(sp_in),
        .jump(jump),
        .rjump(rjump),
        .mem_wb(mem_write_en),
        .mem_wb2(mem_write_en2),
        .reg_wb(reg_write_en),
        .sp_wb(sp_write_en),
        .rn_wb(rn_update_en),
        .dne_tr(dne_tr),
        .clk(clk)
    );


    registers reg_inst(
        .re(reg_read),
        .we(reg_write),
        .reg1(reg1_code),
        .reg2(reg2_code),
        .reg_write_code(reg_write_code),
        .data_in(reg_data_in),
        .data_out1(reg1_data_out),
        .data_out2(reg2_data_out),
        .SREG_read(SREG_read),
        .SREG_write(SREG_write), 
        .sp_write(sp_in),
        .sp_read(sp_out),
        .rn_write_tr(rn_tr),
        .sp_write_tr(sp_write_tr),
        .rn_write(rn_in),
        .rn_read(rn_out),   
        .get_reg_en(reg_tr),
        .reg_write_back(reg_wb_tr),
        .flag_update(flag_update_tr),
        .clk(clk)
    );

    // syncing PC write back after all other write backs
    reg [2:0] write_backs, written;
    reg execute_finished, check_wb;
    reg stall;

    // graph stuff
    wire [`WORD-1:0] rn_in, rn_out; // rn_in is writing into regfile, out is reading from regfile
    
    wire sp_write_en;
    
    // copy of node register
    reg [`WORD-1:0] node_reg;
    // --------------------------------
    // STACK POINTER STUFF
    // copy of stack pointer
    reg [`WORD-1:0] sp_reg;
    wire [`WORD-1:0] sp_node;

    wire [`WORD-1:0] sp_in, sp_out;
    wire [`WORD-1:0] rp_in, rp_out;
    // -------------------------------

    always @(posedge clk) begin
        if(fetch_tr) begin
            $display("----------------------------");
            $display("PC fetch location: %0d", PC);
            fetch_tr <= 1'b0;
            reg_tr <= 1'b1;
            write_backs = 0;
            written = 0;
            stall <= 1'b0;
            // node_reg = sp_node;
        end
        if(reg_tr) begin
            $display("current instruction: %32b\n", instr);
            reg_tr <= 1'b0;
            dne_tr <= 1'b1;
            PC <= PC + 3;
            // $display("written: ", written);
        end
        if(dne_tr) begin
            /* After decode and execute, do all necessary write backs
               After all write backs, reset to initial state
            */
            dne_tr <= 1'b0;
            check_wb <= 1'b1;
            execute_finished <= 1'b1;
            // $display("finished execution");
        end
        if(check_wb) begin // sync write backs
            // $display("CYCLES: %0d", cycles);
            check_wb <= 1'b0;
            if(reg_write_en) begin
                reg_wb_tr <= 1'b1;
                write_backs <= write_backs + 1;
                if(reg_write_code==`rn) node_reg = reg_data_in;
            end
            if(mem_write_en) begin
                mem_wb_tr <= 1'b1;
                write_backs <= write_backs + 1;
            end
            if(mem_write_en2) begin
                mem_wb_tr2 <= 1'b1;
                write_backs <= write_backs + 1;
            end
            if(flag_update_en) begin
                flag_update_tr <= 1'b1;
                write_backs <= write_backs + 1;
            end
            if(jump | rjump) begin
                // $display("CYCLES NOW: %0d", cycles);
                // $display("PC write back\n");
                PC_wb_tr <= 1'b1;
                write_backs <= write_backs + 1;
            end
            if(sp_write_en) begin
                sp_write_tr <= 1'b1;
                write_backs <= write_backs + 1;
                sp_reg <= sp_in;
            end
            if(rn_update_en) begin
                rn_tr <= 1'b1;
                write_backs <= write_backs + 1;
                node_reg = rn_in;
            end
            
            $display("\nClock cycles: %0d\n", cycles);
            PC_fetch <= 1'b1;
            // if(opcode!=`JMP && opcode!=`RJMP && opcode!=`BREQ && opcode!=`STW) begin
            //     // next cycle if no stall
            //     fetch_tr <= 1'b1;
            //     written <= 0;
            // end
            // else begin
            //     stall <= 1'b1;
            //     // $display("stalling\n");
            // end

            // -----stall by default for now
            stall <= 1'b1;
        end
        if(reg_wb_tr) begin
            // $display("cycles at reg %0d", cycles);
            written <= written + 1;
            reg_wb_tr <= 1'b0;
        end
        if(mem_wb_tr) begin
            written <= written + 1;
            mem_wb_tr <= 1'b0;
        end
        if(mem_wb_tr2) begin
            written <= written + 1;
            mem_wb_tr2 <= 1'b0;
        end
        if(flag_update_tr) begin
            // $display("cycles at flag: %0d", cycles);
            written <= written + 1;
            flag_update_tr <= 1'b0;
        end
        if(sp_write_tr) begin
            written <= written + 1;
            sp_write_tr <= 1'b0;
        end
        if(rn_tr) begin
            written <= written + 1;
            rn_tr <= 1'b0;
        end
        if(PC_wb_tr) begin
            // $display("cycles at PC wb: %0d", cycles);
            written <= written + 1;
            PC_wb_tr <= 1'b0;
            if(jump) PC <= jump_loc*3;
            else if(rjump) begin
                PC <= PC + jump_inc*3-3;
                // $display("here");
            end
            // $display(reg_wb_tr);
            // $display(mem_wb_tr);
            // $display(flag_update_tr);
            // $display(write_backs);
            // $display(written);
        end
        // next cycle if stalled
        if(written==write_backs & write_backs!=0 & stall) begin
            $display("stalling\n");
            fetch_tr <= 1'b1;
        end   
    end

    // always @(posedge dne_done) $monitor("%1b", reg_wb_tr);

    initial begin
        // PC_fetch <= 1'b1;
        fetch_tr <= 1'b1;
        PC <= 0;
    end
    

endmodule
