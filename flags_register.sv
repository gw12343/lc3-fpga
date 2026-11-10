// Flags register LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu

module flags_register #(
    parameter int unsigned DATA_SIZE = 16
 )(
    input logic sys_clk,
    input logic rst_n,

    input logic update_flags,
    input logic [DATA_SIZE-1:0] DATA_BUS_IN,

    output logic N_FLAG,
    output logic Z_FLAG,
    output logic P_FLAG
);


always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        N_FLAG <= '0;
        Z_FLAG <= '0;
        P_FLAG <= '0;
    end else if (update_flags) begin
        N_FLAG <= $signed(DATA_BUS_IN) < 0;
        Z_FLAG <= DATA_BUS_IN == '0;
        P_FLAG <= $signed(DATA_BUS_IN) > 0;
    end
end


endmodule
