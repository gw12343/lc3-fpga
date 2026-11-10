// Tristate buffer for bus connectivity for the LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu

module bus_gate #(
    parameter int unsigned DATA_SIZE = 16  
)(
    input logic assert_val,
    input logic [DATA_SIZE-1:0] data,
    output logic [DATA_SIZE-1:0] bus
);

    always_comb begin
        if(assert_val) begin
            bus = data;
        end else begin
            bus = 'Z;
        end
    end

endmodule
