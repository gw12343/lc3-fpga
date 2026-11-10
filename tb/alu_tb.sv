// ALU testbench for the LC3 computer.
// 11/7/2026
// Gabriel West
// gwest9@illinois.edu



module alu_tb;

logic signed [15:0] a, b, out;
logic [1:0] op;


alu DUT(
    .ALU_K  (op),
    .A_IN   (a),
    .B_IN   (b),
    .ALU_OUT (out)
);


task automatic test_add;
    op = 2'b00;
    for(int i = 0; i < 10000; i ++) begin
        shortint x = 16'($random());
        shortint y = 16'($random());
        a = x;
        b = y;
        #1;
        assert (out == (x+y)) else   $error("failed add. got:  %04h + %04h = %04h", x, y, out);
    end
endtask

task automatic test_and;
    op = 2'b01;
    for(int i = 0; i < 10000; i ++) begin
        shortint x = 16'($random());
        shortint y = 16'($random());
        a = x;
        b = y;
        #1;
        assert (out == (x&y)) else   $error("failed and. got:  %04h & %04h = %04h", x, y, out);
    end
endtask

task automatic test_not;
    op = 2'b10;
    for(int i = 0; i < 10000; i ++) begin
        shortint x = 16'($random());
        shortint y = 16'($random());
        a = x;
        b = y;
        #1;
        assert (out == (~x)) else   $error("failed not. got:  ~%04h = %04h", x, out);
    end
endtask


task automatic test_pass;
    op = 2'b11;
    for(int i = 0; i < 10000; i ++) begin
        shortint x = 16'($random());
        shortint y = 16'($random());
        a = x;
        b = y;
        #1;
        assert (out == (x)) else   $error("failed pass. got:  %04h = %04h", x, out);
    end
endtask


initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, alu_tb);
end

initial begin
    $display("================ ALU TESTBENCH ================");

    a = 0;
    b = 0;
    op = 2'b00;

    test_add();
    test_and();
    test_not();
    test_pass();


    $display("===============================================\n   Finished");


    $finish();
end


endmodule
