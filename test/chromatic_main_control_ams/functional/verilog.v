`timescale 1ns/1ps
//`define ARM_POWER_AWARE

module chromatic_main_control_ams_tb ();
 
parameter CLOCK_PERIOD_NS = 5.5;
  
  reg SDI1 = 0;
  reg CS1 = 1;
  reg clk, rst, BP_MUX_SAMPLED;
  reg [63:0] VSAB_OUT;
  reg [255:0] TRUE0, TRUE1;
  
  wire BUSY, SDO1, TX_READY, VSAF_EN, VSAB_EN, FP_PUn, BP_PUn, BP_MUX_READY;
  wire [63:0] MAKE_SEL0, MAKE_SEL1, BREAK_SEL0, BREAK_SEL1;
  wire [127:0] RWLF_pre;
  wire [255:0] RWLB_pre;
  wire [15:0] BP_MUX_SEL;
  wire [127:0] DRDN_WBLp, DRUPn_WBLp, DRDN_WBLn, DRUPn_WBLn;
  wire [255:0] WWL_pre;
  
  wire [255:0] TRUE0_reg, TRUE1_reg;
  wire [63:0] VAR_flipped;
  reg [63:0] var_init;
  
  reg FP_VSA_TEST_MODE_SEL;
  reg BP_VSA_TEST_MODE_SEL;
  reg BP_MUX_TEST_MODE_SEL;
  reg PROG_MODE_SEL;
  reg SOLVE_MODE_SEL;
     
 chromatic_main_control_ams UUTw1 (.clk(clk), .rst(rst), .CS1(CS1), .SDI1(SDI1), .FP_VSA_TEST_MODE_SEL(FP_VSA_TEST_MODE_SEL), .BP_VSA_TEST_MODE_SEL(BP_VSA_TEST_MODE_SEL), .BP_MUX_TEST_MODE_SEL(BP_MUX_TEST_MODE_SEL), .PROG_MODE_SEL(PROG_MODE_SEL), .SOLVE_MODE_SEL(SOLVE_MODE_SEL), .TRUE0(TRUE0), .TRUE1(TRUE1), .VSAB_OUT(VSAB_OUT), .BP_MUX_SAMPLED(BP_MUX_SAMPLED), .var_init(var_init), .BUSY(BUSY), .SDO1(SDO1), .TX_READY(TX_READY), .RWLF_pre(RWLF_pre), .RWLB_pre(RWLB_pre), .MAKE_SEL0(MAKE_SEL0), .MAKE_SEL1(MAKE_SEL1), .BREAK_SEL0(BREAK_SEL0), .BREAK_SEL1(BREAK_SEL1), .BP_MUX_SEL(BP_MUX_SEL), .DRDN_WBLp(DRDN_WBLp), .DRUP_WBLp(DRUPn_WBLp), .DRDN_WBLn(DRDN_WBLn), .DRUP_WBLn(DRUPn_WBLn), .WWL_pre(WWL_pre), .VSAF_EN(VSAF_EN), .VSAB_EN(VSAB_EN), .FP_PUn(FP_PUn), .BP_PUn(BP_PUn), .BP_MUX_READY(BP_MUX_READY), .TRUE0_reg(TRUE0_reg), .TRUE1_reg(TRUE1_reg), .VAR_flipped(VAR_flipped));
   
  always
    begin
        clk = 1'b1;
        #(0.5*CLOCK_PERIOD_NS);
        clk = 1'b0;
        #(0.5*CLOCK_PERIOD_NS);
    end 
 
   
  // Main Testing:
  initial
    begin
       
	  //$sdf_annotate("/home/tinish/gint1/digital/build/main_control_ams/syn-rundir/main_control_ams.tt_nominal_max_1p20v_25c.extra_view.sdf", main_control_ams_tb.UUTw1, , , "maximum");
	  //$sdf_annotate("/home/tinish/gint1/digital/syn_trial/main_control_ams.mapped.sdf", main_control_ams_tb.UUTw1, , , "maximum");
	  $dumpfile("chromatic_main_control_ams.vcd");
	  $dumpvars(0, chromatic_main_control_ams_tb.UUTw1);
	  $dumpoff;
      rst = 1'b0;
      TRUE0 = 0;
      TRUE1 = 0;
      VSAB_OUT = 0;
      BP_MUX_SAMPLED = 1'b0;
      
      FP_VSA_TEST_MODE_SEL = 0;
      BP_VSA_TEST_MODE_SEL = 0;
      BP_MUX_TEST_MODE_SEL = 0;
      PROG_MODE_SEL = 0;
      SOLVE_MODE_SEL = 0;
      //content = 0;
      #(CLOCK_PERIOD_NS);
      
      rst = 1'b1;
      
      #(3*CLOCK_PERIOD_NS);
      
      rst = 1'b0;
      #(0.1*CLOCK_PERIOD_NS);
      #(10*CLOCK_PERIOD_NS);
      
      
      SOLVE_MODE_SEL = 1;
	  var_init = 64'h000000000000000A;
      #(3*CLOCK_PERIOD_NS);
      SOLVE_MODE_SEL = 0;
	  $dumpon;
      #(0.8*CLOCK_PERIOD_NS);
      TRUE0 = 256'h000000000000000000F00000000000000F000000000000000000000000000001;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      #(2*CLOCK_PERIOD_NS);
      VSAB_OUT = 64'h000000000F00000C;
      #(2*CLOCK_PERIOD_NS);
	  TRUE0 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000001;
	  #(4*100*CLOCK_PERIOD_NS);
	  $finish;
    end
   
endmodule