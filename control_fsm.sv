// Control module implementation for the LC3 computer.
// 11/8/2026
// Gabriel West
// gwest9@illinois.edu

module control_fsm 
    import lc3_interface::*;
(
    input logic sys_clk,
    input logic rst_n,

    input logic [3:0] opcode,
    input logic addr_mode_op,

    input logic mem_ready,
    input logic branch_en,

    output control_interface_t ctrl_signal
);

control_state_t curr = S_FETCH0;
control_state_t next;


// Get next state after fetch-decode from the current opcode
function control_state_t get_state_from_opcode(
    input logic[3:0] op
);
    unique case(op)
        4'b0001: get_state_from_opcode = S_ADD;
        4'b0101: get_state_from_opcode = S_AND;
        4'b0000: get_state_from_opcode = S_BR0;
        4'b1100: get_state_from_opcode = S_JMP;
        4'b0100: get_state_from_opcode = S_JSR0;
        4'b1111: get_state_from_opcode = S_TRAP0;
        4'b0010: get_state_from_opcode = S_LD0;
        4'b1010: get_state_from_opcode = S_LDI0;
        4'b0110: get_state_from_opcode = S_LDR0;
        4'b1110: get_state_from_opcode = S_LEA;
        4'b1001: get_state_from_opcode = S_NOT;
        4'b0011: get_state_from_opcode = S_ST0;
        4'b1011: get_state_from_opcode = S_STI0;
        4'b0111: get_state_from_opcode = S_STR0;
        4'b1000: get_state_from_opcode = S_EXCEPTION; // RTI unimplemented for now
        4'b1101: get_state_from_opcode = S_EXCEPTION; // illegal opcode
    endcase
endfunction

// Next state logic
always_comb begin
    case (curr)
        S_FETCH0: next = S_FETCH1;
        S_FETCH1: next = mem_ready ? S_FETCH2 : curr;
        S_FETCH2: next = S_BEN;

        S_BEN: next = get_state_from_opcode(opcode);

        S_ADD: next = S_FETCH0;
        S_AND: next = S_FETCH0;
        S_NOT: next = S_FETCH0;
        
        S_TRAP0: next = S_TRAP1;
        S_TRAP1: next = mem_ready ? S_TRAP2 : curr;
        S_TRAP2: next = S_FETCH0;

        S_LEA: next = S_FETCH0;

        S_LD0: next = S_LCOMMON0;
        S_LDR0: next = S_LCOMMON0; 
        S_LDI0: next = S_LDI1;
        S_LDI1: next = mem_ready ? S_LDI2 : curr;
        S_LDI2: next = S_LCOMMON0;
        S_LCOMMON0: next = mem_ready ? S_LCOMMON1 : curr;
        S_LCOMMON1: next = S_FETCH0;


        S_SCOMMON0: next = S_SCOMMON1;
        S_SCOMMON1: next = mem_ready ? S_FETCH0 : curr;
        S_STI0: next = S_STI1;
        S_STI1: next = mem_ready ? S_STI2 : curr;
        S_STI2: next = S_SCOMMON0;
        S_STR0: next = S_SCOMMON0;
        S_ST0: next = S_SCOMMON0;

        S_JSR0: next = addr_mode_op ? S_JSR1_BRANCH : S_JSR1_BASE;
        S_JSR1_BRANCH: next = S_FETCH0;
        S_JSR1_BASE: next = S_FETCH0;
        S_JMP: next = S_FETCH0;

        S_BR0: next = branch_en ? S_BR1 : S_FETCH0;
        S_BR1: next = S_FETCH0;

        S_EXCEPTION: next = S_EXCEPTION;
        default: next = S_FETCH0;
    endcase
end

// Possible locations to store output of an ALU operation
typedef enum {
    DEST_REG, DEST_PC, DEST_MDR, DEST_MAR
} alu_dest_t;

// Ranges possible for sr1 from the instruction;
// either IR[8:6] or IR[11:9] depending on the instruction
typedef enum { 
    SOURCE_IR8_6,
    SOURCE_IR11_9
} alu_source_range_t;

typedef enum {
    PC_NO_OFF,
    PC_OFF9,
    BASE_OFF6,
    TRAP_VEC
} mar_load_source_t;


function void load_mar(mar_load_source_t src);
    ctrl_signal.load_mar = 1;
    ctrl_signal.store_mar_mux = 1; 

    unique case(src)
        PC_NO_OFF: begin
            //pc no off
            ctrl_signal.load_mar = 1;
            ctrl_signal.store_pc = 1;  
        end
        PC_OFF9: begin
            // 9 bit sext + pc
            ctrl_signal.addr2_mux = 2'b10;  // 9 bit sext
            ctrl_signal.addr1_mux = 1'b0;   // pc
            ctrl_signal.mar_mux = 1'b1;
        end
        BASE_OFF6: begin
            // 6 bit sext + B
            ctrl_signal.addr2_mux = 2'b01;  // 6 bit sext
            ctrl_signal.addr1_mux = 1'b1;   // B
            ctrl_signal.mar_mux = 1'b1;     // 6 bit sext + B
            ctrl_signal.sr1_mux = 2'b01;
        end
        TRAP_VEC: begin
            // select ZEXT(IR[7:0])
            ctrl_signal.mar_mux = 0; 
        end
    endcase
