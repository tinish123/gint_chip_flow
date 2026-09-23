`timescale 1ns / 1ps

module hoho_unit_cell_row_adder(input clk,
  input rst,
  input reg [1:0] triplet1_u,
  input reg [1:0] triplet1_b,
  input reg [1:0] triplet2_u,
  input reg [1:0] triplet2_b,
  input reg [1:0] triplet3_u,
  input reg [1:0] triplet3_b,
  input reg [1:0] triplet4_u,
  input reg [1:0] triplet4_b,
  input reg [1:0] triplet5_u,
  input reg [1:0] triplet5_b,
  input reg [1:0] triplet6_u,
  input reg [1:0] triplet6_b,
  input reg [1:0] triplet7_u,
  input reg [1:0] triplet7_b,
  input reg [1:0] triplet8_u,
  input reg [1:0] triplet8_b,
  input reg variable_value,
  output reg [4:0] make_value,
  output reg [4:0] break_value);
  
wire [2:0] partial_upper_sum1_l1, partial_upper_sum2_l1, partial_upper_sum3_l1, partial_upper_sum4_l1, partial_lower_sum1_l1, partial_lower_sum2_l1, partial_lower_sum3_l1, partial_lower_sum4_l1;
wire [3:0] partial_upper_sum1_l2, partial_upper_sum2_l2, partial_lower_sum1_l2, partial_lower_sum2_l2;
wire [4:0] partial_upper_sum1_l3, partial_lower_sum1_l3;
wire [4:0] make_value_w, break_value_w;

assign partial_upper_sum1_l1 = {1'b0,triplet1_u} + {1'b0,triplet2_u};
assign partial_upper_sum2_l1 = {1'b0,triplet3_u} + {1'b0,triplet4_u};
assign partial_upper_sum3_l1 = {1'b0,triplet5_u} + {1'b0,triplet6_u};
assign partial_upper_sum4_l1 = {1'b0,triplet7_u} + {1'b0,triplet8_u};

assign partial_lower_sum1_l1 = {1'b0,triplet1_b} + {1'b0,triplet2_b};
assign partial_lower_sum2_l1 = {1'b0,triplet3_b} + {1'b0,triplet4_b};
assign partial_lower_sum3_l1 = {1'b0,triplet5_b} + {1'b0,triplet6_b};
assign partial_lower_sum4_l1 = {1'b0,triplet7_b} + {1'b0,triplet8_b};

assign partial_upper_sum1_l2 = {1'b0,partial_upper_sum1_l1} + {1'b0,partial_upper_sum2_l1};
assign partial_upper_sum2_l2 = {1'b0,partial_upper_sum3_l1} + {1'b0,partial_upper_sum4_l1};

assign partial_lower_sum1_l2 = {1'b0,partial_lower_sum1_l1} + {1'b0,partial_lower_sum2_l1};
assign partial_lower_sum2_l2 = {1'b0,partial_lower_sum3_l1} + {1'b0,partial_lower_sum4_l1};

assign partial_upper_sum1_l3 = {1'b0,partial_upper_sum1_l2} + {1'b0,partial_upper_sum2_l2};

assign partial_lower_sum1_l3 = {1'b0,partial_lower_sum1_l2} + {1'b0,partial_upper_sum2_l2};

assign make_value_w = (variable_value == 1'b1) ? partial_upper_sum1_l3 : partial_lower_sum1_l3;
assign break_value_w = (variable_value == 1'b1) ? partial_lower_sum1_l3 : partial_upper_sum1_l3;

always @ (posedge clk) begin
    if (rst == 1'b1) begin
        make_value <= 0;
        break_value <= 0;
    end else begin
        make_value <= make_value_w;
        break_value <= break_value_w;
    end
end
endmodule
