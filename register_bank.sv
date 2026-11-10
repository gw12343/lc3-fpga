// Register bank for the LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu

module register_bank #(
    parameter int unsigned REG_SIZE = 16,
    parameter int unsigned NUM_REGS = 8,
    localparam int unsigned REG_SEL_WIDTH = $clog2(NUM_REGS)
)
(
    input logic sys_clk,
    input logic rst_n,

    input logic load_reg,

    input logic[REG_SIZE - 1:0] DATA_BUS_IN,

    input logic[REG_SEL_WIDTH-1:0] DR,
    input logic[REG_SEL_WIDTH-1:0] SR1,
    input logic[REG_SEL_WIDTH-1:0] SR2,
    
    output logic[REG_SIZE - 1:0] SR1_OUT,
    output logic[REG_SIZE - 1:0] SR2_OUT
);

// unpacked register bank
logic [REG_SIZE - 1:0] bank [8];


assign SR1_OUT = bank[SR1];
assign SR2_OUT = bank[SR2];

always @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        for(int unsigned i = 0; i < NUM_REGS; i++) begin
            bank[i] <= '0;
        end
    end else if(load_reg) begin
        bank[DR] <= DATA_BUS_IN;
    end

end


endmodule
