`timescale 1ns / 1ps

module routing_node(input clk,
  input rst,
  input wire [22:0] D1,
  input wire [22:0] D2,
  input wire [15:0] Ain,
  input reg PRNG,
  input reg RND,
  output reg [15:0] Aout1,
  output reg [15:0] Aout2,
  output reg [22:0] Dout);
  
wire any_bv0_flag, bv0_or_rnd_w, rand_or_winner_w, d1_or_d2_w;
wire [4:0] bv_diff;
wire diff_y,dif_s;
wire [22:0] winner_data_w, Dout_w;

//assign any_bv0_flag = (D1[22] & D1[23]) | (D2[22] & D2[23]);
assign any_bv0_flag = (D1[21] | D2[21]);
assign bv0_or_rnd_w = (any_bv0_flag == 1'b1) ? 1'b0 : RND;
assign bv_diff = D1[4:0] - D2[4:0];
assign diff_y = (bv_diff == 0) ? 1'b1 : 1'b0;
assign dif_s = (bv_diff[4] == 0) ? 1'b1 : 1'b0;
assign rand_or_winner_w = (diff_y == 1'b1) ? 1'b1 : bv0_or_rnd_w;
assign d1_or_d2_w = (rand_or_winner_w == 1'b1) ? PRNG : dif_s;
assign winner_data_w = (d1_or_d2_w == 1'b1) ? D2 : D1;
assign Dout_w = (D2[22] == 1'b1) ? ((D1[22] == 1'b0) ? D2 : winner_data_w) : ((D1[22] == 1'b1) ? D1 : 0);

always @ (posedge clk) begin
    if (rst == 1'b1) begin
        Dout <= 0;
        Aout1 <= 0;
        Aout2 <= 0;
    end else begin
        Dout <= Dout_w;
        Aout1 <= Ain;
        Aout2 <= Ain;
    end
end
endmodule
