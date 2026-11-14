

module integration_tb;

    logic sys_clk;
    logic rst_n;
    //logic[8:0] unused;
    //logic[1:0] unused2;

    logic gate_pc;
    logic gate_alu;
    logic gate_mdr;
    logic gate_mar;
    logic load_pc;
    

    lc3 DUT (
        .sys_clk(sys_clk),
        .rst_n(rst_n)//,
       // .unused(unused)//,
        //.unused2(unused2)
    );

    assign gate_pc = DUT.control.store_pc;
    assign gate_alu = DUT.control.store_alu;
    assign gate_mdr = DUT.control.store_mdr;
    assign gate_mar = DUT.control.store_mar_mux;
    assign load_pc = DUT.control.load_pc;


task automatic check_store(input logic [15:0] pc_after, input logic [15:0] expected, input string name);
    // PC == (instr addr + 2) means the next fetch started, so the store finished
    wait (DUT.pc.PC_OUT == pc_after);
    @(posedge sys_clk); #1;
    if (DUT.mio.ram['h3070] !== expected)
        $error("%s FAILED: mem[x3070]=%h, expected %h", name, DUT.mio.ram['h3070], expected);
    else
        $display("%s passed: mem[x3070]=%h", name, expected);
endtask

task automatic check_reg(input int n, input logic [15:0] expected, input string name);
    if (DUT.rb.bank[n] !== expected)
        $error("%s FAILED: R%0d=%h, expected %h", name, n, DUT.rb.bank[n], expected);
    else
        $display("%s passed: R%0d=%h", name, n, expected);
endtask

task automatic check_mem(input logic [15:0] addr, input logic [15:0] expected, input string name);
    if (DUT.mio.ram[addr] !== expected)
        $error("%s FAILED: mem[%h]=%h, expected %h", name, addr, DUT.mio.ram[addr], expected);
    else
        $display("%s passed: mem[%h]=%h", name, addr, expected);
endtask

task automatic reset_cpu(input logic [15:0] start);
    rst_n = 0;
    #10;
    rst_n = 1;
    DUT.pc.PC_OUT = start;
endtask


task automatic test_st_all;
    reset_cpu('h3000);
    DUT.rb.bank[0] = 16'hEAEA;  // ST source
    DUT.rb.bank[1] = 16'h1111;  // STR source
    DUT.rb.bank[2] = 16'h3060;  // STR base (+16)
    DUT.rb.bank[3] = 16'h3333;  // STI source
    DUT.rb.bank[4] = 16'h3080;  // STR base (-16)
    DUT.rb.bank[5] = 16'h5555;  // STR source
    DUT.rb.bank[6] = 16'h6666;  // STI source

    // Program
    DUT.mio.ram['h3000] = 16'h306F; // ST  R0, #111
    DUT.mio.ram['h3001] = 16'h7290; // STR R1, R2, #16
    DUT.mio.ram['h3002] = 16'hB60D; // STI R3, #13
    DUT.mio.ram['h3003] = 16'h7B30; // STR R5, R4, #-16
    DUT.mio.ram['h3004] = 16'hBC0C; // STI R6, #12
    DUT.mio.ram['h3005] = 16'h0FFF; // BRnzp #-1 (halt)

    // Pointers for STI
    DUT.mio.ram['h3010] = 16'h3070;
    DUT.mio.ram['h3011] = 16'h3070;
    DUT.mio.ram['h3070] = 16'h0000;

    check_store(16'h3002, 16'hEAEA, "ST");
    check_store(16'h3003, 16'h1111, "STR +16");
    check_store(16'h3004, 16'h3333, "STI R3");
    check_store(16'h3005, 16'h5555, "STR -16");
    check_store(16'h3006, 16'h6666, "STI R6");
endtask



task automatic run_cycles(input int n);
    repeat (n) @(posedge sys_clk);
endtask

task automatic run_until_halt();
    while (DUT.pc.PC_OUT != 'h9926) begin
        @(posedge sys_clk);
    end
endtask

task automatic test_jsr;
    reset_cpu(16'h3000);
    DUT.rb.bank[3] = 16'h8000;
    DUT.rb.bank[4] = 16'h1234;
    DUT.rb.bank[5] = 16'h3070;
    DUT.rb.bank[7] = 16'hFFFF;     // so an R7 write is visible

    DUT.mio.ram['h3000] = 16'h4807; // JSR #7        -> x3008
    DUT.mio.ram['h3001] = 16'h16E1; // ADD R3,R3,#1  (runs after the return)
    DUT.mio.ram['h3002] = 16'h0000; // no-op end marker
    DUT.mio.ram['h3008] = 16'h7940; // STR R4, R5, #0
    DUT.mio.ram['h3009] = 16'hC1C0; // RET (JMP R7)

    wait (DUT.pc.PC_OUT == 16'h3002);
    run_cycles(15);

    check_reg(7, 16'h3001, "JSR link");
    check_reg(3, 16'h8001, "JSR returned to x3001");
    check_mem(16'h3070, 16'h1234, "JSR target ran");
endtask

task automatic test_jsrr;
    reset_cpu(16'h3000);
    DUT.rb.bank[3] = 16'h0000;
    DUT.rb.bank[4] = 16'h0000;
    DUT.rb.bank[6] = 16'h3008;
    DUT.rb.bank[7] = 16'hFFFF;

    DUT.mio.ram['h3000] = 16'h4180; // JSRR R6     -> x3008
    DUT.mio.ram['h3001] = 16'h16E1; // ADD R3,R3,#1  (must be skipped)
    DUT.mio.ram['h3008] = 16'h1922; // ADD R4,R4,#2
    DUT.mio.ram['h3009] = 16'h0000; // no-op end marker

    wait (DUT.pc.PC_OUT == 16'h3009);
    run_cycles(15);

    check_reg(7, 16'h3001, "JSRR link");
    check_reg(3, 16'h0000, "JSRR skipped x3001");
    check_reg(4, 16'h0002, "JSRR target ran");
endtask

task automatic test_jmp;
    reset_cpu(16'h3000);
    DUT.rb.bank[3] = 16'h0000;
    DUT.rb.bank[4] = 16'h0000;
    DUT.rb.bank[5] = 16'h3008;
    DUT.rb.bank[7] = 16'h1234;     // must stay unchanged

    DUT.mio.ram['h3000] = 16'hC140; // JMP R5     -> x3008
    DUT.mio.ram['h3001] = 16'h16E1; // ADD R3,R3,#1  (must be skipped)
    DUT.mio.ram['h3008] = 16'h1922; // ADD R4,R4,#2
    DUT.mio.ram['h3009] = 16'h0000; // no-op end marker

    wait (DUT.pc.PC_OUT == 16'h3009);
    run_cycles(15);

    check_reg(7, 16'h1234, "JMP left R7 alone");
    check_reg(3, 16'h0000, "JMP skipped x3001");
    check_reg(4, 16'h0002, "JMP target ran");
endtask


task automatic test_lea;
    reset_cpu(16'h3000);

    DUT.mio.ram['h3000] = 16'hE203; // LEA R1, #3   -> PC(x3001)+3 = x3004
    DUT.mio.ram['h3001] = 16'hE5FE; // LEA R2, #-2  -> PC(x3002)-2 = x3000
    DUT.mio.ram['h3002] = 16'h0FFF; // halt

    run_cycles(25);
    check_reg(1, 16'h3004, "LEA +3");
    check_reg(2, 16'h3000, "LEA -2");
endtask

task automatic test_ld;
    reset_cpu(16'h3000);

    DUT.mio.ram['h3010] = 16'hABCD;
    DUT.mio.ram['h3000] = 16'h220F; // LD R1, #15   -> x3001+15 = x3010
    DUT.mio.ram['h3001] = 16'h0FFF; // halt

    run_cycles(25);
    check_reg(1, 16'hABCD, "LD");
endtask

task automatic test_ldr;
    reset_cpu(16'h3000);
    DUT.rb.bank[1] = 16'h3100;

    DUT.mio.ram['h3102] = 16'h1357;
    DUT.mio.ram['h3000] = 16'h6442; // LDR R2, R1, #2
    DUT.mio.ram['h3001] = 16'h0FFF; // halt

    run_cycles(25);
    check_reg(2, 16'h1357, "LDR +2");
endtask

task automatic test_ldi;
    reset_cpu(16'h3000);

    DUT.mio.ram['h3010] = 16'h3100; // pointer
    DUT.mio.ram['h3100] = 16'h2468; // data
    DUT.mio.ram['h3000] = 16'hA60F; // LDI R3, #15  -> pointer at x3010
    DUT.mio.ram['h3001] = 16'h0FFF; // halt

    run_cycles(25);
    check_reg(3, 16'h2468, "LDI");
endtask

task automatic test_br;
    reset_cpu(16'h3000);
    DUT.rb.bank[0] = 16'h0010;
    DUT.rb.bank[3] = 16'hBEEF;

    DUT.mio.ram['h3000] = 16'h5420; // AND R2, R0, #0   -> R2=0, sets Z
    DUT.mio.ram['h3001] = 16'h0401; // BRz #1           -> taken, goes to x3003
    DUT.mio.ram['h3002] = 16'h1621; // ADD R3, R0, #1   -> must be skipped
    DUT.mio.ram['h3003] = 16'h1823; // ADD R4, R0, #3
    DUT.mio.ram['h3004] = 16'h0FFF; // halt

    run_cycles(25);
    check_reg(3, 16'hBEEF, "BRz taken (skipped ADD)");
    check_reg(4, 16'h0013, "BRz target executed");
endtask

task automatic test_long_program;
    reset_cpu(16'h3000);
    DUT.rb.bank[0] = 16'h0007;
    DUT.rb.bank[1] = 16'h0003;
    DUT.rb.bank[2] = 16'h000A;

    // Main program
    DUT.mio.ram['h3000] = 16'h1601; // ADD R3,R0,R1      R3 = 0x000A
    DUT.mio.ram['h3001] = 16'h18C2; // ADD R4,R3,R2      R4 = 0x0014
    DUT.mio.ram['h3002] = 16'h5B2F; // AND R5,R4,#15     R5 = 0x0004
    DUT.mio.ram['h3003] = 16'h9D7F; // NOT R6,R5         R6 = 0xFFFB
    DUT.mio.ram['h3004] = 16'h223B; // LD  R1,#0x3B      R1 = mem[x3040] = 0x0005
    DUT.mio.ram['h3005] = 16'hA64A; // LDI R3,#0x4A      R3 = mem[mem[x3050]] = 0xFFF0
    DUT.mio.ram['h3006] = 16'h16C0; // ADD R3,R3,R0      R3 = 0xFFF7
    DUT.mio.ram['h3007] = 16'h4818; // JSR #0x18         R7 = x3008, jump to x3020
    DUT.mio.ram['h3008] = 16'h54A0; // AND R2,R2,#0      R2 = 0
    DUT.mio.ram['h3009] = 16'h1484; // ADD R2,R2,R4      R2 = 0x002B
    DUT.mio.ram['h300A] = 16'h3655; // ST  R3,#0x55      mem[x3060] = 0xFFF7
    DUT.mio.ram['h300B] = 16'h1242; // ADD R1,R1,R2      R1 = 0x0030
    DUT.mio.ram['h300C] = 16'hE023; // LEA R0,#0x23      R0 = x3030
    DUT.mio.ram['h300D] = 16'h4000; // JSRR R0           R7 = x300E, jump to x3030
    DUT.mio.ram['h300E] = 16'h1B41; // ADD R5,R5,R1      R5 = 0x0030
    DUT.mio.ram['h300F] = 16'hBA42; // STI R5,#0x42      mem[mem[x3052]] = mem[x3070] = 0x0030
    DUT.mio.ram['h3010] = 16'h1485; // ADD R2,R2,R5      R2 = 0x005B
    DUT.mio.ram['h3011] = 16'hB440; // STI R2,#0x40      mem[x3070] = 0x005B
    DUT.mio.ram['h3012] = 16'hEC00; // LEA R6,#0         R6 = x3013
    DUT.mio.ram['h3013] = 16'hC180; // JMP R6            halt loop (x3013)

    // Subroutine 1 (x3020): R4 = R4*2 + 3
    DUT.mio.ram['h3020] = 16'h1904; // ADD R4,R4,R4
    DUT.mio.ram['h3021] = 16'h1923; // ADD R4,R4,#3
    DUT.mio.ram['h3022] = 16'hC1C0; // RET (JMP R7)

    // Subroutine 2 (x3030): R1 = R1 - 4
    DUT.mio.ram['h3030] = 16'h127C; // ADD R1,R1,#-4
    DUT.mio.ram['h3031] = 16'hC1C0; // RET (JMP R7)

    // Data
    DUT.mio.ram['h3040] = 16'h0005;
    DUT.mio.ram['h3042] = 16'hFFF0;
    DUT.mio.ram['h3050] = 16'h3042; // pointer for LDI
    DUT.mio.ram['h3052] = 16'h3070; // pointer for STI output
    DUT.mio.ram['h3070] = 16'h0000;

    // The halt JMP loops at x3013, so wait for the PC to reach x3014
    // (the fetch that follows the JMP), then let the JMP execute.
    wait (DUT.pc.PC_OUT == 16'h3014);
    run_cycles(10);

    check_reg(2, 16'h005B, "long: R2 final");
    check_reg(3, 16'hFFF7, "long: R3");
    check_reg(4, 16'h002B, "long: R4");
    check_reg(5, 16'h0030, "long: R5");
    check_reg(6, 16'h3013, "long: R6 halt target");
    check_reg(7, 16'h300E, "long: R7 link");
    check_mem(16'h3060, 16'hFFF7, "long: scratch");
    check_mem(16'h3070, 16'h005B, "long: output");
endtask



    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, integration_tb);
        assert (gate_pc == gate_pc);
        assert (gate_alu == gate_alu);
        assert (gate_mdr == gate_mdr);
        assert (gate_mar == gate_mar);
    end

    logic [15:0] read_val;
    assign read_val = DUT.mio.ram['h3070];

    initial begin
        sys_clk = 0;
        rst_n = 0;
        forever #5 sys_clk = ~sys_clk;
        //assert (unused == unused) 
        //else   $finish();
        //assert (unused2 == unused2) 
        //else   $finish();
        assert (load_pc == load_pc) 
        else   $finish();
        assert (read_val == read_val) 
        else   $finish();
    end


 

    initial begin

        // Build trap vector table
        for(shortint unsigned i = 0; i < 16'hff; i++) begin
            DUT.mio.ram['h0000 + i] = 16'h9900 + i;
        end

        DUT.mio.ram['h9925] = 'h0FFF; // trap x25 exit infinite loop

        reset_cpu(16'h0000);
        $readmemh("program.mem", DUT.mio.ram);
        run_until_halt();


        // test_st_all();
        // test_jmp();
        // test_jsr();
        // test_jsrr();
        // test_lea();
        // test_ld();
        // test_ldr();
        // test_ldi();
        // test_br();
        // test_long_program();

        


        $finish();
    end


initial begin
    #100000;
    $error("TIMEOUT: program did not finish");
    $finish();
end

endmodule




