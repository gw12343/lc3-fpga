// LC3 computer.
// 11/6/2026
// Gabriel West
// gwest9@illinois.edu

module lc3 
    import lc3_interface::*;
#(
    parameter int unsigned BUS_WIDTH = 16,
    parameter int unsigned ADDRESS_SIZE = 16
)
(
    input logic sys_clk,
    input logic rst_n,

    output logic[8:0] unused,
    output logic[1:0] unused2
);

// ============================ Interconnect Signals =============================

`ifdef VERILATOR
    logic [BUS_WIDTH-1:0] bus;
`else
    tri [BUS_WIDTH-1:0] bus;
`endif

control_interface_t control;

// Signals buffered to bus
logic signed [BUS_WIDTH-1:0] alu_value;
logic [BUS_WIDTH-1:0] ir_value;
logic [ADDRESS_SIZE-1:0] pc_value;
logic [ADDRESS_SIZE-1:0] mar_mux_out;
logic[BUS_WIDTH-1:0] mdr_val;

assign unused = ir_value[8:0];
assign unused2 = control[7:6];

// Misc Signals
logic SR2_MUX;
logic [BUS_WIDTH-1:0] TRAP_VEC;
logic signed [BUS_WIDTH-1:0] IR_IMMEDIATE_VALUE;
logic [BUS_WIDTH-1:0] SR2_OUT;
logic [BUS_WIDTH-1:0] SR1_OUT;
logic N_FLAG;
logic Z_FLAG;
logic P_FLAG;
logic [2:0] IR_DR;  // [11:9]
logic [2:0] IR_SR;  // [8:6]
logic [2:0] IR_SR2; // [2:0]

logic [2:0] DR_MUX_OUT;
logic [2:0] SR1_MUX_OUT;
logic mem_ready;
logic branch_en;

// Multiplexer outputs
logic signed [ADDRESS_SIZE-1:0] SR2_MUX_OUT;
logic [ADDRESS_SIZE-1:0] ADDRESS1MUX_OUT;
logic signed [ADDRESS_SIZE-1:0] ADDRESS2MUX_OUT;


always_comb begin
    unique case (control.addr1_mux)
        1'b0: ADDRESS1MUX_OUT = pc_value; 
        1'b1: ADDRESS1MUX_OUT = SR1_OUT;
    endcase
end


logic [ADDRESS_SIZE-1:0] ADDRESS_SUM;

// ===================================== MUXs ======================================
// Address 1 after offset (by address 2) mux
always_comb begin
    if(ADDRESS2MUX_OUT[ADDRESS_SIZE-1] == 1'b1) begin
        // Address 2 is a negative offset (msb is 1)
        // Subtract address 2 absolute value
        ADDRESS_SUM = ADDRESS1MUX_OUT - ((~$unsigned(ADDRESS2MUX_OUT)) + 1'b1);
    end else begin
        // Address 2 is a non negative offset (msb is 0)
        // add like normal
        ADDRESS_SUM = ADDRESS1MUX_OUT + $unsigned(ADDRESS2MUX_OUT);
    end
end

// Memory address mux
always_comb begin
    unique case(control.mar_mux)
        1'b0: mar_mux_out = TRAP_VEC;
        1'b1: mar_mux_out = ADDRESS_SUM;
    endcase
end

// ALU input b mux
always_comb begin
    unique case(SR2_MUX)
        1'b0: SR2_MUX_OUT = $signed(SR2_OUT);
        1'b1: SR2_MUX_OUT = IR_IMMEDIATE_VALUE;
    endcase
end

// register file data reg select mux
always_comb begin
    case (control.dr_mux)
        2'b00: DR_MUX_OUT = IR_DR;
        2'b01: DR_MUX_OUT = 3'b111;
        2'b10: DR_MUX_OUT = 3'b110;
        default: DR_MUX_OUT = 3'b000;
    endcase
end

// register file source 1 reg select mux
always_comb begin
    case (control.sr1_mux)
        2'b00: SR1_MUX_OUT = IR_DR;
        2'b01: SR1_MUX_OUT = IR_SR;
        2'b10: SR1_MUX_OUT = 3'b110;
        default: SR1_MUX_OUT = 3'b000;
    endcase
end


// ==================================== Modules ====================================



`ifdef VERILATOR
    // Multiplex bus instead of use tristate buffers for simulation
    always_comb begin
        bus = '0;
        if (control.store_mar_mux) bus |= mar_mux_out;
        if (control.store_pc)      bus |= pc_value;
        if (control.store_alu)     bus |= $unsigned(alu_value);
        if (control.store_mdr)     bus |= mdr_val;
    end
