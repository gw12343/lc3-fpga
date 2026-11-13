

module integration_tb;

    logic sys_clk;
    logic rst_n;
    logic[8:0] unused;
    logic[1:0] unused2;

    logic gate_pc;
    logic gate_alu;
    logic gate_mdr;
    logic gate_mar;
    logic load_pc;
    

    lc3 DUT (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .unused(unused),
        .unused2(unused2)
    );

    assign gate_pc = DUT.control.store_pc;
    assign gate_alu = DUT.control.store_alu;
    assign gate_mdr = DUT.control.store_mdr;
    assign gate_mar = DUT.control.store_mar_mux;
    assign load_pc = DUT.control.load_pc;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, integration_tb);
        assert (gate_pc == gate_pc);
        assert (gate_alu == gate_alu);
        assert (gate_mdr == gate_mdr);
        assert (gate_mar == gate_mar);
    end

    initial begin
        sys_clk = 0;
        rst_n = 0;
        forever #5 sys_clk = ~sys_clk;
        assert (unused == unused) 
        else   $finish();
        assert (unused2 == unused2) 
        else   $finish();
        assert (load_pc == load_pc) 
        else   $finish();
    end


    initial begin
        
        #10;
        rst_n = 1;
        // jump to 0x3000
        DUT.pc.PC_OUT = 16'h3000;

        DUT.rb.bank[0] = 1;
        DUT.rb.bank[1] = 2;
        DUT.rb.bank[2] = 3;
        DUT.rb.bank[3] = 4;

        // Example trap vector table
        for(shortint unsigned i = 0; i < 16'hff; i++) begin
            DUT.mio.ram['h0000 + i] = 16'h9900 + i;
        end

        // Test program 
        DUT.mio.ram['h3000] = 'h202F; // LD  R0, x3030     ; R0 = mem[x3030] = x3040
        DUT.mio.ram['h3001] = 'h6202; // LDR R1, R0, #2    ; R1 = mem[R0 + 2] = mem[x3042]
        DUT.mio.ram['h3002] = 'hA44D; // LDI R2, x3050     ; R2 = mem[mem[x3050]]
        DUT.mio.ram['h3003] = 'hF025; // HALT (TRAP x25)

        DUT.mio.ram['h3030] = 'h3040; // pointer for R0
        DUT.mio.ram['h3042] = 'hBEEF; // data for LDR
        DUT.mio.ram['h3050] = 'h3060; // LDI pointer (address of the data)
        DUT.mio.ram['h3060] = 'hCAFE; // LDI data

        


        //DUT.mio.ram['h3000] = 'h5260; // r1 <- r1 & 0
        // DUT.mio.ram['h3001] = 'h1262; // r1 <- r1 + 1
        // DUT.mio.ram['h3002] = 'h1262; // r1 <- r1 + 1
        // DUT.mio.ram['h3003] = 'h927F; // r1 <- not r1
        // DUT.mio.ram['h3004] = 'h1262; // r1 <- r1 + 2
        //DUT.mio.ram['h3001] = 'hF025; // trap halt (should go to x2f25)

        #1000;


        $finish();
    end


endmodule

