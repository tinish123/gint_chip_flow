`timescale 1ns/1ps
 
module main_control_tb ();
 
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
  
   
  task UART_WRITE_BYTE;
    input [415:0] i_Data;
    integer     ii;
    begin
      #(0.1);
      CS1 <= 1'b0;
      for (ii=415; ii>=0; ii=ii-1)
        begin
          SDI1 <= i_Data[ii];
          #(CLOCK_PERIOD_NS);
        end
      
      CS1 <= 1'b1;
     end
  endtask // UART_WRITE_BYTE
     
 main_control UUT (clk,rst,CS1,SDI1,WTA_OUT,WTA_VALID,TRUE0,TRUE1,VSAB_OUT,BP_MUX_SAMPLED,BUSY,SDO1,TX_READY,WTA_SEL0,WTA_SEL1,RWLF_pre,RWLB_pre,LIT_SEL,BP_MUX_SEL,DRDN_WBLp,DRUPn_WBLp,DRDN_WBLn,DRUPn_WBLn,WWL_pre,VSAF_EN,VSAB_EN,FP_PUn,BP_PUn,BP_MUX_READY,WTA_EN,RESETn);
   
  always
    begin
        clk = 1'b1;
        #(0.5*CLOCK_PERIOD_NS);
        clk = 1'b0;
        #(0.5*CLOCK_PERIOD_NS);
    end 
 
   
  initial
    begin
	
	$sdf_annotate("/home/tinish/gint1/digital/build/main_control/syn-rundir/main_control.tt_nominal_max_1p20v_25c.extra_view.sdf", main_control_tb.UUT, , , "maximum");
	//$sdf_annotate("/home/tinish/gint1/digital/syn_trial/main_control.mapped.sdf", main_control_tb.UUT, , , "maximum");
       
      rst = 1'b0;
      WTA_VALID = 1'b0;
      WTA_OUT = 0;
      TRUE0 = 0;
      TRUE1 = 0;
      VSAB_OUT = 0;
      BP_MUX_SAMPLED = 1'b0;
      
      #(CLOCK_PERIOD_NS);
      
      rst = 1'b1;
      
      #(3*CLOCK_PERIOD_NS);
      
      rst = 1'b0;
      
      #(10*CLOCK_PERIOD_NS);
      
      //WTA TEST mode
//      UART_WRITE_BYTE(416'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000810);
//      #(2.8*CLOCK_PERIOD_NS);
//      WTA_VALID = 1'b1;
//      WTA_OUT = 2;
//      @(posedge clk);
//      #(300*CLOCK_PERIOD_NS);
      
      //FP VSA TEST mode
//      UART_WRITE_BYTE(416'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F1);
//      #(2.8*CLOCK_PERIOD_NS);
//      TRUE0[7:0] = 8'hF1;
//      @(posedge clk);
//      #(300*CLOCK_PERIOD_NS);
      
      //BP VSA TEST mode
//      UART_WRITE_BYTE(416'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F2);
//      #(2.8*CLOCK_PERIOD_NS);
//      VSAB_OUT[7:0] = 8'hF1;
//      @(posedge clk);
//      #(300*CLOCK_PERIOD_NS);
      
      //BP WTA TEST mode
//      UART_WRITE_BYTE(416'h00000000F0000F00F0000FF0000F000F00000F000000000000F00000F00000000000000000000000000B00000F0000F00000F0F3);
//      #(2.8*CLOCK_PERIOD_NS);
//      WTA_VALID = 1'b1;
//      WTA_OUT = 2;
//      @(posedge clk);
//      #(300*CLOCK_PERIOD_NS);
      
      //BP MUX TEST mode
//      UART_WRITE_BYTE(416'h000000000000000000000000000000000000001000000000000000000F00000000000000F0000000000000000000000000000034);
//      #(10*CLOCK_PERIOD_NS);
//      BP_MUX_SAMPLED = 1'b1;
//      #(2*CLOCK_PERIOD_NS);
//      BP_MUX_SAMPLED = 1'b0;
//      @(posedge clk);
//      #(300*CLOCK_PERIOD_NS);
      
      //PROG mode
//      UART_WRITE_BYTE(416'h00000000000000000000000000000000000000000000000000000000000000002020200000000000F00000C000000000F00000C5);
//      @(posedge clk);
//      #(300*CLOCK_PERIOD_NS);
      
      //PRNG RESET mode
      UART_WRITE_BYTE(416'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb0d13043e49ea307);
      @(posedge clk);
      #(300*CLOCK_PERIOD_NS);
      
      //PRNG TEST mode
//      UART_WRITE_BYTE(416'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb0d13043e49ea308);
//      @(posedge clk);
//      #(300*CLOCK_PERIOD_NS);
      
      //SOLVE mode
      UART_WRITE_BYTE(416'h0000000003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0003FFFFFFFFFFFF800FFFF000000000000000A6);
      @(posedge clk);
      #(1.8*CLOCK_PERIOD_NS);
      TRUE0 = 256'h000000000000000000F00000000000000F000000000000000000000000000001;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      #(2*CLOCK_PERIOD_NS);
      VSAB_OUT = 64'h000000000F00000C;
      #(1*CLOCK_PERIOD_NS);
      VSAB_OUT = 64'h00000F000F000005;
      #(13*CLOCK_PERIOD_NS);
      WTA_VALID = 1'b1;
      WTA_OUT = 64'h0000000000000002;
      #(1*CLOCK_PERIOD_NS);
      WTA_VALID = 1'b0;
      WTA_OUT = 64'h0000000000000000;
      
    end
   
endmodule
