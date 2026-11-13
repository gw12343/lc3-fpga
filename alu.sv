// ALU for the LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu


module alu 
    import lc3_interface::*;
#(
    parameter int unsigned DATA_SIZE = 16
)(
    input alu_op_k ALU_K,

    input logic signed [DATA_SIZE - 1 : 0] A_IN,
    input logic signed [DATA_SIZE - 1 : 0] B_IN,
    output logic signed [DATA_SIZE - 1 : 0] ALU_OUT
);

// combanatoric operation MUX
always_comb begin
    unique case (ALU_K)
        OP_ADD: ALU_OUT = A_IN + B_IN;
        OP_AND: ALU_OUT = A_IN & B_IN;
        OP_NOT: ALU_OUT = ~A_IN;
        OP_PASS_A: ALU_OUT = A_IN;
    endcase
end

endmodule
