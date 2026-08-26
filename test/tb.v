`default_nettype none
`timescale 1ns / 1ps

module tb ();
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
        #1;
    end

    reg  clk;
    reg  rst_n;
    reg  ena;
    reg  [7:0] ui_in;
    reg  [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    tt_um_npu_core user_project (
        .ui_in  (ui_in),    
        .uo_out (uo_out),   
        .uio_in (uio_in),   
        .uio_out(uio_out),  
        .uio_oe (uio_oe),   
        .ena    (ena),      
        .clk    (clk),      
        .rst_n  (rst_n)     
    );

`ifdef GL_TEST
    // -------------------------------------------------------------
    // THE GLS POWER HACK:
    // OpenLane sometimes leaves global power nets unconnected in the 
    // simulation netlist. We force the nets to 1 (Power) and 0 (Ground).
    // -------------------------------------------------------------
    initial begin
        #1; // Wait 1ns for the netlist to instantiate
        
        // Try forcing standard SkyWater global nets
        $deposit(tb.user_project.VGND, 1'b0);
        $deposit(tb.user_project.VPWR, 1'b1);
        
    end
`endif

endmodule
