// Register bank testbench for the LC3 computer.
// 11/8/2026
// Gabriel West
// gwest9@illinois.edu

module register_bank_tb;

logic sys_clk;
logic rst_n;

logic load_reg;
logic[15:0] DATA_BUS_IN;
logic[2:0] DR;
logic[2:0] SR1;
logic[2:0] SR2;
logic[15:0] SR1_OUT;
logic[15:0] SR2_OUT;

register_bank DUT (
    .sys_clk    (sys_clk),
    .rst_n      (rst_n),
    .load_reg   (load_reg),
    .DATA_BUS_IN(DATA_BUS_IN),
    .DR         (DR),
    .SR1        (SR1),
    .SR2        (SR2),
    .SR1_OUT    (SR1_OUT),
    .SR2_OUT    (SR2_OUT)
);

task automatic set_reg(logic[2:0] r, logic[15:0] val);
    @(posedge sys_clk);
    DR = 3'(r);
    DATA_BUS_IN = 16'(val);
    load_reg = 1;
    @(posedge sys_clk);
    load_reg = 0;
endtask


initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, register_bank_tb);
end

initial begin
    sys_clk = 0;
    forever #5 sys_clk = ~sys_clk;
end


initial begin
    load_reg = 0;
    rst_n = 0;
    #20;
    rst_n = 1;

    SR1 = 1;
    SR2 = 0;



    $monitor("DEST: %03h   SR1: %03h   SR2: %03h", DR, SR1, SR2);


    set_reg(1, 'hFFFF );
    #10;
    @(posedge sys_clk);
    SR1 = 1;
    $display("%03h val: %03h", SR1, SR1_OUT);
    @(posedge sys_clk);
    SR1=0;

    set_reg(2, 'ha1a1 );
    #10;

    #10;
    @(posedge sys_clk);
    SR1 = 1;
    $display("%03h val: %03h", SR2, SR2_OUT);
    @(posedge sys_clk);
    SR1=0;

    set_reg(2, 'hDEAD );
    set_reg(3, 'hBEEF );
    #10;

    $finish;
end

endmodule