endfunction

function void read_mem;
    // MDR <== M[MAR]
    ctrl_signal.load_mdr = 1;
    ctrl_signal.mem_io_en = 1;
    ctrl_signal.mem_w_nr = 0; // read
endfunction

function void write_mem;
    ctrl_signal.mem_io_en = 1;
    ctrl_signal.mem_w_nr = 1;
endfunction

function void update_flags;
    ctrl_signal.load_flags = 1;
endfunction

function void alu_op(alu_op_k op, alu_source_range_t sr1, alu_dest_t dest, logic up_flags);
    // Select correct load location
    unique case(dest)
        DEST_REG: ctrl_signal.load_reg = 1;
        DEST_PC:  begin 
            ctrl_signal.load_pc = 1; 
            ctrl_signal.pc_mux = 2'b01;
        end
        DEST_MDR: ctrl_signal.load_mdr = 1;
        DEST_MAR: ctrl_signal.load_mar = 1;
    endcase


    ctrl_signal.store_alu = 1;
    ctrl_signal.sr1_mux = (sr1 == SOURCE_IR8_6) ? 2'b01 : 2'b00;
    ctrl_signal.alu_k = op;
    ctrl_signal.load_flags = up_flags;

endfunction


always_comb begin
    ctrl_signal = '0;

    unique case(curr)
        S_FETCH0: begin
            ctrl_signal.load_mar = 1;
            ctrl_signal.store_pc = 1;
            ctrl_signal.pc_mux = 0;
            ctrl_signal.load_pc = 1;
        end
        S_FETCH1: read_mem();
        S_FETCH2: begin
            ctrl_signal.load_ir = 1;
            ctrl_signal.store_mdr = 1;
        end
        S_BEN: ctrl_signal.load_branch_en = 1;
        S_AND: alu_op(OP_AND, SOURCE_IR8_6, DEST_REG, 1);
        S_ADD: alu_op(OP_ADD, SOURCE_IR8_6, DEST_REG, 1);
        S_NOT: alu_op(OP_NOT, SOURCE_IR8_6, DEST_REG, 1);
        S_TRAP0: begin
            load_mar(TRAP_VEC);
        end
        S_TRAP1: begin
            ctrl_signal.load_reg = 1;
            ctrl_signal.store_pc = 1;
            ctrl_signal.dr_mux = 2'b01; // r7

            read_mem();
        end
        S_TRAP2: begin
            ctrl_signal.load_pc = 1;
            ctrl_signal.store_mdr = 1;
            ctrl_signal.pc_mux = 2'b01;
        end
        S_LEA: begin
            // Store address in register 
            ctrl_signal.load_reg = 1;
            ctrl_signal.addr2_mux = 2'b10;  // 9 bit sext
            ctrl_signal.addr1_mux = 1'b0;   // pc
            ctrl_signal.mar_mux = 1'b1;

            ctrl_signal.store_mar_mux = 1; // 9 bit sext + pc
            update_flags();
        end
        S_LD0: load_mar(PC_OFF9);
        S_LDI0, S_STI0: load_mar(PC_OFF9);
        S_LCOMMON0: read_mem();
        S_LCOMMON1: begin
            ctrl_signal.load_reg = 1;
            ctrl_signal.store_mdr = 1;
            update_flags();
        end

        S_LDR0, S_STR0: load_mar(BASE_OFF6);
        S_LDI1, S_STI1: read_mem();
        S_LDI2, S_STI2: begin
            ctrl_signal.store_mdr = 1;
            ctrl_signal.load_mar = 1;
        end
        S_ST0: load_mar(PC_OFF9);
        S_SCOMMON0: alu_op(OP_PASS_A, SOURCE_IR11_9, DEST_MDR, 0);
        S_SCOMMON1: begin
            write_mem();
        end
        S_JSR0: begin
            ctrl_signal.load_reg = 1;
            ctrl_signal.dr_mux = 2'b01; //r7
            ctrl_signal.store_pc = 1;
        end
        S_JSR1_BRANCH: begin
            ctrl_signal.load_pc = 1;
            ctrl_signal.addr2_mux = 2'b11; // IR[10:0] SEXT
            ctrl_signal.addr1_mux = 0;     // PC
            ctrl_signal.pc_mux = 2'b10;
        end
        S_JMP, S_JSR1_BASE: alu_op(OP_PASS_A, SOURCE_IR8_6, DEST_PC, 0);
        S_BR0, S_EXCEPTION: ctrl_signal = '0;
        S_BR1: begin
            ctrl_signal.load_pc = 1;
            ctrl_signal.pc_mux = 2'b10; // sum
            ctrl_signal.addr2_mux = 2'b10; // IR[8:0]
            ctrl_signal.addr1_mux = 1'b0; // PC
        end
        
    endcase   
end


// Go to next state
always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        curr <= S_FETCH0;
    end else begin
        curr <= next;
    end
end


endmodule
