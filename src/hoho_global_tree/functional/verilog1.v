`timescale 1ns / 1ps

module hoho_global_tree(input clk,
  input rst,
  input wire [367:0] Din,
  input wire [14:0] PRNG,
  input wire RND,
  output wire [255:0] Aout);

wire [183:0] Dout_l1;
wire [91:0] Dout_l2;
wire [45:0] Dout_l3;
wire [22:0] Dout_l4;

wire [127:0] Aout_l2;
wire [63:0] Aout_l3;
wire [31:0] Aout_l4;


genvar n1;
genvar n2;
genvar n3;
genvar n4;
generate 
    for (n1=0; n1<8; n1=n1+1) begin
        routing_node UUT_routing_nodes_l1 (clk,rst,Din[22+46*n1:46*n1],Din[22+46*n1+23:46*n1+23],Aout_l2[15+16*n1:16*n1],PRNG[n1],RND,Aout[15+32*n1:32*n1],Aout[15+32*n1+16:32*n1+16],Dout_l1[22+23*n1:23*n1]);
    end
    
    for (n2=0; n2<4; n2=n2+1) begin
        routing_node UUT_routing_nodes_l2 (clk,rst,Dout_l1[22+46*n2:46*n2],Dout_l1[22+46*n2+23:46*n2+23],Aout_l3[15+16*n2:16*n2],PRNG[8+n2],RND,Aout_l2[15+32*n2:32*n2],Aout_l2[15+32*n2+16:32*n2+16],Dout_l2[22+23*n2:23*n2]);
    end
    
    for (n3=0; n3<2; n3=n3+1) begin
        routing_node UUT_routing_nodes_l3 (clk,rst,Dout_l2[22+46*n3:46*n3],Dout_l2[22+46*n3+23:46*n3+23],Aout_l4[15+16*n3:16*n3],PRNG[12+n3],RND,Aout_l3[15+32*n3:32*n3],Aout_l3[15+32*n3+16:32*n3+16],Dout_l3[22+23*n3:23*n3]);
    end
    
    for (n4=0; n4<1; n4=n4+1) begin
        routing_node UUT_routing_nodes_l4 (clk,rst,Dout_l3[22+46*n4:46*n4],Dout_l3[22+46*n4+23:46*n4+23],Dout_l4[20+23*n4:23*n4+5],PRNG[14+n4],RND,Aout_l4[15+32*n4:32*n4],Aout_l4[15+32*n4+16:32*n4+16],Dout_l4[22+23*n4:23*n4]);
    end
    
endgenerate


endmodule
