`timescale 1ns/1ps
 
module GINT1AChipletTop_tb ();
 
  parameter CLOCK_PERIOD_NS1 = 20;
  parameter CLOCK_PERIOD_NS2 = 100;
  
  reg SDI1 = 0;
  reg CS1 = 1;
  reg CS2 = 1;
  reg clk, clk2, rst, WTA_VALID, BP_MUX_SAMPLED, START;
  reg [63:0] WTA_OUT, VSAB_OUT;
  reg [255:0] TRUE0, TRUE1;
  reg [255:0] o_Data;
  
  wire BUSY, SDO1, WTA_EN, RESETn, VSAF_EN, VSAB_EN, FP_PUn, BP_PUn, BP_MUX_READY;
  wire [63:0] WTA_SEL0, WTA_SEL1, LIT_SEL;
  wire [127:0] RWLF_pre;
  wire [255:0] RWLB_pre;
  wire [15:0] BP_MUX_SEL;
  wire [127:0] DRDN_WBLp, DRUPn_WBLp, DRDN_WBLn, DRUPn_WBLn;
  wire [255:0] WWL_pre;
  //wire [31:0] PRNG_BITS;
  //wire [255:0] content_out;
  
   
  task UART_WRITE_BYTE;
    input [415:0] i_Data;
    integer     ii;
    begin
      CS1 <= 1'b0;
      for (ii=415; ii>=0; ii=ii-1)
        begin
          SDI1 <= i_Data[ii];
          #(CLOCK_PERIOD_NS2);
        end
      
      CS1 <= 1'b1;
     end
  endtask // UART_WRITE_BYTE
  
  task UART_RECEIVE_BYTE;
    integer     ii;
    begin
      CS2 <= 1'b0;
      for (ii=255; ii>=0; ii=ii-1)
        begin
          @(posedge clk2);
          o_Data[ii] <= SDO1;
        end
      CS2 <= 1'b1;
     end
  endtask // UART_WRITE_BYTE
   
   GINT1AChipletTop UUT (clk,clk2,TRUE0,TRUE1,VSAB_OUT,WTA_OUT,WTA_VALID,rst,CS1,SDI1,BP_MUX_SAMPLED,START,CS2,BUSY,SDO1,BP_MUX_READY,,,,,,,,,,,,,,,VSAF_EN,VSAB_EN,FP_PUn,BP_PUn,WTA_EN,RESETn,RWLF_pre,RWLB_pre,WTA_SEL0,WTA_SEL1,LIT_SEL,BP_MUX_SEL,DRDN_WBLp,DRDN_WBLn,DRUPn_WBLp,DRUPn_WBLn,WWL_pre);
	
  always
    begin
        clk = 1'b1;
        #(0.5*CLOCK_PERIOD_NS1);
        clk = 1'b0;
        #(0.5*CLOCK_PERIOD_NS1);
    end
    
  always
    begin
        clk2 = 1'b1;
        #(0.5*CLOCK_PERIOD_NS2);
        clk2 = 1'b0;
        #(0.5*CLOCK_PERIOD_NS2);
    end 
 
   
  initial
    begin
	
	$sdf_annotate("/home/tinish/gint1/digital/src/GINT1AChipletTop_sim/sdf/GINT1AChipletTop.par.sdf", GINT1AChipletTop_tb.UUT, , , "maximum");
	//$sdf_annotate("/home/tinish/gint1/digital/build/main_control_new/syn-rundir/main_control_new.tt_nominal_max_1p20v_25c.extra_view.sdf", GINT1AChipletTop_tb.UUT, , , "maximum");
	//$sdf_annotate("/home/tinish/gint1/digital/syn_trial/main_control_new.mapped.sdf", GINT1AChipletTop_tb.UUT, , , "maximum");
       
      rst = 1'b0;
      WTA_VALID = 1'b0;
      WTA_OUT = 0;
      TRUE0 = 0;
      TRUE1 = 0;
      VSAB_OUT = 0;
      BP_MUX_SAMPLED = 1'b0;
      START = 1'b0;
      
      #(CLOCK_PERIOD_NS2);
      
      rst = 1'b1;
      
      #(30*CLOCK_PERIOD_NS2);
      
      rst = 1'b0;
      
      #(10*CLOCK_PERIOD_NS1);
      
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
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb0d13043e49ea307);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
      //PRNG TEST mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb0d13043e49ea308);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
	  
	  
	  //PROG mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'h00000000000000000000000000000000000000000000000000000000000000002020200000000000F00000C000000000F00000C5);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
      
            //BP WTA TEST mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'h00000000F0000F00F0000FF0000F000F00000F000000000000F00000F00000000000000000000000000B00000F0000F00000F0F3);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(2.8*CLOCK_PERIOD_NS1);
      WTA_VALID = 1'b1;
      WTA_OUT = 2;
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
      
      //SOLVE mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'h0000000003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0003FFFFFFFFFFFF800FFFF000000000000000A6);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(1.8*CLOCK_PERIOD_NS1);
      TRUE0 = 256'h000000000000000000F00000000000000F000000000000000000000000000001;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      #(2*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h000000000F00000C;
      #(1*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h00000F000F000005;
      #(13*CLOCK_PERIOD_NS1);
      WTA_VALID = 1'b1;
      WTA_OUT = 64'h0000000000000002;
      #(1*CLOCK_PERIOD_NS1);
      WTA_VALID = 1'b0;
      WTA_OUT = 64'h0000000000000000;
      
    end
   
endmodule