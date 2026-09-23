
///////////////////////////////////////////////////////////////////////////////////RANDOM CLAUSE SELECT/////////////////////////////////////////////////////////////////////////////////////////////////
module randClauseSelect(input wire [255:0] TRUE0_reg,
  input wire [255:0] clause_mask,
  input wire [7:0] prngbits_randClause,
  output wire [255:0] randClause_sel_l0,
  output wire unsat);
  
wire [255:0] true0_l0;
wire [127:0] true0_l1, randClause_sel_l1;
wire [63:0] true0_l2, randClause_sel_l2;
wire [31:0] true0_l3, randClause_sel_l3;
wire [15:0] true0_l4, randClause_sel_l4;
wire [7:0] true0_l5, randClause_sel_l5;
wire [3:0] true0_l6, randClause_sel_l6;
wire [1:0] true0_l7, randClause_sel_l7;

genvar n1;
for (n1=0; n1<128; n1=n1+1) begin  : randClause_and_Unsat_logic1
    assign true0_l0[2*n1] = TRUE0_reg[2*n1] & clause_mask[2*n1];
    assign true0_l0[2*n1+1] = TRUE0_reg[2*n1+1] & clause_mask[2*n1+1];
    assign true0_l1[n1] = true0_l0[2*n1] | true0_l0[2*n1+1]; 
    assign randClause_sel_l0[2*n1] = randClause_sel_l1[n1] & ((true0_l0[2*n1] & ~true0_l0[2*n1+1]) | (~prngbits_randClause[0] & true0_l0[2*n1] & true0_l0[2*n1+1]));
    assign randClause_sel_l0[2*n1+1] = randClause_sel_l1[n1] & ((~true0_l0[2*n1] & true0_l0[2*n1+1]) | (prngbits_randClause[0] & true0_l0[2*n1] & true0_l0[2*n1+1]));                   
end

genvar n2;
for (n2=0; n2<64; n2=n2+1) begin  : randClause_and_Unsat_logic2
    assign true0_l2[n2] = true0_l1[2*n2] | true0_l1[2*n2+1];       
    assign randClause_sel_l1[2*n2] = randClause_sel_l2[n2] & ((true0_l1[2*n2] & ~true0_l1[2*n2+1]) | (~prngbits_randClause[1] & true0_l1[2*n2] & true0_l1[2*n2+1]));
    assign randClause_sel_l1[2*n2+1] = randClause_sel_l2[n2] & ((~true0_l1[2*n2] & true0_l1[2*n2+1]) | (prngbits_randClause[1] & true0_l1[2*n2] & true0_l1[2*n2+1]));             
end

genvar n3;
for (n3=0; n3<32; n3=n3+1) begin  : randClause_and_Unsat_logic3
    assign true0_l3[n3] = true0_l2[2*n3] | true0_l2[2*n3+1];  
    assign randClause_sel_l2[2*n3] = randClause_sel_l3[n3] & ((true0_l2[2*n3] & ~true0_l2[2*n3+1]) | (~prngbits_randClause[2] & true0_l2[2*n3] & true0_l2[2*n3+1]));
    assign randClause_sel_l2[2*n3+1] = randClause_sel_l3[n3] & ((~true0_l2[2*n3] & true0_l2[2*n3+1]) | (prngbits_randClause[2] & true0_l2[2*n3] & true0_l2[2*n3+1]));                  
end

genvar n4;
for (n4=0; n4<16; n4=n4+1) begin  : randClause_and_Unsat_logic4
    assign true0_l4[n4] = true0_l3[2*n4] | true0_l3[2*n4+1];
    assign randClause_sel_l3[2*n4] = randClause_sel_l4[n4] & ((true0_l3[2*n4] & ~true0_l3[2*n4+1]) | (~prngbits_randClause[3] & true0_l3[2*n4] & true0_l3[2*n4+1]));
    assign randClause_sel_l3[2*n4+1] = randClause_sel_l4[n4] & ((~true0_l3[2*n4] & true0_l3[2*n4+1]) | (prngbits_randClause[3] & true0_l3[2*n4] & true0_l3[2*n4+1]));               
end

genvar n5;
for (n5=0; n5<8; n5=n5+1) begin  : randClause_and_Unsat_logic5
    assign true0_l5[n5] = true0_l4[2*n5] | true0_l4[2*n5+1];
    assign randClause_sel_l4[2*n5] = randClause_sel_l5[n5] & ((true0_l4[2*n5] & ~true0_l4[2*n5+1]) | (~prngbits_randClause[4] & true0_l4[2*n5] & true0_l4[2*n5+1]));
    assign randClause_sel_l4[2*n5+1] = randClause_sel_l5[n5] & ((~true0_l4[2*n5] & true0_l4[2*n5+1]) | (prngbits_randClause[4] & true0_l4[2*n5] & true0_l4[2*n5+1]));               
end

genvar n6;
for (n6=0; n6<4; n6=n6+1) begin  : randClause_and_Unsat_logic6
    assign true0_l6[n6] = true0_l5[2*n6] | true0_l5[2*n6+1];
    assign randClause_sel_l5[2*n6] = randClause_sel_l6[n6] & ((true0_l5[2*n6] & ~true0_l5[2*n6+1]) | (~prngbits_randClause[5] & true0_l5[2*n6] & true0_l5[2*n6+1]));
    assign randClause_sel_l5[2*n6+1] = randClause_sel_l6[n6] & ((~true0_l5[2*n6] & true0_l5[2*n6+1]) | (prngbits_randClause[5] & true0_l5[2*n6] & true0_l5[2*n6+1]));                 
end

genvar n7;
for (n7=0; n7<2; n7=n7+1) begin  : randClause_and_Unsat_logic7
    assign true0_l7[n7] = true0_l6[2*n7] | true0_l6[2*n7+1];
    assign randClause_sel_l6[2*n7] = randClause_sel_l7[n7] & ((true0_l6[2*n7] & ~true0_l6[2*n7+1]) | (~prngbits_randClause[6] & true0_l6[2*n7] & true0_l6[2*n7+1]));
    assign randClause_sel_l6[2*n7+1] = randClause_sel_l7[n7] & ((~true0_l6[2*n7] & true0_l6[2*n7+1]) | (prngbits_randClause[6] & true0_l6[2*n7] & true0_l6[2*n7+1]));       
end

assign unsat = true0_l7[0] | true0_l7[1];
assign randClause_sel_l7[0] = unsat & ((true0_l7[0] & ~true0_l7[1]) | (~prngbits_randClause[7] & true0_l7[0] & true0_l7[1]));
assign randClause_sel_l7[1] = unsat & ((~true0_l7[0] & true0_l7[1]) | (prngbits_randClause[7] & true0_l7[0] & true0_l7[1]));

endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

