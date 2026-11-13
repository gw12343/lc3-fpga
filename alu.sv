// ALU for the LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu


module alu #(
    parameter int unsigned DATA_SIZE = 16
)(
    input logic[1:0] ALU_K,

    input logic signed [DATA_SIZE - 1 : 0] A_IN,
    input logic signed [DATA_SIZE - 1 : 0] B_IN,
    output logic signed [DATA_SIZE - 1 : 0] ALU_OUT
);

// combanatoric operation MUX
always_comb begin
    unique case (ALU_K)
        2'b00: ALU_OUT = A_IN + B_IN;
        2'b01: ALU_OUT = A_IN & B_IN;
        2'b10: ALU_OUT = ~A_IN;
        2'b11: ALU_OUT = A_IN;
    endcase
end

endmodule
