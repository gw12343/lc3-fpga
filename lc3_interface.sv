// Control module interface for the LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu

package lc3_interface;
    
typedef enum logic[1:0] {
    OP_ADD = 2'b00,
    OP_AND = 2'b01,
    OP_NOT = 2'b10,
    OP_PASS_A = 2'b11
} alu_op_k;

typedef struct packed {
    logic       load_mar;
    logic       load_mdr;
    logic       load_ir;
    logic       load_pc;
    logic       load_reg;
    logic       load_branch_en;
    logic       load_flags;

    logic       store_mar_mux;
    logic       store_mdr;
    logic       store_alu;
    logic       store_pc;

    logic       mar_mux;
    logic       addr1_mux;
    logic[1:0]  addr2_mux;
    logic[1:0]  pc_mux;
    logic[1:0]  sr1_mux;

    logic       mem_io_en;
    logic       mem_w_nr;

    alu_op_k  alu_k;
    logic[1:0]  dr_mux;
} control_interface_t;


typedef enum logic [5:0] {
    S_FETCH0 = 6'd18, 
    S_FETCH1 = 6'd33, 
    S_FETCH2 = 6'd35,
    S_BEN = 6'd32,

    S_ADD = 6'd1,
    S_AND = 6'd5,
    S_NOT = 6'd9,
    S_TRAP0 = 6'd15,
    S_TRAP1 = 6'd28,
    S_TRAP2 = 6'd30,
    S_LEA = 6'd14,

    // related load instructions
    S_LD0 = 6'd2,  //b
    S_LDR0 = 6'd6, //c
    S_LDI0 = 6'd10,
    S_LDI1 = 6'd24,
    S_LDI2 = 6'd26,
    S_LCOMMON0 = 6'd25, //10
    S_LCOMMON1 = 6'd27, //11

    // related store instructions
    S_STI0 = 6'd11,
    S_STI1 = 6'd29,
    S_STI2 = 6'd31,
    S_STR0 = 6'd7,
    S_ST0 = 6'd3,
    S_SCOMMON0 = 6'd23,
    S_SCOMMON1 = 6'd16,


    S_JSR0 = 6'd4,
    S_JSR1_BRANCH = 6'd21,
    S_JSR1_BASE = 6'd20,

    S_JMP = 6'd12,
    
    S_BR0 = 6'd0,
    S_BR1 = 6'd22,


    S_EXCEPTION = 6'd13
} control_state_t;


endpackage : lc3_interface
