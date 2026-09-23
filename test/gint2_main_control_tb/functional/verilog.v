`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2025 11:09:37 PM
// Design Name: 
// Module Name: main_control_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module main_control_tb();

  parameter CLOCK_PERIOD_NS1 = 10;
  parameter CLOCK_PERIOD_NS2 = 20;
  
  reg SDI1 = 0;
  reg CS1 = 1;
  reg CS2 = 1;
  reg clk, clk2, rst, START;
  reg [63:0] PBIT_OUT, VSAB_OUT;
  reg [255:0] TRUE0, TRUE1;
  reg [255:0] o_Data;
  
  wire BUSY, SDO1, PBIT_EN, VSAF_EN, VSAB_EN, FP_PUn;
  wire [63:0] PBIT_SEL, MB_SEL;
  wire [127:0] RWLF_pre, BP_PUnS, BP_PUnZ;
  wire [255:0] RWLBS_pre, RWLBZ_pre;
  wire [127:0] DRDN_WBLp, DRUPn_WBLp, DRDN_WBLn, DRUPn_WBLn;
  wire [255:0] WWL_pre;
  wire [63:0] rn0, rn1, rn2, rn3, rp0, rp1, rp2, rp3;
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
  
  
  task UART_WRITE_BYTE_NEW;
    input [543:0] i_Data;
    integer     ii;
    begin
      CS1 <= 1'b0;
      for (ii=543; ii>=0; ii=ii-1)
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
  
 main_control UUT (clk,rst,CS1,SDI1,clk2,START,CS2,PBIT_OUT,TRUE0,TRUE1,VSAB_OUT,BUSY,SDO1,PBIT_SEL,rn0,rn1,rn2,rn3,rp0,rp1,rp2,rp3,RWLF_pre,RWLBS_pre,RWLBZ_pre,MB_SEL,BP_PUnS,BP_PUnZ,DRDN_WBLp,DRUPn_WBLp,DRDN_WBLn,DRUPn_WBLn,WWL_pre,VSAF_EN,VSAB_EN,FP_PUn,PBIT_EN);
   
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
	
	$sdf_annotate("/home/tinish/gint1/digital/build/gint2_control/par-rundir/main_control.par.sdf", main_control_tb.UUT, , , "maximum");
	//$sdf_annotate("/home/tinish/gint1/digital/build/gint2_control/syn-rundir/main_control.mapped.sdf", main_control_tb.UUT, , , "maximum");
       
      rst = 1'b0;
      PBIT_OUT = 0;
      TRUE0 = 0;
      TRUE1 = 0;
      VSAB_OUT = 0;
      START = 1'b0;
      
      #(CLOCK_PERIOD_NS2);
      
      rst = 1'b1;
      
      #(3*CLOCK_PERIOD_NS2);
      
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
      
      //PBIT TEST EXT mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'h00000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111960);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(0.7*CLOCK_PERIOD_NS1);
      PBIT_OUT = 64'h1111111111111111;
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
      #(7*CLOCK_PERIOD_NS1);
      rst = 1'b1;
      #(3*CLOCK_PERIOD_NS2);
      rst = 1'b0;
            //PBIT TEST INT mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'hFF00F0000000000000000000000000000000000000000000000000000000000000000000000000F0F0F0F1111111111111111963);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(0.7*CLOCK_PERIOD_NS1);
      PBIT_OUT = 64'h1011111111111101;
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
      #(7*CLOCK_PERIOD_NS1);
      rst = 1'b1;
      #(3*CLOCK_PERIOD_NS2);
      rst = 1'b0;
      
                  //BP VSA TEST mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'hFF00F0000000000000000000000000000000000000000000000000000000000000000000000000F0F0F0F1111111111111111002);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(0.7*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h1011111111111101;
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
      #(7*CLOCK_PERIOD_NS1);
      rst = 1'b1;
      #(3*CLOCK_PERIOD_NS2);
      rst = 1'b0;
      
                        //FP VSA TEST mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'hFF00F000000000000000000000000000000000000000000000000000000000000000001FFFFFFFFFFFFFFFF11111111111111111);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(0.7*CLOCK_PERIOD_NS1);
      TRUE0 = 64'h1011111111111101;
      TRUE1 = 64'h0101111111111010;
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
      #(7*CLOCK_PERIOD_NS1);
      rst = 1'b1;
      #(3*CLOCK_PERIOD_NS2);
      rst = 1'b0;
      
      ////PRNG RESET mode
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
      
      ////PRNG TEST mode
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
      
      
            ////PRNG TEST mode
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
      
      #(7*CLOCK_PERIOD_NS1);
      rst = 1'b1;
      #(3*CLOCK_PERIOD_NS2);
      rst = 1'b0;
      
            ////PROG mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE(416'h0000000000000000000000000000000000000000000000000000000000000000202020F000000000F00000C000000000F00000C5);
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
      #(7*CLOCK_PERIOD_NS1);
      rst = 1'b1;
      #(3*CLOCK_PERIOD_NS2);
      rst = 1'b0;      
      
      ////SOLVE mode init var sent in via serial
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE_NEW({64'h000000000000001A,64'h000000000000001A,64'h000000000000001A,7'b0000001,256'h00000000000000000000000000000000000000000000000000000000000000FF,64'h000000000000000F,20'h00010,4'h6});
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(7.6*CLOCK_PERIOD_NS1);
      TRUE0 = 256'h000000000000000000F00000000000000F000000000000000000000000000001;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h000000000F00000C;
      PBIT_OUT = 64'h00000000000CC002;
      @(posedge clk);
      #(1.6*CLOCK_PERIOD_NS1);
      TRUE0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h000000000F00000C;
      PBIT_OUT = 64'h00000000000CC002;
      @(posedge clk);
      
      #(7*CLOCK_PERIOD_NS1);
      rst = 1'b1;
      #(3*CLOCK_PERIOD_NS2);
      rst = 1'b0;      
      
      
      ////SOLVE mode init var generated using RNG
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE_NEW({64'h000000000000001A,64'h000000000000001A,64'h000000000000001A,7'b0000001,256'h00000000000000000000000000000000000000000000000000000000000000FF,64'h000000000000000F,20'h00011,4'h6});
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(7.6*CLOCK_PERIOD_NS1);
      TRUE0 = 256'h000000000000000000F00000000000000F000000000000000000000000000001;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h000000000F00000C;
      PBIT_OUT = 64'h00000000000CC002;
      @(posedge clk);
      #(1.6*CLOCK_PERIOD_NS1);
      TRUE0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h000000000F00000C;
      PBIT_OUT = 64'h00000000000CC002;
      @(posedge clk);
      
      #(7*CLOCK_PERIOD_NS1);
      rst = 1'b1;
      #(3*CLOCK_PERIOD_NS2);
      rst = 1'b0;      
      
      
      ////SOLVE mode init var sent via serial comm but parallel trials
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE_NEW({64'h000000000000001C,64'h000000000000001B,64'h000000000000001A,7'b0000001,256'h00000000000000000000000000000000000000000000000000000000000000FF,64'h000000000000000F,20'h00012,4'h6});
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(7.6*CLOCK_PERIOD_NS1);
      TRUE0 = 256'h000000000000000000F00000000000000F000000000000000000000000000001;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h000000000F00000C;
      PBIT_OUT = 64'h00000000000CC003;
      @(posedge clk);
      #(2.6*CLOCK_PERIOD_NS1);
      TRUE0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h000000000F00000C;
      PBIT_OUT = 64'h00000000000CC002;
      @(posedge clk);
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
      #(7*CLOCK_PERIOD_NS1);
      rst = 1'b1;
      #(3*CLOCK_PERIOD_NS2);
      rst = 1'b0;   
      
            ////SOLVE mode init var sent via serial comm but parallel trials + single flip mode
      @(posedge clk2);
      #(0.7*CLOCK_PERIOD_NS2);
      UART_WRITE_BYTE_NEW({64'h000000000000001C,64'h000000000000001B,64'h000000000000001A,7'b0000011,256'h00000000000000000000000000000000000000000000000000000000000000FF,64'h000000000000000F,20'h00012,4'h4});
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      START = 1'b1;
      #(CLOCK_PERIOD_NS1);
      START = 1'b0;
      @(posedge clk);
      #(7.6*CLOCK_PERIOD_NS1);
      TRUE0 = 256'h000000000000000000F00000000000000F000000000000000000000000000001;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h000000000F00000C;
      PBIT_OUT = 64'h00000000000CC003;
      @(posedge clk);
      #(2.6*CLOCK_PERIOD_NS1);
      TRUE0 = 256'h0000000000000000000000000000000000000000000000000000000000000001;
      TRUE1 = 256'h000000000000000000F00000000000000F000000000000000000000000000002;
      @(posedge clk);
      #(0.6*CLOCK_PERIOD_NS1);
      VSAB_OUT = 64'h000000000F00000C;
      PBIT_OUT = 64'h00000000000CC002;
      @(posedge clk);
      @(negedge BUSY);
      @(posedge clk2);
      #(0.6*CLOCK_PERIOD_NS2);
      UART_RECEIVE_BYTE();
      
    end

endmodule