`else
    bus_gate gate_mar_mux (
        .assert_val(control.store_mar_mux),
        .data      (mar_mux_out),
        .bus       (bus)
    );
    bus_gate gate_pc (
        .assert_val(control.store_pc),
        .data      (pc_value),
        .bus       (bus)
    );
    bus_gate gate_alu (
        .assert_val(control.store_alu),
        .data      ($unsigned(alu_value)),
        .bus       (bus)
    );
    bus_gate gate_mdr (
        .assert_val(control.store_mdr),
        .data      (mdr_val),
        .bus       (bus)
    );
`endif


control_fsm control_fsm (
    .sys_clk    (sys_clk),
    .rst_n      (rst_n),
    .addr_mode_op (ir_value[11]),
    .opcode       (ir_value[BUS_WIDTH-1:BUS_WIDTH-4]),
    .mem_ready  (mem_ready),
    .branch_en  (branch_en),
    .ctrl_signal(control)
);

mio_controller mio (
    .sys_clk   (sys_clk),
    .rst_n     (rst_n),
    .load_mdr  (control.load_mdr),
    .load_mar  (control.load_mar),
    .w_nr      (control.mem_w_nr),
    .mio_enable(control.mem_io_en),
    .BUS_IN    (bus),
    .ready     (mem_ready),
    .mdr_reg   (mdr_val)
);


alu alu0 (
    .ALU_K   (control.alu_k),
    .A_IN    ($signed(SR1_OUT)),
    .B_IN    (SR2_MUX_OUT),
    .ALU_OUT (alu_value)
);


instruction_reg ir (
    .sys_clk         (sys_clk),
    .rst_n           (rst_n),
    .load_ir         (control.load_ir),
    .address_2_mux   (control.addr2_mux),
    .DATA_BUS_IN     (bus),
    .IR_OUT          (ir_value),
    .ADDRESS2MUX_OUT (ADDRESS2MUX_OUT),
    .TRAP_VEC        (TRAP_VEC),
    .IR_IMMEDIATE_VALUE (IR_IMMEDIATE_VALUE),
    .IR_DR              (IR_DR),
    .IR_SR              (IR_SR),
    .IR_SR2             (IR_SR2),
    .SR2_MUX            (SR2_MUX)
);


program_counter pc (
    .sys_clk    (sys_clk),
    .rst_n      (rst_n),
    .pc_mux     (control.pc_mux),
    .load_pc    (control.load_pc),
    .DATA_BUS_IN(bus),
    .ADDR_IN    (ADDRESS_SUM),
    .PC_OUT     (pc_value)
);

register_bank rb (
    .sys_clk    (sys_clk),
    .rst_n      (rst_n),
    .load_reg   (control.load_reg),
    .DATA_BUS_IN(bus),
    .DR         (DR_MUX_OUT),
    .SR1        (SR1_MUX_OUT),
    .SR2        (IR_SR2),
    .SR1_OUT    (SR1_OUT),
    .SR2_OUT    (SR2_OUT)
);


flags_register flags (
    .sys_clk     (sys_clk),
    .rst_n       (rst_n),
    .update_flags(control.load_flags),
    .DATA_BUS_IN (bus),
    .N_FLAG      (N_FLAG),
    .Z_FLAG      (Z_FLAG),
    .P_FLAG      (P_FLAG)
);

branch_controller branch_controller (
    .sys_clk  (sys_clk),
    .rst_n    (rst_n),
    .N_FLAG   (N_FLAG),
    .Z_FLAG   (Z_FLAG),
    .P_FLAG   (P_FLAG),
    .ir_out   (ir_value[11:9]),
    .load_be  (control.load_branch_en),
    .branch_en(branch_en)
);

endmodule
