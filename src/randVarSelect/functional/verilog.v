
///////////////////////////////////////////////////////////////////////////////////RANDOM VARIABLE SELECT/////////////////////////////////////////////////////////////////////////////////////////////////
module randVarSelect(input wire [63:0] candVar_reg,
	input wire [63:0] memvar_mask,
	input wire [5:0] prngbits_randVar,
	output wire [63:0] randVar_sel_l0,
	output wire candVar_present);
  
	wire [63:0] candVar_l0;
	wire [31:0] candVar_l1, randVar_sel_l1;
	wire [15:0] candVar_l2, randVar_sel_l2;
	wire [7:0] candVar_l3, randVar_sel_l3;
	wire [3:0] candVar_l4, randVar_sel_l4;
	wire [1:0] candVar_l5, randVar_sel_l5;

	genvar m1;
	for (m1=0; m1<32; m1=m1+1) begin  : randVar_BV0_logic1
		assign candVar_l0[2*m1] = candVar_reg[2*m1] & memvar_mask[2*m1];
		assign candVar_l0[2*m1+1] = candVar_reg[2*m1+1] & memvar_mask[2*m1+1];
		assign candVar_l1[m1] = candVar_l0[2*m1] | candVar_l0[2*m1+1]; 
		assign randVar_sel_l0[2*m1] = randVar_sel_l1[m1] & ((candVar_l0[2*m1] & ~candVar_l0[2*m1+1]) | (~prngbits_randVar[0] & candVar_l0[2*m1] & candVar_l0[2*m1+1]));
		assign randVar_sel_l0[2*m1+1] = randVar_sel_l1[m1] & ((~candVar_l0[2*m1] & candVar_l0[2*m1+1]) | (prngbits_randVar[0] & candVar_l0[2*m1] & candVar_l0[2*m1+1]));                   
	end

	genvar m2;
	for (m2=0; m2<16; m2=m2+1) begin  : randVar_BV0_logic2
		assign candVar_l2[m2] = candVar_l1[2*m2] | candVar_l1[2*m2+1]; 
		assign randVar_sel_l1[2*m2] = randVar_sel_l2[m2] & ((candVar_l1[2*m2] & ~candVar_l1[2*m2+1]) | (~prngbits_randVar[1] & candVar_l1[2*m2] & candVar_l1[2*m2+1]));
		assign randVar_sel_l1[2*m2+1] = randVar_sel_l2[m2] & ((~candVar_l1[2*m2] & candVar_l1[2*m2+1]) | (prngbits_randVar[1] & candVar_l1[2*m2] & candVar_l1[2*m2+1]));                   
	end

	genvar m3;
	for (m3=0; m3<8; m3=m3+1) begin  : randVar_BV0_logic3
		assign candVar_l3[m3] = candVar_l2[2*m3] | candVar_l2[2*m3+1]; 
		assign randVar_sel_l2[2*m3] = randVar_sel_l3[m3] & ((candVar_l2[2*m3] & ~candVar_l2[2*m3+1]) | (~prngbits_randVar[2] & candVar_l2[2*m3] & candVar_l2[2*m3+1]));
		assign randVar_sel_l2[2*m3+1] = randVar_sel_l3[m3] & ((~candVar_l2[2*m3] & candVar_l2[2*m3+1]) | (prngbits_randVar[2] & candVar_l2[2*m3] & candVar_l2[2*m3+1]));                   
	end

	genvar m4;
	for (m4=0; m4<4; m4=m4+1) begin  : randVar_BV0_logic4
		assign candVar_l4[m4] = candVar_l3[2*m4] | candVar_l3[2*m4+1]; 
		assign randVar_sel_l3[2*m4] = randVar_sel_l4[m4] & ((candVar_l3[2*m4] & ~candVar_l3[2*m4+1]) | (~prngbits_randVar[3] & candVar_l3[2*m4] & candVar_l3[2*m4+1]));
		assign randVar_sel_l3[2*m4+1] = randVar_sel_l4[m4] & ((~candVar_l3[2*m4] & candVar_l3[2*m4+1]) | (prngbits_randVar[3] & candVar_l3[2*m4] & candVar_l3[2*m4+1]));                   
	end

	genvar m5;
	for (m5=0; m5<2; m5=m5+1) begin  : randVar_BV0_logic5
		assign candVar_l5[m5] = candVar_l4[2*m5] | candVar_l4[2*m5+1]; 
		assign randVar_sel_l4[2*m5] = randVar_sel_l5[m5] & ((candVar_l4[2*m5] & ~candVar_l4[2*m5+1]) | (~prngbits_randVar[4] & candVar_l4[2*m5] & candVar_l4[2*m5+1]));
		assign randVar_sel_l4[2*m5+1] = randVar_sel_l5[m5] & ((~candVar_l4[2*m5] & candVar_l4[2*m5+1]) | (prngbits_randVar[4] & candVar_l4[2*m5] & candVar_l4[2*m5+1]));                   
	end

	assign candVar_present = candVar_l5[0] | candVar_l5[1];
	assign randVar_sel_l5[0] = candVar_present & ((candVar_l5[0] & ~candVar_l5[1]) | (~prngbits_randVar[5] & candVar_l5[0] & candVar_l5[1]));
	assign randVar_sel_l5[1] = candVar_present & ((~candVar_l5[0] & candVar_l5[1]) | (prngbits_randVar[5] & candVar_l5[0] & candVar_l5[1]));

endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
