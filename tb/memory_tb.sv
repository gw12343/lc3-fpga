// Memory testbench for the LC3 computer.
// 11/9/2026
// Gabriel West
// gwest9@illinois.edu


module memory_tb;
    logic sys_clk;
    logic rst_n;

    logic load_mar;
    logic load_mdr;
    logic w_nr;
    logic mio_enable;
    logic[15:0] BUS_IN;
    logic ready;
    logic[15:0] mdr_reg;

    mio_controller DUT (
        .sys_clk   (sys_clk),
        .rst_n     (rst_n),
        .load_mdr  (load_mdr),
        .load_mar  (load_mar),
        .w_nr      (w_nr),
        .mio_enable(mio_enable),
        .BUS_IN    (BUS_IN),
        .ready     (ready),
        .mdr_reg   (mdr_reg)
    );

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, memory_tb);
    end

    initial begin
        rst_n = 0;
        sys_clk = 0;

        forever #5 sys_clk = ~sys_clk;
    end

    initial begin
        load_mar = 0;
        load_mdr = 0;
        w_nr = 0;
        mio_enable = 0;
        BUS_IN = '0;
        
        #10;
        rst_n = 1;

        #30;

        $monitor("ready: %d    val: %04h", ready, mdr_reg);


        $finish();
    end


endmodule
