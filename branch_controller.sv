// Branch controller for the LC3 computer.
// 11/8/2026
// Gabriel West
// gwest9@illinois.edu


module branch_controller (
    input logic sys_clk,
    input logic rst_n,

    input logic N_FLAG,
    input logic Z_FLAG,
    input logic P_FLAG,

    input logic[11:9] ir_out,
    input logic load_be,

    output logic branch_en
);



always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        branch_en <= 0;
    end else if(load_be) begin
        branch_en <= (ir_out[11] & N_FLAG) + (ir_out[10] & Z_FLAG) + (ir_out[9] & P_FLAG);
    end
end


endmodule
