`timescale 1ns / 1ps

module chromatic_main_control_ams(input clk,
  input rst,
  input CS1,
  input SDI1,
  input FP_VSA_TEST_MODE_SEL,
  input BP_VSA_TEST_MODE_SEL,
  input BP_MUX_TEST_MODE_SEL,
  input PROG_MODE_SEL,
  input SOLVE_MODE_SEL,
  input [255:0] TRUE0,
  input [255:0] TRUE1,
  input [63:0] VSAB_OUT,
  input BP_MUX_SAMPLED,
  input [63:0] var_init,
  output reg BUSY,
  output reg SDO1,
  output reg TX_READY,
  output wire [127:0] RWLF_pre,
  output wire [255:0] RWLB_pre,
  output wire [63:0] MAKE_SEL0,
  output wire [63:0] MAKE_SEL1,
  output wire [63:0] BREAK_SEL0,
  output wire [63:0] BREAK_SEL1,
  output wire [15:0] BP_MUX_SEL,
  output wire [127:0] DRDN_WBLp,
  output wire [127:0] DRUP_WBLp,
  output wire [127:0] DRDN_WBLn,
  output wire [127:0] DRUP_WBLn,
  output wire [255:0] WWL_pre,
  output wire VSAF_EN,
  output wire VSAB_EN,
  output reg FP_PUn,
  output reg BP_PUn,
  output reg BP_MUX_READY,
  output reg [255:0] TRUE0_reg,
  output reg [255:0] TRUE1_reg,
  output reg [63:0] VAR_flipped
);
      
      
parameter INPUT_SR_WIDTH = 416;
reg [INPUT_SR_WIDTH-1:0] content; //Main Data Input Shift Register
reg [255:0] content_out; //Main Data Output Shift Register
reg [63:0] VAR; // Main 64x1 variable register for SOLVE Mode
wire [127:0] LIT; // Signal used to drive the RWLF_pre drivers
wire [255:0] S; // Signal used to drive the RWLB_pre during make-value computation or BMP mode
wire [255:0] Z; // Signal used to drive the RWLB_pre during break-value computation or BBP & BWP modes

reg [8:0] r_Bit_Index;

wire clk_p; //Complementary clock required for enabling the sense amplifiers
assign clk_p = ~clk;


//////////////////////////////////////Mode Indicator Registers//////////////////////////////////////////////
//reg wta_test_mode;
reg fp_vsa_test_mode;
reg bp_vsa_test_mode;
reg bmp_test_mode;
reg bbp_test_mode;
//reg bp_wta_test_mode;
reg bp_mux_test_mode;
reg bmp_mode;
reg bbp_mode;
//reg bwp_mode;
reg fp_mode;
reg prog_mode;
reg flip_mode;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////INTERMEDIATE WIRES, MODULES (DECODERS) AND REGISTERS USED DURING TEST MODES///////////////////////////////////////
//wire [5:0] v_exta_address; //Encodes address of WTA input branch where V_exta is to be applied
//wire [5:0] v_extb_address; //Encodes address of WTA input branch where V_extb is to be applied
//wire [63:0] wta_va_decoded, wta_vb_decoded;
wire [127:0] fp_wl_test;   // 128x1 input obtained from input shift-register to be applied to RWLF_pre during FP_VSA_TEST mode
wire [255:0] bp_wl_test;
wire [63:0] lit_sel_test;
//wire [63:0] bp_wta_sel_test;
wire [3:0] bp_mux_sel_decIn;

//assign v_exta_address = content[9:4];
//assign v_extb_address = content[15:10];
assign fp_wl_test = content[131:4];
assign bp_wl_test = content[259:4];
assign lit_sel_test = content[323:260];
//assign bp_wta_sel_test = content[387:324];
assign bp_mux_sel_decIn = content[263:260];

//decoder6Bit WTA_Va_Decoder_ams (wta_test_mode,v_exta_address,wta_va_decoded);
//decoder6Bit WTA_Vb_Decoder_ams (wta_test_mode,v_extb_address,wta_vb_decoded);
decoder4Bit BP_Mux_Decoder_ams (bp_mux_test_mode,bp_mux_sel_decIn,BP_MUX_SEL);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////INTERMEDIATE WIRES, MODULES (DECODERS) AND REGISTERS USED DURING PROG MODES////////////////////////////////////////////////
wire [7:0] prog_wl_decIn;
wire [127:0] prog_bl_p;
wire [7:0] prog_bl_wait_time, prog_wl_wait_time, prog_postwl_wait_time;
wire [255:0] prog_wl_decOut;

assign prog_bl_p = content[131:4];
assign prog_wl_decIn = content[139:132];
assign prog_bl_wait_time = content[147:140];
assign prog_wl_wait_time = content[155:148];
assign prog_postwl_wait_time = content[163:156];

decoder8Bit Prog_WL_Decoder (prog_mode,prog_wl_decIn,prog_wl_decOut);

reg prog_bl_en;
reg prog_wl_en;
reg [7:0] prog_bl_wait_counter, prog_wl_wait_counter, prog_postwl_wait_counter;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////INTERMEDIATE WIRES, MODULES & REGISTERS USED DURING SOLVE MODE////////////////////////////////////////
wire [16:0] max_flips;
wire [3:0] max_color;
wire [255:0] clause_mask;//, randClause_sel_l0;
wire unsat;
wire [63:0] variable_mask;//, randVar_sel_l0;
wire [15:0] color_wl_sel;
//wire candVar_present;

assign max_flips = {1'b0,content[83:68]};
//assign p_noise = {1'b0,content[95:84]};
assign max_color = content[87:84];
assign variable_mask = content[159:96];
assign clause_mask = content[415:160];

//reg [255:0] TRUE1_reg;
//reg [7:0] prngbits_randClause;
//reg [5:0] prngbits_randVar;
//reg [63:0] memvar_mask;
reg [63:0] chromaticGsat_chosenVar;
//reg [12:0] sampled_noise;
//reg [63:0] candVar_reg;
//reg bv0_present, wta_valid_reg, restart_flag;
reg restart_flag;
//reg [63:0] VAR_flipped;
reg [16:0] flip_counter;
reg [3:0] color_wl_decIn;

unsatEval unsatEval (TRUE0_reg,clause_mask,unsat);
//randVarSelect randVarSelect (candVar_reg,memvar_mask,prngbits_randVar,randVar_sel_l0,candVar_present);

//assign random_walk_flag = (sampled_noise > p_noise) ? 1'b1 : 1'b0;

always @(*)
    begin
    if (flip_mode==1'b1) begin
		VAR_flipped = VAR ^ chromaticGsat_chosenVar;
    end else begin
        VAR_flipped = 0;
    end  
end

decoder4Bit_v2 color_decoder_ams (color_wl_decIn,color_wl_sel);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




//////////////////////////////////MIXED SIGNAL CORE SIGNAL GENERATION////////////////////////////////////////

assign VSAF_EN = clk_p & (fp_vsa_test_mode | fp_mode);
assign VSAB_EN = clk_p & (bp_vsa_test_mode | bbp_mode);

genvar i;
for (i=0; i<64; i=i+1) begin  : MAKE_BREAK_SEL_logic
    assign MAKE_SEL0[i] = (~lit_sel_test[i] & bmp_test_mode) | (bmp_mode & ~VAR[i]);                          
    assign MAKE_SEL1[i] = (lit_sel_test[i] & bmp_test_mode) | (bmp_mode & VAR[i]); 
	assign BREAK_SEL0[i] = (lit_sel_test[i] & bbp_test_mode) | (bbp_mode & VAR[i]);                          
    assign BREAK_SEL1[i] = (~lit_sel_test[i] & bbp_test_mode) | (bbp_mode & ~VAR[i]);
    assign LIT[2*i] = variable_mask[i] & VAR[i];
    assign LIT[2*i+1] = variable_mask[i] & ~VAR[i];
end

genvar n;
for (n=0; n<128; n=n+1) begin  : FP_WLn_logic
    assign RWLF_pre[n] = (fp_mode & LIT[n]) | (fp_wl_test[n] & fp_vsa_test_mode);
    //assign WBLp[n] = prog_bl_en & prog_bl_p[n];
    //assign WBLn[n] = prog_bl_en & ~prog_bl_p[n];
	assign DRDN_WBLp[n] = prog_bl_en & ~prog_bl_p[n];
	assign DRUP_WBLp[n] = prog_bl_en & ~prog_bl_p[n] | ~prog_bl_en;
	assign DRDN_WBLn[n] = prog_bl_en & prog_bl_p[n];
	assign DRUP_WBLn[n] = prog_bl_en & prog_bl_p[n] | ~prog_bl_en;                 
end

genvar m;
for (m=0; m<256; m=m+1) begin  : BP_WLm_logic1
    assign WWL_pre[m] = prog_wl_decOut[m] & prog_wl_en;      
    assign S[m] = TRUE0_reg[m] & clause_mask[m];
    assign Z[m] = ~TRUE0_reg[m] & TRUE1_reg[m] & clause_mask[m];     
end

genvar m1;
for (m1=0; m1<240; m1=m1+1) begin  : BP_WLm_logic2
    assign RWLB_pre[m1] = (bmp_mode & S[m1]) | (bbp_mode & Z[m1]) | (bp_wl_test[m1] & (bp_vsa_test_mode | bp_mux_test_mode));
end

genvar m2;
for (m2=0; m2<16; m2=m2+1) begin  : BP_WLm_logic3
    assign RWLB_pre[m2+240] = (bbp_mode & color_wl_sel[m2]); 
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////////FSM STATE ENCODINGS & REGISTER/////////////////////////////////////////////////////////////////////////////////////////////////
parameter size = 5;
parameter s_IDLE = 5'b00000, s_DIN_DECODE = 5'b00001, s_BP_VSA_TEST3 = 5'b00010, s_WTA_TEST2 = 5'b00011, s_DOUT = 5'b00100, s_FP_VSA_TEST1 = 5'b00101, s_FP_VSA_TEST2 = 5'b00110, s_BP_VSA_TEST1 = 5'b00111, s_BP_VSA_TEST2 = 5'b01000, s_BP_WTA_TEST1 = 5'b01001, s_BP_WTA_TEST2 = 5'b01010, s_BP_WTA_TEST3 = 5'b01011, s_BP_MUX_TEST1 = 5'b01100, s_BP_MUX_TEST2 = 5'b01101;
parameter s_PROG_BL1 = 5'b01110, s_PROG_WL = 5'b01111, s_PROG_BL2 = 5'b10000, s_SOLVE_FP = 5'b10001, s_SOLVE_RC = 5'b10010, s_SOLVE_BMP = 5'b10011, s_SOLVE_BBP = 5'b10100, s_SOLVE_BWP = 5'b10101, s_SOLVE_FLIP = 5'b10110, s_PRNG_TEST = 5'b10111, s_STATE_SEL = 5'b11000;
reg [size-1:0] state; //FSM state register
wire direct_state_select;
assign direct_state_select = FP_VSA_TEST_MODE_SEL | BP_VSA_TEST_MODE_SEL | BP_MUX_TEST_MODE_SEL | PROG_MODE_SEL | SOLVE_MODE_SEL;
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////MAIN FSM/////////////////////////////////////////////////////////////////////////////////////////////////
    
    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            BUSY <= 1'b0;
            SDO1 <= 1'b0;
            state <= s_IDLE;
            content <= 0;
            r_Bit_Index <= 255;
            TX_READY <= 1'b0;
            content_out <= 0;
            fp_vsa_test_mode <= 1'b0;
            bp_vsa_test_mode <= 1'b0;
            fp_mode <= 1'b0;
            bbp_mode <= 1'b0;
            bmp_mode <= 1'b0;
            bp_mux_test_mode <= 1'b0;
			bmp_test_mode <= 1'b0;
			bbp_test_mode <= 1'b0;
            BP_MUX_READY <= 1'b0;
            FP_PUn <= 1'b1;
            BP_PUn <= 1'b1;
            prog_mode <= 1'b0;
            prog_bl_en <= 1'b0;
            prog_wl_en <= 1'b0;
            prog_bl_wait_counter <= 1'b0;
            prog_wl_wait_counter <= 1'b0;
            prog_postwl_wait_counter <= 1'b0;
            VAR <= content[67:4];
            flip_mode <= 1'b0;
            restart_flag <= 1'b1;
            flip_counter <= 0;
            TRUE0_reg <= 0;
            TRUE1_reg <= 0;
			chromaticGsat_chosenVar <= 0;
            color_wl_decIn <= 0;
        end else begin
            case(state)
                s_IDLE: begin
                        fp_vsa_test_mode <= 1'b0;
                        bp_vsa_test_mode <= 1'b0;
                        fp_mode <= 1'b0;
                        bmp_mode <= 1'b0;
                        bbp_mode <= 1'b0;
						bmp_test_mode <= 1'b0;
						bbp_test_mode <= 1'b0;
                        FP_PUn <= 1'b1;
                        TX_READY <= 1'b0;
                        r_Bit_Index <= 255; 
                        BP_PUn <= 1'b1;
                        bp_mux_test_mode <= 1'b0;
                        BP_MUX_READY <= 1'b0;
                        prog_mode <= 1'b0;
                        prog_bl_en <= 1'b0;
                        prog_wl_en <= 1'b0;
                        prog_bl_wait_counter <= 1'b0;
                        prog_wl_wait_counter <= 1'b0;
                        prog_postwl_wait_counter <= 1'b0;
                        VAR <= content[67:4];
                        restart_flag <= 1'b1;
                        flip_mode <= 1'b0;
                        flip_counter <= 0;
                        TRUE0_reg <= 0;
                        TRUE1_reg <= 0;
						chromaticGsat_chosenVar <= 0;
                        content_out <= 0;
                        color_wl_decIn <= 0;
                        if (direct_state_select==1'b1) begin
							BUSY <= 1'b1;
                            SDO1 <= 1'b0;
                            content <= content;
                            state <= s_STATE_SEL;
						end else begin
                            BUSY <= 1'b0;
                            SDO1 <= 1'b0;
                            content <= content;
                            state <= s_IDLE;
                        end
                    end
				s_STATE_SEL: begin
                        prog_bl_en <= 1'b0;
                        prog_wl_en <= 1'b0;
                        prog_bl_wait_counter <= 1'b0;
                        prog_wl_wait_counter <= 1'b0;
                        prog_postwl_wait_counter <= 1'b0;
                        VAR <= content[67:4];
                        restart_flag <= 1'b1;
						if (FP_VSA_TEST_MODE_SEL==1'b1) begin
							state <= s_FP_VSA_TEST1;
							prog_mode <= 1'b0;
							FP_PUn <= 1'b0;
							BP_PUn <= 1'b1;
							content <= 416'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F1;
						end else if (BP_VSA_TEST_MODE_SEL==1'b1) begin
							state <= s_BP_VSA_TEST1;
							prog_mode <= 1'b0;
							FP_PUn <= 1'b1;
							BP_PUn <= 1'b0;
							content <= 416'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000F2;
						end else if (BP_MUX_TEST_MODE_SEL==1'b1) begin
							state <= s_BP_MUX_TEST1;
							prog_mode <= 1'b0;
							FP_PUn <= 1'b1;
							BP_PUn <= 1'b0;
							content <= 416'h000000000000000000000000000000000000001000000000000000000F00000000000000F0000000000000000000000000000034;
						end else if (PROG_MODE_SEL==1'b1) begin
							state <= s_PROG_BL1;
							prog_mode <= 1'b1;
							FP_PUn <= 1'b1;
							BP_PUn <= 1'b1;
							content <= 416'h00000000000000000000000000000000000000000000000000000000000000002020200000000000F00000C000000000F00000C5;
						end else if (SOLVE_MODE_SEL==1'b1) begin
							state <= s_SOLVE_FP;
							prog_mode <= 1'b0;
							FP_PUn <= 1'b0;
							BP_PUn <= 1'b1;
							//content <= 416'h0000000003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0003FFFFFFFFFFFF400FFFF00009708C2EF0B5A6;
							content <= {348'h0000000003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0003FFFFFFFFFFFF00CFFFF,var_init,4'h6};
						end else begin
							state <= s_IDLE;
							prog_mode <= 1'b0;
							FP_PUn <= 1'b1;
							BP_PUn <= 1'b1;
							content <= content;
						end						
                    end
                s_DOUT: begin
                        content <= content;
                        content_out <= content_out;
                        if (r_Bit_Index>=0 & r_Bit_Index < 256) begin
                            SDO1 <= content_out[r_Bit_Index];
                            state <= s_DOUT;
                            TX_READY <= 1'b1;
                            r_Bit_Index <= r_Bit_Index - 1;
                        end else begin
                            SDO1 <= 1'b0;
                            state <= s_IDLE;
                            TX_READY <= 1'b0;
                            r_Bit_Index <= 255;
                        end
                    end
                s_FP_VSA_TEST1: begin
                        content <= content;
                        fp_vsa_test_mode <= 1'b1;
                        FP_PUn <= 1'b0;
                        state <= s_FP_VSA_TEST2;
                    end
                s_FP_VSA_TEST2: begin
                        content <= content;
                        fp_vsa_test_mode <= 1'b0;
                        FP_PUn <= 1'b1;
                        state <= s_DOUT;
                        if (content[132]==1'b0)
                            content_out[255:0] <= TRUE0[255:0];
                        else 
                            content_out[255:0] <= TRUE1[255:0];
                    end
                s_BP_VSA_TEST1: begin
                        content <= content;
                        bp_vsa_test_mode <= 1'b1;
                        BP_PUn <= 1'b0;
						bmp_test_mode <= 1'b1;
						bbp_test_mode <= 1'b0;
                        state <= s_BP_VSA_TEST2;
                    end
				s_BP_VSA_TEST2: begin
                        content <= content;
                        bp_vsa_test_mode <= 1'b1;
                        BP_PUn <= 1'b0;
						bmp_test_mode <= 1'b0;
						bbp_test_mode <= 1'b1;
                        state <= s_BP_VSA_TEST3;
                    end
				s_BP_VSA_TEST3: begin
                        content <= content;
                        bp_vsa_test_mode <= 1'b0;
                        BP_PUn <= 1'b1;
						bmp_test_mode <= 1'b0;
						bbp_test_mode <= 1'b0;
                        state <= s_DOUT;
                        content_out[255:0] <= {content_out[255:64],VSAB_OUT[63:0]};
                    end
                s_BP_MUX_TEST1: begin
                        content <= content;
                        bp_mux_test_mode <= 1'b1;
                        BP_PUn <= 1'b0;
                        state <= s_BP_MUX_TEST2;
                    end
                s_BP_MUX_TEST2: begin
                        content <= content;
                        if (BP_MUX_SAMPLED==1'b0) begin
                            state <= s_BP_MUX_TEST2;
                            BP_MUX_READY <= 1'b1;
                            bp_mux_test_mode <= 1'b1;
                            BP_PUn <= 1'b0;
                        end else begin 
                            state <= s_IDLE;
                            BP_MUX_READY <= 1'b0;
                            bp_mux_test_mode <= 1'b0;
                            BP_PUn <= 1'b1;
                        end
                    end
                s_PROG_BL1: begin
                        content <= content;
                        prog_mode <= 1'b1;
                        prog_bl_en <= 1'b1;
                        if (prog_bl_wait_counter < prog_bl_wait_time) begin
                            prog_bl_wait_counter <= prog_bl_wait_counter + 1;
                            prog_wl_en <= 1'b0;
                            state <= s_PROG_BL1;
                        end else begin 
                            prog_bl_wait_counter <= 0;
                            prog_wl_en <= 1'b1;
                            state <= s_PROG_WL;
                        end
                    end
                s_PROG_WL: begin
                        content <= content;
                        prog_mode <= 1'b1;
                        prog_bl_en <= 1'b1;
                        if (prog_wl_wait_counter < prog_wl_wait_time-1) begin
                            prog_wl_wait_counter <= prog_wl_wait_counter + 1;
                            prog_wl_en <= 1'b1;
                            state <= s_PROG_WL;
                        end else begin 
                            prog_wl_wait_counter <= 0;
                            prog_wl_en <= 1'b0;
                            state <= s_PROG_BL2;
                        end
                    end
                s_PROG_BL2: begin
                        content <= content;
                        prog_mode <= 1'b1;
                        prog_wl_en <= 1'b0;
                        if (prog_postwl_wait_counter < prog_postwl_wait_time-1) begin
                            prog_postwl_wait_counter <= prog_postwl_wait_counter + 1;
                            prog_bl_en <= 1'b1;
                            state <= s_PROG_BL2;
                            content_out <= content_out;
                        end else begin 
                            prog_postwl_wait_counter <= 0;
                            prog_bl_en <= 1'b0;
                            state <= s_DOUT;
                            content_out <= {content_out[255:160],content[163:4]};
                        end
                    end
                s_SOLVE_FP: begin
                        content <= content;
                        if (restart_flag==1'b1) begin
                            VAR <= content[67:4];
                            flip_counter <= 0;
                            color_wl_decIn <= 0;
                        end else begin
                            VAR <= VAR_flipped;
                            flip_counter <= flip_counter + 1;
                            color_wl_decIn <= color_wl_decIn;
                        end
                        restart_flag <= 1'b0;
                        fp_mode <= 1'b1;
						bmp_mode <= 1'b0;
						bbp_mode <= 1'b0;
						flip_mode <= 1'b0;
                        FP_PUn <= 1'b0;
						TRUE0_reg <= TRUE0_reg;
                        TRUE1_reg <= TRUE1_reg;
                        state <= s_SOLVE_BMP;
						chromaticGsat_chosenVar <= chromaticGsat_chosenVar;
						content_out <= content_out;
                    end
                s_SOLVE_BMP: begin
                        content <= content;
                        flip_counter <= flip_counter;
                        VAR <= VAR;
                        fp_mode <= 1'b0;
						bmp_mode <= 1'b1;
						bbp_mode <= 1'b0;
						flip_mode <= 1'b0;
                        FP_PUn <= 1'b1;
						BP_PUn <= 1'b0;
                        TRUE0_reg <= TRUE0;
                        TRUE1_reg <= TRUE1;
						state <= s_SOLVE_BBP;
						chromaticGsat_chosenVar <= chromaticGsat_chosenVar;
						content_out <= content_out;
						color_wl_decIn <= color_wl_decIn;
                    end
                s_SOLVE_BBP: begin
                        content <= content;
                        flip_counter <= flip_counter;
                        VAR <= VAR;
                        fp_mode <= 1'b0;
                        bmp_mode <= 1'b0;
						flip_mode <= 1'b0;
                        FP_PUn <= 1'b1;
                        TRUE0_reg <= TRUE0_reg;
                        TRUE1_reg <= TRUE1_reg;
						chromaticGsat_chosenVar <= chromaticGsat_chosenVar;
						if (unsat==1'b1) begin
                            if (flip_counter > max_flips) begin
                                state <= s_DOUT;
                                content_out <= {content_out[255:82],flip_counter,VAR,1'b0};
                                BP_PUn <= 1'b1;
                                bbp_mode <= 1'b0;
                                color_wl_decIn <= 0;
                            end else begin
                                state <= s_SOLVE_FLIP;
                                content_out <= content_out;
                                BP_PUn <= 1'b0;
                                bbp_mode <= 1'b1;
                                color_wl_decIn <= color_wl_decIn;
                            end
                        end else begin 
                            state <= s_DOUT;
                            content_out <= {content_out[255:82],flip_counter,VAR,1'b1};
                            BP_PUn <= 1'b1;
                            bbp_mode <= 1'b0;
                            color_wl_decIn <= 0;
                        end
						
                    end
                s_SOLVE_FLIP: begin
                        content <= content;
                        flip_counter <= flip_counter;
                        VAR <= VAR;
                        fp_mode <= 1'b0;
                        bmp_mode <= 1'b0;
                        bbp_mode <= 1'b0;
                        flip_mode <= 1'b1;
                        FP_PUn <= 1'b1;
                        BP_PUn <= 1'b1;
                        TRUE0_reg <= TRUE0_reg;
                        TRUE1_reg <= TRUE1_reg;
						chromaticGsat_chosenVar <= VSAB_OUT;
                        state <= s_SOLVE_FP;
						content_out <= content_out;
						if (color_wl_decIn < max_color - 1) begin
						  color_wl_decIn <= color_wl_decIn + 1;
						end else begin
						  color_wl_decIn <= 0;
						end
                    end
                default: begin
                            BUSY <= 1'b0;
                            SDO1 <= 1'b0;
                            TX_READY <= 1'b0;
                            content <= 0;
                            state <= s_IDLE;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            bp_mux_test_mode <= 1'b0;
                            BP_MUX_READY <= 1'b0;
                            fp_mode <= 1'b0;
                            bmp_mode <= 1'b0;
                            bbp_mode <= 1'b0;
							bmp_test_mode <= 1'b0;
							bbp_test_mode <= 1'b0;
                            FP_PUn <= 1'b1;
                            BP_PUn <= 1'b1;
                            prog_mode <= 1'b0;
                            r_Bit_Index <= 255;
                            prog_bl_wait_counter <= 1'b0;
                            prog_wl_wait_counter <= 1'b0;
                            prog_postwl_wait_counter <= 1'b0;
                            VAR <= content[67:4];
                            flip_mode <= 1'b0;
                            flip_counter <= 0;
                            TRUE0_reg <= 0;
                            TRUE1_reg <= 0;
                            content_out <= 0;
                         end
           endcase
        end
    end
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule



///////////////////////////////////////////////////////////////////////////////////RANDOM CLAUSE SELECT/////////////////////////////////////////////////////////////////////////////////////////////////
module unsatEval(input wire [255:0] TRUE0_reg,
  input wire [255:0] clause_mask,
  output wire unsat);
  
wire [255:0] true0_l0;
wire [127:0] true0_l1;
wire [63:0] true0_l2;
wire [31:0] true0_l3;
wire [15:0] true0_l4;
wire [7:0] true0_l5;
wire [3:0] true0_l6;
wire [1:0] true0_l7;

genvar n1;
for (n1=0; n1<128; n1=n1+1) begin  : randClause_and_Unsat_logic1
    assign true0_l0[2*n1] = TRUE0_reg[2*n1] & clause_mask[2*n1];
    assign true0_l0[2*n1+1] = TRUE0_reg[2*n1+1] & clause_mask[2*n1+1];
    assign true0_l1[n1] = true0_l0[2*n1] | true0_l0[2*n1+1];                   
end

genvar n2;
for (n2=0; n2<64; n2=n2+1) begin  : randClause_and_Unsat_logic2
    assign true0_l2[n2] = true0_l1[2*n2] | true0_l1[2*n2+1];               
end

genvar n3;
for (n3=0; n3<32; n3=n3+1) begin  : randClause_and_Unsat_logic3
    assign true0_l3[n3] = true0_l2[2*n3] | true0_l2[2*n3+1];             
end

genvar n4;
for (n4=0; n4<16; n4=n4+1) begin  : randClause_and_Unsat_logic4
    assign true0_l4[n4] = true0_l3[2*n4] | true0_l3[2*n4+1];             
end

genvar n5;
for (n5=0; n5<8; n5=n5+1) begin  : randClause_and_Unsat_logic5
    assign true0_l5[n5] = true0_l4[2*n5] | true0_l4[2*n5+1];           
end

genvar n6;
for (n6=0; n6<4; n6=n6+1) begin  : randClause_and_Unsat_logic6
    assign true0_l6[n6] = true0_l5[2*n6] | true0_l5[2*n6+1];               
end

genvar n7;
for (n7=0; n7<2; n7=n7+1) begin  : randClause_and_Unsat_logic7
    assign true0_l7[n7] = true0_l6[2*n7] | true0_l6[2*n7+1];  
end

assign unsat = true0_l7[0] | true0_l7[1];

endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////4-BIT INPUT DECODER FOR BP_MUX_SEL SELECTION DURING BP_MUX_TEST MODE/////////////////////////////////////////////////////////////////////////////////////////////////
module decoder4Bit(input wire mode,
  input wire [3:0] decIn,
  output reg [15:0] decOut);

  always @(*)
	begin
	if (mode==1'b1) begin
        case (decIn)
        4'b0000 : decOut <= 16'h0001;
        4'b0001 : decOut <= 16'h0002;
        4'b0010 : decOut <= 16'h0004;
        4'b0011 : decOut <= 16'h0008;
        4'b0100 : decOut <= 16'h0010;
        4'b0101 : decOut <= 16'h0020;
        4'b0110 : decOut <= 16'h0040;
        4'b0111 : decOut <= 16'h0080;
        4'b1000 : decOut <= 16'h0100;
        4'b1001 : decOut <= 16'h0200;
        4'b1010 : decOut <= 16'h0400;
        4'b1011 : decOut <= 16'h0800;
        4'b1100 : decOut <= 16'h1000;
        4'b1101 : decOut <= 16'h2000;
        4'b1110 : decOut <= 16'h4000;
        4'b1111 : decOut <= 16'h8000;
        default: decOut <= 0;
        endcase
    end else begin
        decOut <= 0;
    end
end
endmodule

module decoder4Bit_v2(input wire [3:0] decIn,
  output reg [15:0] decOut);

  always @(*)
	begin
    case (decIn)
    4'b0000 : decOut <= 16'h0001;
    4'b0001 : decOut <= 16'h0002;
    4'b0010 : decOut <= 16'h0004;
    4'b0011 : decOut <= 16'h0008;
    4'b0100 : decOut <= 16'h0010;
    4'b0101 : decOut <= 16'h0020;
    4'b0110 : decOut <= 16'h0040;
    4'b0111 : decOut <= 16'h0080;
    4'b1000 : decOut <= 16'h0100;
    4'b1001 : decOut <= 16'h0200;
    4'b1010 : decOut <= 16'h0400;
    4'b1011 : decOut <= 16'h0800;
    4'b1100 : decOut <= 16'h1000;
    4'b1101 : decOut <= 16'h2000;
    4'b1110 : decOut <= 16'h4000;
    4'b1111 : decOut <= 16'h8000;
    default: decOut <= 0;
    endcase
end
endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////////8-BIT INPUT DECODER FOR WWL SELECTION DURING PROG MODE/////////////////////////////////////////////////////////////////////////////////////////////////
module decoder8Bit(input wire mode,
  input wire [7:0] decIn,
  output reg [255:0] decOut);
  
  always @(*)
	begin
	if (mode==1'b1) begin
        case (decIn)
        8'h00: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000001;
        8'h01: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000002;
        8'h02: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000004;
        8'h03: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000008;
        8'h04: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000010;
        8'h05: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000020;
        8'h06: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000040;
        8'h07: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000080;
        8'h08: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000100;
        8'h09: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000200;
        8'h0A: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000400;
        8'h0B: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000000800;
        8'h0C: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000001000;
        8'h0D: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000002000;
        8'h0E: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000004000;
        8'h0F: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000008000;
        8'h10: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000010000;
        8'h11: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000020000;
        8'h12: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000040000;
        8'h13: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000080000;
        8'h14: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000100000;
        8'h15: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000200000;
        8'h16: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000400000;
        8'h17: decOut <= 256'h0000000000000000000000000000000000000000000000000000000000800000;
        8'h18: decOut <= 256'h0000000000000000000000000000000000000000000000000000000001000000;
        8'h19: decOut <= 256'h0000000000000000000000000000000000000000000000000000000002000000;
        8'h1A: decOut <= 256'h0000000000000000000000000000000000000000000000000000000004000000;
        8'h1B: decOut <= 256'h0000000000000000000000000000000000000000000000000000000008000000;
        8'h1C: decOut <= 256'h0000000000000000000000000000000000000000000000000000000010000000;
        8'h1D: decOut <= 256'h0000000000000000000000000000000000000000000000000000000020000000;
        8'h1E: decOut <= 256'h0000000000000000000000000000000000000000000000000000000040000000;
        8'h1F: decOut <= 256'h0000000000000000000000000000000000000000000000000000000080000000;
        8'h20: decOut <= 256'h0000000000000000000000000000000000000000000000000000000100000000;
        8'h21: decOut <= 256'h0000000000000000000000000000000000000000000000000000000200000000;
        8'h22: decOut <= 256'h0000000000000000000000000000000000000000000000000000000400000000;
        8'h23: decOut <= 256'h0000000000000000000000000000000000000000000000000000000800000000;
        8'h24: decOut <= 256'h0000000000000000000000000000000000000000000000000000001000000000;
        8'h25: decOut <= 256'h0000000000000000000000000000000000000000000000000000002000000000;
        8'h26: decOut <= 256'h0000000000000000000000000000000000000000000000000000004000000000;
        8'h27: decOut <= 256'h0000000000000000000000000000000000000000000000000000008000000000;
        8'h28: decOut <= 256'h0000000000000000000000000000000000000000000000000000010000000000;
        8'h29: decOut <= 256'h0000000000000000000000000000000000000000000000000000020000000000;
        8'h2A: decOut <= 256'h0000000000000000000000000000000000000000000000000000040000000000;
        8'h2B: decOut <= 256'h0000000000000000000000000000000000000000000000000000080000000000;
        8'h2C: decOut <= 256'h0000000000000000000000000000000000000000000000000000100000000000;
        8'h2D: decOut <= 256'h0000000000000000000000000000000000000000000000000000200000000000;
        8'h2E: decOut <= 256'h0000000000000000000000000000000000000000000000000000400000000000;
        8'h2F: decOut <= 256'h0000000000000000000000000000000000000000000000000000800000000000;
        8'h30: decOut <= 256'h0000000000000000000000000000000000000000000000000001000000000000;
        8'h31: decOut <= 256'h0000000000000000000000000000000000000000000000000002000000000000;
        8'h32: decOut <= 256'h0000000000000000000000000000000000000000000000000004000000000000;
        8'h33: decOut <= 256'h0000000000000000000000000000000000000000000000000008000000000000;
        8'h34: decOut <= 256'h0000000000000000000000000000000000000000000000000010000000000000;
        8'h35: decOut <= 256'h0000000000000000000000000000000000000000000000000020000000000000;
        8'h36: decOut <= 256'h0000000000000000000000000000000000000000000000000040000000000000;
        8'h37: decOut <= 256'h0000000000000000000000000000000000000000000000000080000000000000;
        8'h38: decOut <= 256'h0000000000000000000000000000000000000000000000000100000000000000;
        8'h39: decOut <= 256'h0000000000000000000000000000000000000000000000000200000000000000;
        8'h3A: decOut <= 256'h0000000000000000000000000000000000000000000000000400000000000000;
        8'h3B: decOut <= 256'h0000000000000000000000000000000000000000000000000800000000000000;
        8'h3C: decOut <= 256'h0000000000000000000000000000000000000000000000001000000000000000;
        8'h3D: decOut <= 256'h0000000000000000000000000000000000000000000000002000000000000000;
        8'h3E: decOut <= 256'h0000000000000000000000000000000000000000000000004000000000000000;
        8'h3F: decOut <= 256'h0000000000000000000000000000000000000000000000008000000000000000;
        8'h40: decOut <= 256'h0000000000000000000000000000000000000000000000010000000000000000;
        8'h41: decOut <= 256'h0000000000000000000000000000000000000000000000020000000000000000;
        8'h42: decOut <= 256'h0000000000000000000000000000000000000000000000040000000000000000;
        8'h43: decOut <= 256'h0000000000000000000000000000000000000000000000080000000000000000;
        8'h44: decOut <= 256'h0000000000000000000000000000000000000000000000100000000000000000;
        8'h45: decOut <= 256'h0000000000000000000000000000000000000000000000200000000000000000;
        8'h46: decOut <= 256'h0000000000000000000000000000000000000000000000400000000000000000;
        8'h47: decOut <= 256'h0000000000000000000000000000000000000000000000800000000000000000;
        8'h48: decOut <= 256'h0000000000000000000000000000000000000000000001000000000000000000;
        8'h49: decOut <= 256'h0000000000000000000000000000000000000000000002000000000000000000;
        8'h4A: decOut <= 256'h0000000000000000000000000000000000000000000004000000000000000000;
        8'h4B: decOut <= 256'h0000000000000000000000000000000000000000000008000000000000000000;
        8'h4C: decOut <= 256'h0000000000000000000000000000000000000000000010000000000000000000;
        8'h4D: decOut <= 256'h0000000000000000000000000000000000000000000020000000000000000000;
        8'h4E: decOut <= 256'h0000000000000000000000000000000000000000000040000000000000000000;
        8'h4F: decOut <= 256'h0000000000000000000000000000000000000000000080000000000000000000;
        8'h50: decOut <= 256'h0000000000000000000000000000000000000000000100000000000000000000;
        8'h51: decOut <= 256'h0000000000000000000000000000000000000000000200000000000000000000;
        8'h52: decOut <= 256'h0000000000000000000000000000000000000000000400000000000000000000;
        8'h53: decOut <= 256'h0000000000000000000000000000000000000000000800000000000000000000;
        8'h54: decOut <= 256'h0000000000000000000000000000000000000000001000000000000000000000;
        8'h55: decOut <= 256'h0000000000000000000000000000000000000000002000000000000000000000;
        8'h56: decOut <= 256'h0000000000000000000000000000000000000000004000000000000000000000;
        8'h57: decOut <= 256'h0000000000000000000000000000000000000000008000000000000000000000;
        8'h58: decOut <= 256'h0000000000000000000000000000000000000000010000000000000000000000;
        8'h59: decOut <= 256'h0000000000000000000000000000000000000000020000000000000000000000;
        8'h5A: decOut <= 256'h0000000000000000000000000000000000000000040000000000000000000000;
        8'h5B: decOut <= 256'h0000000000000000000000000000000000000000080000000000000000000000;
        8'h5C: decOut <= 256'h0000000000000000000000000000000000000000100000000000000000000000;
        8'h5D: decOut <= 256'h0000000000000000000000000000000000000000200000000000000000000000;
        8'h5E: decOut <= 256'h0000000000000000000000000000000000000000400000000000000000000000;
        8'h5F: decOut <= 256'h0000000000000000000000000000000000000000800000000000000000000000;
        8'h60: decOut <= 256'h0000000000000000000000000000000000000001000000000000000000000000;
        8'h61: decOut <= 256'h0000000000000000000000000000000000000002000000000000000000000000;
        8'h62: decOut <= 256'h0000000000000000000000000000000000000004000000000000000000000000;
        8'h63: decOut <= 256'h0000000000000000000000000000000000000008000000000000000000000000;
        8'h64: decOut <= 256'h0000000000000000000000000000000000000010000000000000000000000000;
        8'h65: decOut <= 256'h0000000000000000000000000000000000000020000000000000000000000000;
        8'h66: decOut <= 256'h0000000000000000000000000000000000000040000000000000000000000000;
        8'h67: decOut <= 256'h0000000000000000000000000000000000000080000000000000000000000000;
        8'h68: decOut <= 256'h0000000000000000000000000000000000000100000000000000000000000000;
        8'h69: decOut <= 256'h0000000000000000000000000000000000000200000000000000000000000000;
        8'h6A: decOut <= 256'h0000000000000000000000000000000000000400000000000000000000000000;
        8'h6B: decOut <= 256'h0000000000000000000000000000000000000800000000000000000000000000;
        8'h6C: decOut <= 256'h0000000000000000000000000000000000001000000000000000000000000000;
        8'h6D: decOut <= 256'h0000000000000000000000000000000000002000000000000000000000000000;
        8'h6E: decOut <= 256'h0000000000000000000000000000000000004000000000000000000000000000;
        8'h6F: decOut <= 256'h0000000000000000000000000000000000008000000000000000000000000000;
        8'h70: decOut <= 256'h0000000000000000000000000000000000010000000000000000000000000000;
        8'h71: decOut <= 256'h0000000000000000000000000000000000020000000000000000000000000000;
        8'h72: decOut <= 256'h0000000000000000000000000000000000040000000000000000000000000000;
        8'h73: decOut <= 256'h0000000000000000000000000000000000080000000000000000000000000000;
        8'h74: decOut <= 256'h0000000000000000000000000000000000100000000000000000000000000000;
        8'h75: decOut <= 256'h0000000000000000000000000000000000200000000000000000000000000000;
        8'h76: decOut <= 256'h0000000000000000000000000000000000400000000000000000000000000000;
        8'h77: decOut <= 256'h0000000000000000000000000000000000800000000000000000000000000000;
        8'h78: decOut <= 256'h0000000000000000000000000000000001000000000000000000000000000000;
        8'h79: decOut <= 256'h0000000000000000000000000000000002000000000000000000000000000000;
        8'h7A: decOut <= 256'h0000000000000000000000000000000004000000000000000000000000000000;
        8'h7B: decOut <= 256'h0000000000000000000000000000000008000000000000000000000000000000;
        8'h7C: decOut <= 256'h0000000000000000000000000000000010000000000000000000000000000000;
        8'h7D: decOut <= 256'h0000000000000000000000000000000020000000000000000000000000000000;
        8'h7E: decOut <= 256'h0000000000000000000000000000000040000000000000000000000000000000;
        8'h7F: decOut <= 256'h0000000000000000000000000000000080000000000000000000000000000000;
        8'h80: decOut <= 256'h0000000000000000000000000000000100000000000000000000000000000000;
        8'h81: decOut <= 256'h0000000000000000000000000000000200000000000000000000000000000000;
        8'h82: decOut <= 256'h0000000000000000000000000000000400000000000000000000000000000000;
        8'h83: decOut <= 256'h0000000000000000000000000000000800000000000000000000000000000000;
        8'h84: decOut <= 256'h0000000000000000000000000000001000000000000000000000000000000000;
        8'h85: decOut <= 256'h0000000000000000000000000000002000000000000000000000000000000000;
        8'h86: decOut <= 256'h0000000000000000000000000000004000000000000000000000000000000000;
        8'h87: decOut <= 256'h0000000000000000000000000000008000000000000000000000000000000000;
        8'h88: decOut <= 256'h0000000000000000000000000000010000000000000000000000000000000000;
        8'h89: decOut <= 256'h0000000000000000000000000000020000000000000000000000000000000000;
        8'h8A: decOut <= 256'h0000000000000000000000000000040000000000000000000000000000000000;
        8'h8B: decOut <= 256'h0000000000000000000000000000080000000000000000000000000000000000;
        8'h8C: decOut <= 256'h0000000000000000000000000000100000000000000000000000000000000000;
        8'h8D: decOut <= 256'h0000000000000000000000000000200000000000000000000000000000000000;
        8'h8E: decOut <= 256'h0000000000000000000000000000400000000000000000000000000000000000;
        8'h8F: decOut <= 256'h0000000000000000000000000000800000000000000000000000000000000000;
        8'h90: decOut <= 256'h0000000000000000000000000001000000000000000000000000000000000000;
        8'h91: decOut <= 256'h0000000000000000000000000002000000000000000000000000000000000000;
        8'h92: decOut <= 256'h0000000000000000000000000004000000000000000000000000000000000000;
        8'h93: decOut <= 256'h0000000000000000000000000008000000000000000000000000000000000000;
        8'h94: decOut <= 256'h0000000000000000000000000010000000000000000000000000000000000000;
        8'h95: decOut <= 256'h0000000000000000000000000020000000000000000000000000000000000000;
        8'h96: decOut <= 256'h0000000000000000000000000040000000000000000000000000000000000000;
        8'h97: decOut <= 256'h0000000000000000000000000080000000000000000000000000000000000000;
        8'h98: decOut <= 256'h0000000000000000000000000100000000000000000000000000000000000000;
        8'h99: decOut <= 256'h0000000000000000000000000200000000000000000000000000000000000000;
        8'h9A: decOut <= 256'h0000000000000000000000000400000000000000000000000000000000000000;
        8'h9B: decOut <= 256'h0000000000000000000000000800000000000000000000000000000000000000;
        8'h9C: decOut <= 256'h0000000000000000000000001000000000000000000000000000000000000000;
        8'h9D: decOut <= 256'h0000000000000000000000002000000000000000000000000000000000000000;
        8'h9E: decOut <= 256'h0000000000000000000000004000000000000000000000000000000000000000;
        8'h9F: decOut <= 256'h0000000000000000000000008000000000000000000000000000000000000000;
        8'hA0: decOut <= 256'h0000000000000000000000010000000000000000000000000000000000000000;
        8'hA1: decOut <= 256'h0000000000000000000000020000000000000000000000000000000000000000;
        8'hA2: decOut <= 256'h0000000000000000000000040000000000000000000000000000000000000000;
        8'hA3: decOut <= 256'h0000000000000000000000080000000000000000000000000000000000000000;
        8'hA4: decOut <= 256'h0000000000000000000000100000000000000000000000000000000000000000;
        8'hA5: decOut <= 256'h0000000000000000000000200000000000000000000000000000000000000000;
        8'hA6: decOut <= 256'h0000000000000000000000400000000000000000000000000000000000000000;
        8'hA7: decOut <= 256'h0000000000000000000000800000000000000000000000000000000000000000;
        8'hA8: decOut <= 256'h0000000000000000000001000000000000000000000000000000000000000000;
        8'hA9: decOut <= 256'h0000000000000000000002000000000000000000000000000000000000000000;
        8'hAA: decOut <= 256'h0000000000000000000004000000000000000000000000000000000000000000;
        8'hAB: decOut <= 256'h0000000000000000000008000000000000000000000000000000000000000000;
        8'hAC: decOut <= 256'h0000000000000000000010000000000000000000000000000000000000000000;
        8'hAD: decOut <= 256'h0000000000000000000020000000000000000000000000000000000000000000;
        8'hAE: decOut <= 256'h0000000000000000000040000000000000000000000000000000000000000000;
        8'hAF: decOut <= 256'h0000000000000000000080000000000000000000000000000000000000000000;
        8'hB0: decOut <= 256'h0000000000000000000100000000000000000000000000000000000000000000;
        8'hB1: decOut <= 256'h0000000000000000000200000000000000000000000000000000000000000000;
        8'hB2: decOut <= 256'h0000000000000000000400000000000000000000000000000000000000000000;
        8'hB3: decOut <= 256'h0000000000000000000800000000000000000000000000000000000000000000;
        8'hB4: decOut <= 256'h0000000000000000001000000000000000000000000000000000000000000000;
        8'hB5: decOut <= 256'h0000000000000000002000000000000000000000000000000000000000000000;
        8'hB6: decOut <= 256'h0000000000000000004000000000000000000000000000000000000000000000;
        8'hB7: decOut <= 256'h0000000000000000008000000000000000000000000000000000000000000000;
        8'hB8: decOut <= 256'h0000000000000000010000000000000000000000000000000000000000000000;
        8'hB9: decOut <= 256'h0000000000000000020000000000000000000000000000000000000000000000;
        8'hBA: decOut <= 256'h0000000000000000040000000000000000000000000000000000000000000000;
        8'hBB: decOut <= 256'h0000000000000000080000000000000000000000000000000000000000000000;
        8'hBC: decOut <= 256'h0000000000000000100000000000000000000000000000000000000000000000;
        8'hBD: decOut <= 256'h0000000000000000200000000000000000000000000000000000000000000000;
        8'hBE: decOut <= 256'h0000000000000000400000000000000000000000000000000000000000000000;
        8'hBF: decOut <= 256'h0000000000000000800000000000000000000000000000000000000000000000;
        8'hC0: decOut <= 256'h0000000000000001000000000000000000000000000000000000000000000000;
        8'hC1: decOut <= 256'h0000000000000002000000000000000000000000000000000000000000000000;
        8'hC2: decOut <= 256'h0000000000000004000000000000000000000000000000000000000000000000;
        8'hC3: decOut <= 256'h0000000000000008000000000000000000000000000000000000000000000000;
        8'hC4: decOut <= 256'h0000000000000010000000000000000000000000000000000000000000000000;
        8'hC5: decOut <= 256'h0000000000000020000000000000000000000000000000000000000000000000;
        8'hC6: decOut <= 256'h0000000000000040000000000000000000000000000000000000000000000000;
        8'hC7: decOut <= 256'h0000000000000080000000000000000000000000000000000000000000000000;
        8'hC8: decOut <= 256'h0000000000000100000000000000000000000000000000000000000000000000;
        8'hC9: decOut <= 256'h0000000000000200000000000000000000000000000000000000000000000000;
        8'hCA: decOut <= 256'h0000000000000400000000000000000000000000000000000000000000000000;
        8'hCB: decOut <= 256'h0000000000000800000000000000000000000000000000000000000000000000;
        8'hCC: decOut <= 256'h0000000000001000000000000000000000000000000000000000000000000000;
        8'hCD: decOut <= 256'h0000000000002000000000000000000000000000000000000000000000000000;
        8'hCE: decOut <= 256'h0000000000004000000000000000000000000000000000000000000000000000;
        8'hCF: decOut <= 256'h0000000000008000000000000000000000000000000000000000000000000000;
        8'hD0: decOut <= 256'h0000000000010000000000000000000000000000000000000000000000000000;
        8'hD1: decOut <= 256'h0000000000020000000000000000000000000000000000000000000000000000;
        8'hD2: decOut <= 256'h0000000000040000000000000000000000000000000000000000000000000000;
        8'hD3: decOut <= 256'h0000000000080000000000000000000000000000000000000000000000000000;
        8'hD4: decOut <= 256'h0000000000100000000000000000000000000000000000000000000000000000;
        8'hD5: decOut <= 256'h0000000000200000000000000000000000000000000000000000000000000000;
        8'hD6: decOut <= 256'h0000000000400000000000000000000000000000000000000000000000000000;
        8'hD7: decOut <= 256'h0000000000800000000000000000000000000000000000000000000000000000;
        8'hD8: decOut <= 256'h0000000001000000000000000000000000000000000000000000000000000000;
        8'hD9: decOut <= 256'h0000000002000000000000000000000000000000000000000000000000000000;
        8'hDA: decOut <= 256'h0000000004000000000000000000000000000000000000000000000000000000;
        8'hDB: decOut <= 256'h0000000008000000000000000000000000000000000000000000000000000000;
        8'hDC: decOut <= 256'h0000000010000000000000000000000000000000000000000000000000000000;
        8'hDD: decOut <= 256'h0000000020000000000000000000000000000000000000000000000000000000;
        8'hDE: decOut <= 256'h0000000040000000000000000000000000000000000000000000000000000000;
        8'hDF: decOut <= 256'h0000000080000000000000000000000000000000000000000000000000000000;
        8'hE0: decOut <= 256'h0000000100000000000000000000000000000000000000000000000000000000;
        8'hE1: decOut <= 256'h0000000200000000000000000000000000000000000000000000000000000000;
        8'hE2: decOut <= 256'h0000000400000000000000000000000000000000000000000000000000000000;
        8'hE3: decOut <= 256'h0000000800000000000000000000000000000000000000000000000000000000;
        8'hE4: decOut <= 256'h0000001000000000000000000000000000000000000000000000000000000000;
        8'hE5: decOut <= 256'h0000002000000000000000000000000000000000000000000000000000000000;
        8'hE6: decOut <= 256'h0000004000000000000000000000000000000000000000000000000000000000;
        8'hE7: decOut <= 256'h0000008000000000000000000000000000000000000000000000000000000000;
        8'hE8: decOut <= 256'h0000010000000000000000000000000000000000000000000000000000000000;
        8'hE9: decOut <= 256'h0000020000000000000000000000000000000000000000000000000000000000;
        8'hEA: decOut <= 256'h0000040000000000000000000000000000000000000000000000000000000000;
        8'hEB: decOut <= 256'h0000080000000000000000000000000000000000000000000000000000000000;
        8'hEC: decOut <= 256'h0000100000000000000000000000000000000000000000000000000000000000;
        8'hED: decOut <= 256'h0000200000000000000000000000000000000000000000000000000000000000;
        8'hEE: decOut <= 256'h0000400000000000000000000000000000000000000000000000000000000000;
        8'hEF: decOut <= 256'h0000800000000000000000000000000000000000000000000000000000000000;
        8'hF0: decOut <= 256'h0001000000000000000000000000000000000000000000000000000000000000;
        8'hF1: decOut <= 256'h0002000000000000000000000000000000000000000000000000000000000000;
        8'hF2: decOut <= 256'h0004000000000000000000000000000000000000000000000000000000000000;
        8'hF3: decOut <= 256'h0008000000000000000000000000000000000000000000000000000000000000;
        8'hF4: decOut <= 256'h0010000000000000000000000000000000000000000000000000000000000000;
        8'hF5: decOut <= 256'h0020000000000000000000000000000000000000000000000000000000000000;
        8'hF6: decOut <= 256'h0040000000000000000000000000000000000000000000000000000000000000;
        8'hF7: decOut <= 256'h0080000000000000000000000000000000000000000000000000000000000000;
        8'hF8: decOut <= 256'h0100000000000000000000000000000000000000000000000000000000000000;
        8'hF9: decOut <= 256'h0200000000000000000000000000000000000000000000000000000000000000;
        8'hFA: decOut <= 256'h0400000000000000000000000000000000000000000000000000000000000000;
        8'hFB: decOut <= 256'h0800000000000000000000000000000000000000000000000000000000000000;
        8'hFC: decOut <= 256'h1000000000000000000000000000000000000000000000000000000000000000;
        8'hFD: decOut <= 256'h2000000000000000000000000000000000000000000000000000000000000000;
        8'hFE: decOut <= 256'h4000000000000000000000000000000000000000000000000000000000000000;
        8'hFF: decOut <= 256'h8000000000000000000000000000000000000000000000000000000000000000;
        default: decOut <= 0;
        endcase
    end else begin
        decOut <= 0;
    end
end
endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
