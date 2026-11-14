// Memory IO controller for the LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu

module mio_controller #(
    parameter int unsigned DATA_SIZE = 16,
    parameter int unsigned ADDRESS_SIZE = 16,
    localparam int unsigned DATA_DEPTH = 1 << ADDRESS_SIZE
)(
    input logic sys_clk,
    input logic rst_n,

    // control signals
    input logic load_mdr,
    input logic load_mar,
    input logic w_nr,   // write_not_read:  1:write, 0:read

    input logic mio_enable,

    // other
    input logic [DATA_SIZE-1:0] BUS_IN,

    output logic ready,
    output logic [DATA_SIZE-1:0] mdr_reg
);


typedef enum { 
    S_IDLE, S_BEGIN_READ, S_BEGIN_WRITE, S_READY
} mem_state_t;


// Make sure ram is infered to be bram and not luts. 
(* ram_style = "block" *) logic [DATA_SIZE-1:0] ram [DATA_DEPTH];
logic [DATA_SIZE-1:0] ram_out;

logic [ADDRESS_SIZE-1:0] mar_reg;
logic [DATA_SIZE-1:0] mdr_mux_out;

mem_state_t curr_state = S_IDLE;
mem_state_t next_state;

always_comb begin
    // Select MDR source
    unique case (mio_enable)
        1'b0: mdr_mux_out = BUS_IN;
        1'b1: mdr_mux_out = ram_out;
    endcase
end

// Next state combanatoric logic
always_comb begin
    unique case (curr_state)
        S_IDLE: 
            if(!mio_enable) begin
                next_state = S_IDLE;
            end else begin
                if(w_nr) begin
                    next_state = S_BEGIN_WRITE;
                end else begin
                    next_state = S_BEGIN_READ;
                end
            end
        S_BEGIN_READ: next_state = S_READY;
        S_BEGIN_WRITE: next_state = S_READY;
        S_READY: next_state = S_IDLE;
    endcase

    ready = curr_state == S_READY;
end


always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        mdr_reg <= '0;
        mar_reg <= '0;
        curr_state <= S_IDLE;
    end else begin

        if(curr_state == S_BEGIN_WRITE) begin
            ram[mar_reg] <= mdr_reg;
        end
        if (curr_state == S_BEGIN_READ) begin
            ram_out <= ram[mar_reg];
        end
        

        if (load_mdr && (!mio_enable || ready)) begin
            mdr_reg <= mdr_mux_out;
        end

        if (load_mar) begin
            mar_reg <= BUS_IN;
        end

        curr_state <= next_state;
    end
end




endmodule
