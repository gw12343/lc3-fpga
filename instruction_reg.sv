// Instruction register and related
// signal generation for the LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu

module instruction_reg #(
    // size of data bus
    parameter int unsigned DATA_SIZE = 16,
    // size of addresses
    parameter int unsigned ADDRESS_SIZE = 16,
    // size of immediates
    parameter int unsigned IMMEDIATE_SIZE = 5
) (
    input logic sys_clk,
    input logic rst_n,

    input logic load_ir,
    input logic [1:0] address_2_mux,

    input logic [DATA_SIZE-1:0] DATA_BUS_IN,

    output logic [3:0] OPCODE_OUT,
    output logic [2:0] NZP_OUT,
    
    output logic signed [ADDRESS_SIZE-1:0] ADDRESS2MUX_OUT,
    output logic [DATA_SIZE-1:0] TRAP_VEC,

    output logic signed [DATA_SIZE-1:0] IR_IMMEDIATE_VALUE,
    output logic [2:0] IR_DR,  // [11:9]
    output logic [2:0] IR_SR,  // [8:6]
    output logic [2:0] IR_SR2, // [2:0]

    output logic SR2_MUX
);


logic [DATA_SIZE-1:0] IR_OUT;
assign OPCODE_OUT = IR_OUT[DATA_SIZE-1:DATA_SIZE-4];
assign NZP_OUT = IR_OUT[DATA_SIZE-5:DATA_SIZE-7];


// size of various address segments from the current instruction
localparam int unsigned ADDR2MUX_3_OUT_SZ = 11;
localparam int unsigned ADDR2MUX_2_OUT_SZ = 9;
localparam int unsigned ADDR2MUX_1_OUT_SZ = 6;
localparam int unsigned TRAP_VEC_SIZE = 8;

// different instruction operands, immediates, etc.
logic signed [ADDR2MUX_3_OUT_SZ-1:0] slice3;
logic signed [ADDR2MUX_2_OUT_SZ-1:0] slice2;
logic signed [ADDR2MUX_1_OUT_SZ-1:0] slice1;

// Sign extend these constants
assign slice3 = $signed(IR_OUT[ADDR2MUX_3_OUT_SZ-1:0]);
assign slice2 = $signed(IR_OUT[ADDR2MUX_2_OUT_SZ-1:0]);
assign slice1 = $signed(IR_OUT[ADDR2MUX_1_OUT_SZ-1:0]);

// Zero extend vector
assign TRAP_VEC = DATA_SIZE'(IR_OUT[TRAP_VEC_SIZE-1:0]);

// ALU B input control signal (embedded into bit 5 in instruction format)
assign SR2_MUX = IR_OUT[5];

// Slice the immediate from the instruction and sign extend to DATA_SIZE bits
assign IR_IMMEDIATE_VALUE = DATA_SIZE'(
                                        $signed(
                                            IR_OUT[IMMEDIATE_SIZE-1:0]
                                            )
                                        );

// Register operands
assign IR_DR = IR_OUT[11:9];
assign IR_SR = IR_OUT[8:6];
assign IR_SR2 = IR_OUT[2:0];

always_comb begin
    unique case (address_2_mux)
        2'b00: ADDRESS2MUX_OUT = '0;
        2'b01: ADDRESS2MUX_OUT = ADDRESS_SIZE'(slice1);
        2'b10: ADDRESS2MUX_OUT = ADDRESS_SIZE'(slice2);
        2'b11: ADDRESS2MUX_OUT = ADDRESS_SIZE'(slice3);
    endcase
end


always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        IR_OUT <= '0;
    end else if (load_ir) begin
        IR_OUT <= DATA_BUS_IN;
    end
end



endmodule
