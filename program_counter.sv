// Program counter for the LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu

module program_counter #(
    parameter int unsigned DATA_SIZE = 16,
    parameter int unsigned ADDRESS_SIZE = 16
)(
    input logic sys_clk,
    input logic rst_n,

    input logic[1:0] pc_mux,
    input logic load_pc,

    input logic[DATA_SIZE - 1:0] DATA_BUS_IN,
    input logic[ADDRESS_SIZE-1:0] ADDR_IN,


    output logic[ADDRESS_SIZE-1:0] PC_OUT
);




always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        PC_OUT <= '0;
    end else if (load_pc) begin
        if(pc_mux == 2'b00 || pc_mux == 2'b11) begin
            PC_OUT <= PC_OUT + 1;
        end else if (pc_mux == 2'b01) begin
            PC_OUT <= DATA_BUS_IN;
        end else if (pc_mux == 2'b10) begin
            PC_OUT <= ADDR_IN;
        end
    end
end



endmodule
