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

logic signed [DATA_SIZE - 1 : 0] add_val;    //00
logic signed [DATA_SIZE - 1 : 0] and_val;    //01
logic signed [DATA_SIZE - 1 : 0] not_val;    //10
logic signed [DATA_SIZE - 1 : 0] pass_a_val; //11


assign add_val = A_IN + B_IN;
assign and_val = A_IN & B_IN;
assign not_val = ~A_IN;
assign pass_a_val = A_IN;


// combanatoric operation MUX
always_comb begin
    unique case (ALU_K)
        2'b00: ALU_OUT = add_val;
        2'b01: ALU_OUT = and_val;
        2'b10: ALU_OUT = not_val;
        2'b11: ALU_OUT = pass_a_val;
    endcase
end

endmodule
