// Control module interface for the LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu

package lc3_interface;
    
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

    logic[1:0]  alu_k;
    logic[1:0]  dr_mux;
} control_interface_t;


typedef enum logic [5:0] {
    S_FETCH0, S_FETCH1, S_FETCH2,
    S_BEN,

    S_ADD,
    S_AND,
    S_NOT,
    S_TRAP0,
    S_TRAP1,
    S_TRAP2,
    S_LEA,

    // related load instructions
    S_LD0,
    S_LDR0,
    S_LDI0,
    S_LDI1,
    S_LDI2,
    S_LCOMMON0,
    S_LCOMMON1,

    // related store instructions
    S_STI0,
    S_STI1,
    S_STI2,
    S_STR0,
    S_ST0,
    S_SCOMMON0,
    S_SCOMMON1,


    S_JSR0,
    S_JSR1_BRANCH,
    S_JSR1_BASE,

    S_JMP,
    
    S_BR0,
    S_BR1,


    S_EXCEPTION
} control_state_t;

endpackage : lc3_interface
