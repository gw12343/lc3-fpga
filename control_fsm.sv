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

always_comb begin
    ctrl_signal = '0;

    if(curr == S_FETCH0) begin
        ctrl_signal.load_mar = 1;
        ctrl_signal.store_pc = 1;
        ctrl_signal.pc_mux = 0;
        ctrl_signal.load_pc = 1;
    end else if (curr == S_FETCH1) begin
        ctrl_signal.load_mdr = 1;
        ctrl_signal.mem_io_en = 1;
        ctrl_signal.mem_w_nr = 0; // read
    end else if (curr == S_FETCH2) begin
        ctrl_signal.load_ir = 1;
        ctrl_signal.store_mdr = 1;
    end else if (curr == S_BEN) begin
        ctrl_signal.load_branch_en = 1;
    end
    
end

//
always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        curr <= S_FETCH0;
    end else begin
        curr <= next;
    end
end


endmodule
