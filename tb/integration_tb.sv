

module integration_tb;

    logic sys_clk;
    logic rst_n;
    logic[8:0] unused;
    logic[1:0] unused2;

    lc3 DUT (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .unused(unused),
        .unused2(unused2)
    );

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, integration_tb);
    end

    initial begin
        sys_clk = 0;
        rst_n = 0;
        forever #5 sys_clk = ~sys_clk;
        assert (unused == unused) 
        else   $finish();
        assert (unused2 == unused2) 
        else   $finish();
    end


    initial begin
        
        #10;
        rst_n = 1;
        // jump to 0x3000
        DUT.pc.PC_OUT = 16'h3000;

        DUT.mio.ram['h3000] = 'h5260;
        DUT.mio.ram['h3001] = 'h1261;
        DUT.mio.ram['h3002] = 'h1261;
        DUT.mio.ram['h3003] = 'h1261;
        DUT.mio.ram['h3004] = 'h1261;
        DUT.mio.ram['h3005] = 'h1261;
        DUT.mio.ram['h3006] = 'h1261;

        #250;


        $finish();
    end


endmodule

