`timescale 1ns/1ps
//`define ARM_POWER_AWARE

module main_control_ams_tb ();
 
parameter CLOCK_PERIOD_NS = 10;
  
  reg SDI1 = 0;
  reg CS1 = 1;
  reg clk, rst, WTA_VALID, BP_MUX_SAMPLED;
  reg [63:0] WTA_OUT, VSAB_OUT;
  reg [255:0] TRUE0, TRUE1;
  
  wire BUSY, SDO1, WTA_EN, TX_READY, RESETn, VSAF_EN, VSAB_EN, FP_PUn, BP_PUn, BP_MUX_READY;
  wire [63:0] WTA_SEL0, WTA_SEL1, LIT_SEL;
  wire [127:0] RWLF_pre;
  wire [255:0] RWLB_pre;
  wire [15:0] BP_MUX_SEL;
  wire [127:0] DRDN_WBLp, DRUPn_WBLp, DRDN_WBLn, DRUPn_WBLn;
  wire [255:0] WWL_pre;
  wire [31:0] PRNG_BITS;
  //wire [63:0] variable_mask;
  //wire [255:0] clause_mask;
  //wire [415:0] content;
  //wire [8:0] mode_select;
  //wire [4:0] state;
  wire [255:0] TRUE0_reg;
  wire [63:0] VAR_flipped;
  wire take_random_walk, random_walk_flag;
  reg [63:0] seed_init, var_init;
  
  reg WTA_TEST_MODE_SEL;
  reg FP_VSA_TEST_MODE_SEL;
  reg BP_VSA_TEST_MODE_SEL;
  reg BP_WTA_TEST_MODE_SEL;
  reg BP_MUX_TEST_MODE_SEL;
  reg PROG_MODE_SEL;
  reg SOLVE_MODE_SEL;
  reg PRNG_RESET_MODE_SEL;
  reg PRNG_TEST_MODE_SEL;
     
 main_control_ams UUTw1 (.clk(clk), .rst(rst), .CS1(CS1), .SDI1(SDI1), .WTA_TEST_MODE_SEL(WTA_TEST_MODE_SEL), .FP_VSA_TEST_MODE_SEL(FP_VSA_TEST_MODE_SEL), .BP_VSA_TEST_MODE_SEL(BP_VSA_TEST_MODE_SEL), .BP_WTA_TEST_MODE_SEL(BP_WTA_TEST_MODE_SEL), .BP_MUX_TEST_MODE_SEL(BP_MUX_TEST_MODE_SEL), .PROG_MODE_SEL(PROG_MODE_SEL), .SOLVE_MODE_SEL(SOLVE_MODE_SEL), .PRNG_RESET_MODE_SEL(PRNG_RESET_MODE_SEL), .PRNG_TEST_MODE_SEL(PRNG_TEST_MODE_SEL), .WTA_OUT(WTA_OUT), .WTA_VALID(WTA_VALID), .TRUE0(TRUE0), .TRUE1(TRUE1), .VSAB_OUT(VSAB_OUT), .BP_MUX_SAMPLED(BP_MUX_SAMPLED), .seed_init(seed_init), .var_init(var_init), .BUSY(BUSY), .SDO1(SDO1), .TX_READY(TX_READY), .random_walk_flag(random_walk_flag), .WTA_SEL0(WTA_SEL0), .WTA_SEL1(WTA_SEL1), .RWLF_pre(RWLF_pre), .RWLB_pre(RWLB_pre), .LIT_SEL(LIT_SEL), .BP_MUX_SEL(BP_MUX_SEL), .DRDN_WBLp(DRDN_WBLp), .DRUP_WBLp(DRUPn_WBLp), .DRDN_WBLn(DRDN_WBLn), .DRUP_WBLn(DRUPn_WBLn), .WWL_pre(WWL_pre), .PRNG_BITS(PRNG_BITS), .VSAF_EN(VSAF_EN), .VSAB_EN(VSAB_EN), .FP_PUn(FP_PUn), .BP_PUn(BP_PUn), .BP_MUX_READY(BP_MUX_READY), .WTA_EN(WTA_EN), .RESETn(RESETn), .TRUE0_reg(TRUE0_reg), .VAR_flipped(VAR_flipped), .take_random_walk(take_random_walk));
   
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
	  $dumpfile("main_control_ams.vcd");
	  $dumpvars(0, main_control_ams_tb.UUTw1);
	  $dumpoff;
      rst = 1'b0;
      WTA_VALID = 1'b0;
      WTA_OUT = 0;
      TRUE0 = 0;
      TRUE1 = 0;
      VSAB_OUT = 0;
      BP_MUX_SAMPLED = 1'b0;
      
      WTA_TEST_MODE_SEL = 0;
      FP_VSA_TEST_MODE_SEL = 0;
      BP_VSA_TEST_MODE_SEL = 0;
      BP_WTA_TEST_MODE_SEL = 0;
      BP_MUX_TEST_MODE_SEL = 0;
      PROG_MODE_SEL = 0;
      SOLVE_MODE_SEL = 0;
      PRNG_RESET_MODE_SEL = 0;
      PRNG_TEST_MODE_SEL = 0;
      //content = 0;
      #(CLOCK_PERIOD_NS);
      
      rst = 1'b1;
      
      #(3*CLOCK_PERIOD_NS);
      
      rst = 1'b0;
      #(0.1*CLOCK_PERIOD_NS);
      #(10*CLOCK_PERIOD_NS);
      
      //@(posedge clk);
      PRNG_RESET_MODE_SEL = 1;
	  seed_init = 64'hbb0d13043e49ea30;
      //content = 416'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb0d13043e49ea307;
      #(2*CLOCK_PERIOD_NS);
      PRNG_RESET_MODE_SEL = 0;
      
      #(4*CLOCK_PERIOD_NS);
      //@(posedge clk);
      SOLVE_MODE_SEL = 1;
	  var_init = 64'h000000000000000A;
      //content = 416'h0000000000000000000000000000000000000000000000000000000000000003000000000000000F0040008000000000000000A6;
      #(3*CLOCK_PERIOD_NS);
      SOLVE_MODE_SEL = 0;
	  $dumpon;
      #(0.8*CLOCK_PERIOD_NS);
      TRUE0 = 256'h000000000000000000F00000000000000F000000000000000000000000000001;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      
      #(1*CLOCK_PERIOD_NS);
      //PRNG_BITS = 28'h0000000;
      #(1*CLOCK_PERIOD_NS);
      VSAB_OUT = 64'h000000000F00000C;
      #(1*CLOCK_PERIOD_NS);
      VSAB_OUT = 64'h00000F000F000005;
      #(13*CLOCK_PERIOD_NS);
      WTA_VALID = 1'b1;
      WTA_OUT = 64'h0000000000000002;
      #(1*CLOCK_PERIOD_NS);
      WTA_VALID = 1'b0;
      WTA_OUT = 64'h0000000000000000;
	  
	  #(6*100*CLOCK_PERIOD_NS);
	  $finish;
    end
   
endmodule