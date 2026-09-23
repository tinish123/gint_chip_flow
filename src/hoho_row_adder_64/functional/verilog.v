`timescale 1ns / 1ps

module hoho_row_adder_64(input clk,
  input rst,
  input wire [127:0] triplet1_u,
  input wire [127:0] triplet1_b,
  input wire [127:0] triplet2_u,
  input wire [127:0] triplet2_b,
  input wire [127:0] triplet3_u,
  input wire [127:0] triplet3_b,
  input wire [127:0] triplet4_u,
  input wire [127:0] triplet4_b,
  input wire [127:0] triplet5_u,
  input wire [127:0] triplet5_b,
  input wire [127:0] triplet6_u,
  input wire [127:0] triplet6_b,
  input wire [127:0] triplet7_u,
  input wire [127:0] triplet7_b,
  input wire [127:0] triplet8_u,
  input wire [127:0] triplet8_b,
  input wire [63:0] variable_value,
  output wire [319:0] make_value,
  output wire [319:0] break_value);
  
genvar n1;
generate 

    for (n1=0; n1<64; n1=n1+1) begin
        hoho_unit_cell_row_adder UUT_hoho_unit_cell_row_adder (clk,rst,triplet1_u[2*n1+1:2*n1],triplet1_b[2*n1+1:2*n1],triplet2_u[2*n1+1:2*n1],triplet2_b[2*n1+1:2*n1],triplet3_u[2*n1+1:2*n1],triplet3_b[2*n1+1:2*n1],triplet4_u[2*n1+1:2*n1],triplet4_b[2*n1+1:2*n1],triplet5_u[2*n1+1:2*n1],triplet5_b[2*n1+1:2*n1],triplet6_u[2*n1+1:2*n1],triplet6_b[2*n1+1:2*n1],triplet7_u[2*n1+1:2*n1],triplet7_b[2*n1+1:2*n1],triplet8_u[2*n1+1:2*n1],triplet8_b[2*n1+1:2*n1],variable_value[n1],make_value[5*n1+4:5*n1],break_value[5*n1+4:5*n1]);
    end
    
endgenerate

endmodule
