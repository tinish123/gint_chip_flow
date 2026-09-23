`timescale 1ns / 1ps

module main_controlB_ams(input clk,
  input rst,
  input CS1,
  input SDI1,
  input clk2,
  input START,
  input CS2,
  input [63:0] PBIT_OUT,
  input [255:0] TRUE0,
  input [255:0] TRUE1,
  input [63:0] VSAB_OUT,
  input [587:0] content,
  input [127:0] seed_x,
  input [127:0] seed_y,
  input prng_rst,
  output reg BUSY,
  output wire SDO1,
  output wire [63:0] PBIT_SEL,
  output wire [63:0] rn0,
  output wire [63:0] rn1,
  output wire [63:0] rn2,
  output wire [63:0] rn3,
  output wire [63:0] rp0,
  output wire [63:0] rp1,
  output wire [63:0] rp2,
  output wire [63:0] rp3,
  output wire [127:0] RWLF_pre,
  output wire [255:0] RWLBS_pre,
  output wire [255:0] RWLBZ_pre,
  output wire [63:0] MB_SEL,
  output wire [127:0] BP_PUnS,
  output wire [127:0] BP_PUnZ,
  output wire [127:0] DRDN_WBLp,
  output wire [127:0] DRUPn_WBLp,
  output wire [127:0] DRDN_WBLn,
  output wire [127:0] DRUPn_WBLn,
  output wire [255:0] WWL_pre,
  output wire VSAF_EN,
  output wire VSAB_EN,
  output reg FP_PUn,
  output wire PBIT_EN,
  output reg [255:0] content_out,
  output wire unsat,
  output wire [63:0] Var_to_flip);
	
parameter INPUT_SR_WIDTH = 588;
//reg [INPUT_SR_WIDTH-1:0] content; //Main Data Input Shift Register
//reg [255:0] content_out, content_out2; //Main Data Output Shift Register
//reg [255:0] content_out2;
reg [63:0] VAR1, VAR2, VAR3; // Main 64x1 variable register for SOLVE Mode
reg [63:0] VAR1_refr, VAR2_refr, VAR3_refr; // Main 64x1 sing-bit flip history register for SOLVE Mode with refractory period aware.
wire [255:0] S; // Signal used to drive the RWLBS_pre during gain-value computation or BMP mode
wire [255:0] Z; // Signal used to drive the RWLBZ_pre during gain-value computation or BBP & BWP modes

wire clk_p; //Complementary clock required for enabling the sense amplifiers
assign clk_p = ~clk;


//////////////////////////////////////Mode Indicator Registers//////////////////////////////////////////////
reg pbit_test_int_mode;
reg pbit_test_ext_mode;
reg bp_pbit_test_mode;
reg fp_vsa_test_mode;
reg bp_vsa_test_mode;
reg bp_mode1, bp_mode2, bp_mode3;
reg fp_mode1, fp_mode2, fp_mode3;
reg prog_mode;
reg flip_mode1, flip_mode2, flip_mode3;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////INTERMEDIATE WIRES, MODULES (DECODERS) AND REGISTERS USED DURING TEST MODES///////////////////////////////////////
wire [3:0] pbit_rp_test, pbit_rn_test;
wire [63:0] mb_sel_test;
wire [63:0] pbit_sel_test;
wire [255:0] bp_wls_test;
wire [255:0] bp_wlz_test;
wire [127:0] fp_wl_test;   // 128x1 input obtained from input shift-register to be applied to RWLF_pre during FP_VSA_TEST mode

assign pbit_rn_test = content[7:4];
assign pbit_rp_test = content[11:8];
assign mb_sel_test = content[75:12];
assign bp_wls_test = content[331:76];
assign bp_wlz_test = content[587:332];
assign pbit_sel_test = content[75:12];
assign fp_wl_test = content[131:4];
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
wire [18:0] max_flips;
wire [255:0] clause_mask;
//wire unsat;
wire [63:0] variable_mask, randVar_sel_l0, arbiter_input, HVar_Notin_Refr, GVar_Notin_Refr, allVar_Notin_Refr, candVar_G, candVar_H;
wire candVar_present;
wire [7:0] max_restarts;
wire gen_var, do_trial;
wire [63:0] VAR1_init, VAR2_init, VAR3_init;
wire any_GVar_Notin_Refr;

assign max_flips = {1'b0,content[23:6]};
assign variable_mask = content[87:24];
assign clause_mask = content[343:88];
assign max_restarts = {1'b0,content[350:344]};
assign gen_var = content[4];
assign do_trial = content[5];
assign VAR1_init = content[414:351];
assign VAR2_init = content[478:415];
assign VAR3_init = content[542:479];

reg [255:0] TRUE0_reg, TRUE1_reg;
reg [63:0] VSAB_OUT_reg, PBIT_OUT_reg;
reg [5:0] prngbits_randVar;
reg no_refr_pG, no_refr_sG, refr_pG_pH, refr_pG_sH, restart_flag1, restart_flag2, restart_flag3;
reg [18:0] flip_counter1, flip_counter2, flip_counter3;
reg [7:0] restart_counter;

genvar pp;
for (pp=0; pp<64; pp=pp+1) begin  : Cand_VAR_logic
	assign candVar_H[pp] = ~VSAB_OUT_reg[pp] & variable_mask[pp];
	assign candVar_G[pp] = PBIT_OUT_reg[pp] & candVar_H[pp];
	assign allVar_Notin_Refr[pp] = ((flip_mode1 & ~VAR1_refr[pp]) | (flip_mode2 & ~VAR2_refr[pp]) | (flip_mode3 & ~VAR3_refr[pp]));
	assign GVar_Notin_Refr[pp] = allVar_Notin_Refr[pp] & candVar_G[pp];
	assign HVar_Notin_Refr[pp] = allVar_Notin_Refr[pp] & candVar_H[pp];
    assign arbiter_input[pp] = (no_refr_sG & candVar_G[pp]) | (refr_pG_sH & HVar_Notin_Refr[pp]);
	assign Var_to_flip[pp] = (no_refr_pG & candVar_G[pp]) | (no_refr_sG & randVar_sel_l0[pp]) | (refr_pG_pH & ((any_GVar_Notin_Refr & GVar_Notin_Refr[pp]) | (~any_GVar_Notin_Refr & HVar_Notin_Refr[pp]))) | (refr_pG_sH & ((any_GVar_Notin_Refr & GVar_Notin_Refr[pp]) | (~any_GVar_Notin_Refr & randVar_sel_l0[pp])));
end

assign any_GVar_Notin_Refr = |GVar_Notin_Refr;

randVarSelect randVarSelect_UUT (arbiter_input,variable_mask,prngbits_randVar,randVar_sel_l0,candVar_present);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////PRNG MODULE INSTANTIATION AND RELEVANT WIRES & REGISTERS////////////////////////////////////////
//wire [127:0] seed_x, seed_y;
wire [127:0] PRNG_BITS;          //Output signals from the PRNG circuit module
reg [511:0] rng_buffer;
reg [3:0] rng_init_cycle_counter;

//assign seed_x = content[131:4];
//assign seed_y = content[259:132];

reg prng_en;
//reg prng_en;

xormix128 #(.streams(1)) prng_core (
  .clk(clk), .rst(prng_rst), .seed_x(seed_x),
  .seed_y(seed_y), .enable(prng_en),
  .result(PRNG_BITS)
);

always @ (posedge clk) begin
    if (rst == 1'b1) begin
        rng_buffer <= 0;
    end else begin
        if (prng_en == 1'b1) begin 
            rng_buffer[127:0] <= PRNG_BITS;
            rng_buffer[255:128] <= rng_buffer[127:0];
            rng_buffer[383:256] <= rng_buffer[255:128];
            rng_buffer[511:384] <= rng_buffer[383:256];
        end else begin
            rng_buffer <= rng_buffer;
        end
    end
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////MIXED SIGNAL CORE SIGNAL GENERATION////////////////////////////////////////
assign VSAF_EN = clk_p & (fp_vsa_test_mode | fp_mode1 | fp_mode2 | fp_mode3);
assign VSAB_EN = clk_p & (bp_vsa_test_mode | bp_mode1 | bp_mode2 | bp_mode3);
assign PBIT_EN = clk_p & (bp_mode1 | bp_mode2 | bp_mode3 | pbit_test_int_mode | pbit_test_ext_mode | bp_pbit_test_mode);
//assign FP_PUn = ~(fp_mode1 | fp_mode2 | fp_mode3 | fp_vsa_test_mode);

genvar i;
for (i=0; i<64; i=i+1) begin  : PBIT_SEL0_logic
    assign MB_SEL[i] = ((pbit_test_int_mode | bp_vsa_test_mode | bp_pbit_test_mode) & mb_sel_test[i]) | (bp_mode1 & VAR1[i]) | (bp_mode2 & VAR2[i]) | (bp_mode3 & VAR3[i]);
    assign PBIT_SEL[i] = ((pbit_test_int_mode | bp_pbit_test_mode) & 1'b1) | (pbit_test_ext_mode & pbit_sel_test[i]) | ((bp_mode1 | bp_mode2 | bp_mode3) & variable_mask[i]);
    assign BP_PUnS[2*i] = ~ (((pbit_test_int_mode | pbit_test_ext_mode | bp_vsa_test_mode | bp_pbit_test_mode) | variable_mask[i] & (bp_mode1 | bp_mode2 | bp_mode3)) & ~MB_SEL[i]);
    assign BP_PUnS[2*i+1] = ~ (((pbit_test_int_mode | pbit_test_ext_mode | bp_vsa_test_mode | bp_pbit_test_mode) | variable_mask[i] & (bp_mode1 | bp_mode2 | bp_mode3)) & MB_SEL[i]);
    assign BP_PUnZ[2*i] = ~ (((pbit_test_int_mode | pbit_test_ext_mode | bp_pbit_test_mode) | variable_mask[i] & (bp_mode1 | bp_mode2 | bp_mode3)) & MB_SEL[i]);
    assign BP_PUnZ[2*i+1] = ~ (((pbit_test_int_mode | pbit_test_ext_mode | bp_pbit_test_mode) | variable_mask[i] & (bp_mode1 | bp_mode2 | bp_mode3)) & ~MB_SEL[i]);
    assign RWLF_pre[2*i] = (variable_mask[i] & ((fp_mode1 & VAR1[i]) | (fp_mode2 & VAR2[i]) | (fp_mode3 & VAR3[i]))) | (fp_wl_test[2*i] & fp_vsa_test_mode);
    assign RWLF_pre[2*i+1] = (variable_mask[i] & ((fp_mode1 & ~VAR1[i]) | (fp_mode2 & ~VAR2[i]) | (fp_mode3 & ~VAR3[i]))) | (fp_wl_test[2*i+1] & fp_vsa_test_mode);
    
    assign rp3[i] = ((bp_pbit_test_mode | bp_mode1 | bp_mode2 | bp_mode3) & rng_buffer[8*i]) | ((pbit_test_int_mode | pbit_test_ext_mode) & pbit_rp_test[3]);
    assign rp2[i] = ((bp_pbit_test_mode | bp_mode1 | bp_mode2 | bp_mode3) & rng_buffer[8*i+1]) | ((pbit_test_int_mode | pbit_test_ext_mode) & pbit_rp_test[2]);
    assign rp1[i] = ((bp_pbit_test_mode | bp_mode1 | bp_mode2 | bp_mode3) & rng_buffer[8*i+2]) | ((pbit_test_int_mode | pbit_test_ext_mode) & pbit_rp_test[1]);
    assign rp0[i] = ((bp_pbit_test_mode | bp_mode1 | bp_mode2 | bp_mode3) & rng_buffer[8*i+3]) | ((pbit_test_int_mode | pbit_test_ext_mode) & pbit_rp_test[0]);
    
    assign rn3[i] = ((bp_pbit_test_mode | bp_mode1 | bp_mode2 | bp_mode3) & rng_buffer[8*i+4]) | ((pbit_test_int_mode | pbit_test_ext_mode) & pbit_rn_test[3]);
    assign rn2[i] = ((bp_pbit_test_mode | bp_mode1 | bp_mode2 | bp_mode3) & rng_buffer[8*i+5]) | ((pbit_test_int_mode | pbit_test_ext_mode) & pbit_rn_test[2]);
    assign rn1[i] = ((bp_pbit_test_mode | bp_mode1 | bp_mode2 | bp_mode3) & rng_buffer[8*i+6]) | ((pbit_test_int_mode | pbit_test_ext_mode) & pbit_rn_test[1]);
    assign rn0[i] = ((bp_pbit_test_mode | bp_mode1 | bp_mode2 | bp_mode3) & rng_buffer[8*i+7]) | ((pbit_test_int_mode | pbit_test_ext_mode) & pbit_rn_test[0]);
end

genvar n;
for (n=0; n<128; n=n+1) begin  : FP_WLn_logic
    assign DRDN_WBLp[n] = prog_bl_en & ~prog_bl_p[n];
	assign DRUPn_WBLp[n] = prog_bl_en & ~prog_bl_p[n] | ~prog_bl_en;
	assign DRDN_WBLn[n] = prog_bl_en & prog_bl_p[n];
	assign DRUPn_WBLn[n] = prog_bl_en & prog_bl_p[n] | ~prog_bl_en;
end

genvar m;
for (m=0; m<256; m=m+1) begin  : BP_WLm_logic
    assign RWLBS_pre[m] = ((pbit_test_int_mode | bp_vsa_test_mode | bp_pbit_test_mode) & bp_wls_test[m]) | ((bp_mode1 | bp_mode2 | bp_mode3) & S[m]);
    assign RWLBZ_pre[m] = ((pbit_test_int_mode | bp_pbit_test_mode) & bp_wlz_test[m]) | ((bp_mode1 | bp_mode2 | bp_mode3) & Z[m]);
    assign WWL_pre[m] = prog_wl_decOut[m] & prog_wl_en;      
    assign S[m] = TRUE0_reg[m] & clause_mask[m];
    assign Z[m] = ~TRUE0_reg[m] & TRUE1_reg[m] & clause_mask[m];     
end

assign unsat = |S;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//always @ (posedge clk2) begin
//    if (rst == 1'b1) begin
//        content <= 0;
//    end else begin
//        if (CS1 == 1'b0) begin
//            content <= {content[INPUT_SR_WIDTH-2:0],SDI1};
//        end else begin
//            content <= content;
//        end
//    end
//end

//assign SDO1 = content_out2[255];

//always @ (posedge clk2) begin
//    if (rst == 1'b1) begin
//        content_out2 <= 0;
//    end else begin
//        if (CS2 == 1'b0) begin
//            content_out2 <= {content_out2[254:0],1'b0};
//        end else begin
//            content_out2 <= content_out;
//        end
//    end
//end
    
            


///////////////////////////////////////////////////////////////////////////////////FSM STATE ENCODINGS & REGISTER/////////////////////////////////////////////////////////////////////////////////////////////////
parameter size = 5;
parameter s_IDLE = 5'b00000, s_DIN_DECODE = 5'b00001, s_PBIT_TEST_EXT = 5'b00010, s_FP_VSA_TEST1 = 5'b00011, s_BP_VSA_TEST = 5'b00100, s_PBIT_TEST_INT = 5'b00101, s_PRNG_TEST1 = 5'b00110;
parameter s_PROG_BL1 = 5'b00111, s_PROG_WL = 5'b01000, s_PROG_BL2 = 5'b01001, s_SOLVE_FP = 5'b01010, s_SOLVE_BP = 5'b01011, s_SOLVE_FLIP = 5'b01100, s_SOLVE_RNG_INIT = 5'b01101, s_SOLVE_RESTART = 5'b01110, s_PRNG_TEST2 = 5'b01111, s_BP_PBIT_TEST1 = 5'b10000, s_BP_PBIT_TEST2 = 5'b10001, s_FP_VSA_TEST2 = 5'b10010;
reg [size-1:0] state; //FSM state register
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////MAIN FSM/////////////////////////////////////////////////////////////////////////////////////////////////
    
    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            BUSY <= 1'b0;
            state <= s_IDLE;
            content_out <= 0;
            pbit_test_ext_mode <= 1'b0;
            pbit_test_int_mode <= 1'b0;
            fp_vsa_test_mode <= 1'b0;
            bp_vsa_test_mode <= 1'b0;
            fp_mode1 <= 1'b0;
            fp_mode2 <= 1'b0;
            fp_mode3 <= 1'b0;
            bp_mode1 <= 1'b0;
            bp_mode2 <= 1'b0;
            bp_mode3 <= 1'b0;
            flip_mode1 <= 1'b0;
            flip_mode2 <= 1'b0;
            flip_mode3 <= 1'b0;
            prog_mode <= 1'b0;
            prog_bl_en <= 1'b0;
            prog_wl_en <= 1'b0;
            prog_bl_wait_counter <= 1'b0;
            prog_wl_wait_counter <= 1'b0;
            prog_postwl_wait_counter <= 1'b0;
            VAR1 <= VAR1_init;
            VAR2 <= VAR2_init;
            VAR3 <= VAR3_init;
            VAR1_refr <= 0;
            VAR2_refr <= 0;
            VAR3_refr <= 0;
            prngbits_randVar <= 0;
            restart_flag1 <= 1'b1;
            restart_flag2 <= 1'b1;
            restart_flag3 <= 1'b1;
            flip_counter1 <= 0;
            flip_counter2 <= 0;
            flip_counter3 <= 0;
            TRUE0_reg <= 0;
            TRUE1_reg <= 0;
            VSAB_OUT_reg <= 0;
            PBIT_OUT_reg <= 0;
            prng_en <= 1'b0;
            rng_init_cycle_counter <= 0;
            restart_counter <= 1;
            no_refr_sG <= 1'b0;
            no_refr_pG <= 1'b0;
            refr_pG_sH <= 1'b0;
            refr_pG_pH <= 1'b0;
            FP_PUn <= 1'b1;
            bp_pbit_test_mode <= 1'b0;
        end else begin
            case(state)
                s_IDLE: begin
                        bp_pbit_test_mode <= 1'b0;
                        pbit_test_ext_mode <= 1'b0;
                        pbit_test_int_mode <= 1'b0;
                        fp_vsa_test_mode <= 1'b0;
                        bp_vsa_test_mode <= 1'b0;
                        fp_mode1 <= 1'b0;
                        fp_mode2 <= 1'b0;
                        fp_mode3 <= 1'b0;
                        bp_mode1 <= 1'b0;
                        bp_mode2 <= 1'b0;
                        bp_mode3 <= 1'b0;
                        flip_mode1 <= 1'b0;
                        flip_mode2 <= 1'b0;
                        flip_mode3 <= 1'b0;
                        prog_mode <= 1'b0;
                        prog_bl_en <= 1'b0;
                        prog_wl_en <= 1'b0;
                        prog_bl_wait_counter <= 1'b0;
                        prog_wl_wait_counter <= 1'b0;
                        prog_postwl_wait_counter <= 1'b0;
                        VAR1 <= VAR1_init;
                        VAR2 <= VAR2_init;
                        VAR3 <= VAR3_init;
                        VAR1_refr <= 0;
                        VAR2_refr <= 0;
                        VAR3_refr <= 0;
                        prngbits_randVar <= 0;
                        restart_flag1 <= 1'b1;
                        restart_flag2 <= 1'b1;
                        restart_flag3 <= 1'b1;
                        flip_counter1 <= 0;
                        flip_counter2 <= 0;
                        flip_counter3 <= 0;
                        TRUE0_reg <= 0;
                        TRUE1_reg <= 0;
                        VSAB_OUT_reg <= 0;
                        PBIT_OUT_reg <= 0;
                        prng_en <= 1'b0;
                        rng_init_cycle_counter <= 0;
                        restart_counter <= 1;
                        no_refr_sG <= 1'b0;
                        no_refr_pG <= 1'b0;
                        refr_pG_sH <= 1'b0;
                        refr_pG_pH <= 1'b0;
                        FP_PUn <= 1'b1;
                        if (START == 1'b1) begin
                            BUSY <= 1'b1;
                            state <= s_DIN_DECODE;
                            content_out <= 0;
                        end else begin
                            BUSY <= 1'b0;
                            state <= s_IDLE;
                            content_out <= content_out;
                        end
                    end
                s_DIN_DECODE: begin
                        bp_pbit_test_mode <= 1'b0;
                        prog_bl_en <= 1'b0;
                        prog_wl_en <= 1'b0;
                        prog_bl_wait_counter <= 1'b0;
                        prog_wl_wait_counter <= 1'b0;
                        prog_postwl_wait_counter <= 1'b0;
                        restart_flag1 <= 1'b1;
                        restart_flag2 <= 1'b1;
                        restart_flag3 <= 1'b1;
                        flip_counter1 <= 0;
                        flip_counter2 <= 0;
                        flip_counter3 <= 0;
                        restart_counter <= 1;
                        rng_init_cycle_counter <= 0;
                        if (content[3:0]==4'b0000) begin //0
                            state <= s_PBIT_TEST_EXT;
                            pbit_test_ext_mode <= 1'b1;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b0;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b0001) begin //1
                            state <= s_FP_VSA_TEST1;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b0;
                            FP_PUn <= 1'b0;
                        end else if (content[3:0]==4'b0010) begin //2
                            state <= s_BP_VSA_TEST;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b1;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b0;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b0011) begin //3
                            state <= s_PBIT_TEST_INT;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b1;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b0;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b0111) begin //7
                            state <= s_IDLE;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b0;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b1000) begin //8
                            state <= s_PRNG_TEST1;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b1;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b0101) begin //5
                            state <= s_PROG_BL1;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b1;
                            prng_en <= 1'b0;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b0100) begin //4
                            state <= s_SOLVE_RNG_INIT;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b1;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b1;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b0110) begin //6
                            state <= s_SOLVE_RNG_INIT;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b1;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b1;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b1001) begin //9
                            state <= s_BP_PBIT_TEST1;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b1;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b1010) begin //10
                            state <= s_SOLVE_RNG_INIT;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b1;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b1;
                            FP_PUn <= 1'b1;
                        end else if (content[3:0]==4'b1011) begin //11
                            state <= s_SOLVE_RNG_INIT;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b1;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b1;
                            FP_PUn <= 1'b1;
                        end else begin
                            state <= s_IDLE;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            prog_mode <= 1'b0;
                            prng_en <= 1'b0;
                            FP_PUn <= 1'b1;
                        end
                    end
                s_PBIT_TEST_EXT: begin
                        pbit_test_ext_mode <= 1'b0;
                        content_out <= {content_out[255:64],PBIT_OUT[63:0]};
                        state <= s_IDLE;
                    end
                s_PBIT_TEST_INT: begin
                        pbit_test_int_mode <= 1'b0;
                        content_out <= {content_out[255:64],PBIT_OUT[63:0]};
                        state <= s_IDLE;
                    end
                s_FP_VSA_TEST1: begin
                        fp_vsa_test_mode <= 1'b1;
                        FP_PUn <= 1'b0;
                        state <= s_FP_VSA_TEST2;
                    end
                s_FP_VSA_TEST2: begin
                        fp_vsa_test_mode <= 1'b0;
                        FP_PUn <= 1'b1;
                        state <= s_IDLE;
                        if (content[132]==1'b0)
                            content_out[255:0] <= TRUE0[255:0];
                        else 
                            content_out[255:0] <= TRUE1[255:0];
                    end
                s_BP_VSA_TEST: begin
                        bp_vsa_test_mode <= 1'b0;
                        state <= s_IDLE;
                        content_out[255:0] <= {content_out[255:64],VSAB_OUT[63:0]};
                    end
                s_BP_PBIT_TEST1: begin
                        prng_en <= 1'b0;
                        bp_pbit_test_mode <= 1'b1;
                        state <= s_BP_PBIT_TEST2;
                    end
                s_BP_PBIT_TEST2: begin
                        bp_pbit_test_mode <= 1'b0;
                        content_out <= {content_out[255:64],PBIT_OUT[63:0]};
                        state <= s_IDLE;
                    end
                s_PROG_BL1: begin
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
                            state <= s_IDLE;
                            content_out <= {content_out[255:160],content[163:4]};
                        end
                    end
                s_SOLVE_RNG_INIT: begin
                        FP_PUn <= 1'b0;
                        prng_en <= 1'b1;
                        no_refr_sG <= no_refr_sG;
                        no_refr_pG <= no_refr_pG;
                        refr_pG_sH <= refr_pG_sH;
                        refr_pG_pH <= refr_pG_pH;
                        VAR1_refr <= 0;
                        VAR2_refr <= 0;
                        VAR3_refr <= 0;
                        if (gen_var==1'b1 && do_trial==1'b1 && rng_init_cycle_counter==2) begin
                            VAR1 <= VAR1;
                            VAR2 <= rng_buffer[63:0] & variable_mask;
                            VAR3 <= rng_buffer[127:64] & variable_mask;
                        end else if (gen_var==1'b1 && rng_init_cycle_counter==3) begin
                            VAR1 <= rng_buffer[63:0] & variable_mask;
                            VAR2 <= VAR2;
                            VAR3 <= VAR3;
                        end else if (gen_var==1'b0) begin
                            VAR1 <= VAR1_init;
                            VAR2 <= VAR2_init;
                            VAR3 <= VAR3_init;
                        end else begin
                            VAR1 <= VAR1;
                            VAR2 <= VAR2;
                            VAR3 <= VAR3;
                        end
                                                
                        if (rng_init_cycle_counter < 5) begin
                            state <= s_SOLVE_RNG_INIT;
                            rng_init_cycle_counter <= rng_init_cycle_counter + 1;
                        end else begin
                            state <= s_SOLVE_FP;
                            rng_init_cycle_counter <= 0;
                        end
                    end
                    
                s_SOLVE_FP: begin
                        prng_en <= 1'b1;
                        restart_counter <= restart_counter;
                        no_refr_sG <= no_refr_sG;
                        refr_pG_sH <= refr_pG_sH;
                        refr_pG_pH <= refr_pG_pH;
                        no_refr_pG <= no_refr_pG;
                        prngbits_randVar <= PRNG_BITS[5:0];
                        
                        if (restart_flag1==1'b1) begin
                            VAR1 <= VAR1;
							VAR1_refr <= VAR1_refr;
                            flip_counter1 <= 0;
                        end else begin
                            VAR1 <= VAR1 ^ Var_to_flip;
							VAR1_refr <= Var_to_flip;
                            flip_counter1 <= flip_counter1 + 1;
                        end
                        restart_flag1 <= 1'b0;
                        fp_mode1 <= 1'b1;
                        bp_mode1 <= 1'b0;
                        flip_mode1 <= 1'b0;
                        
                        flip_counter2 <= flip_counter2;
                        flip_counter3 <= flip_counter3;
                        VAR2 <= VAR2;
                        VAR3 <= VAR3;
						VAR2_refr <= VAR2_refr;
						VAR3_refr <= VAR3_refr;
                        TRUE0_reg <= TRUE0;
                        TRUE1_reg <= TRUE1;
                        VSAB_OUT_reg <= VSAB_OUT;
                        PBIT_OUT_reg <= PBIT_OUT;
                        
                        if (do_trial==1'b1) begin
                            FP_PUn <= 1'b0;
                            if (restart_flag3==1'b0) begin
                                fp_mode3 <= 1'b0;
                                bp_mode3 <= 1'b1;
                                flip_mode3 <= 1'b0;
                            end else begin
                                fp_mode3 <= 1'b0;
                                bp_mode3 <= 1'b0;
                                flip_mode3 <= 1'b0;
                            end
                            if (restart_flag2==1'b0) begin
                                fp_mode2 <= 1'b0;
                                bp_mode2 <= 1'b0;
                                flip_mode2 <= 1'b1;
                                if (unsat==1'b1) begin
                                    if (flip_counter2 > max_flips) begin
                                        if (restart_counter >= max_restarts) begin
                                            state <= s_IDLE;
                                            content_out <= {content_out[255:92],restart_counter,flip_counter2,VAR2,1'b0};
                                        end else begin
                                            state <= s_SOLVE_RESTART;
                                            content_out <= content_out;
                                        end
                                    end else begin
                                        state <= s_SOLVE_BP;
                                        content_out <= content_out;
                                    end
                                end else begin 
                                    state <= s_IDLE;
                                    content_out <= {content_out[255:92],restart_counter,flip_counter2,VAR2,1'b1};
                                end
                            end else begin
                                fp_mode2 <= 1'b0;
                                bp_mode2 <= 1'b0;
                                flip_mode2 <= 1'b0;
                                content_out <= content_out;
                                state <= s_SOLVE_BP;
                            end 
                        end else begin
                            FP_PUn <= 1'b0;
                            state <= s_SOLVE_BP;
                            fp_mode3 <= 1'b0;
                            bp_mode3 <= 1'b0;
                            flip_mode3 <= 1'b0;
                            fp_mode2 <= 1'b0;
                            bp_mode2 <= 1'b0;
                            flip_mode2 <= 1'b0;
                            content_out <= content_out;
                        end
                    end
                    
                s_SOLVE_BP: begin
                        prng_en <= 1'b1;
                        restart_counter <= restart_counter;
                        no_refr_sG <= no_refr_sG;
                        no_refr_pG <= no_refr_pG;
                        refr_pG_sH <= refr_pG_sH;
                        refr_pG_pH <= refr_pG_pH;
                        prngbits_randVar <= PRNG_BITS[5:0];
                        
                        flip_counter1 <= flip_counter1;
                        VAR1 <= VAR1;
						VAR1_refr <= VAR1_refr;
                        fp_mode1 <= 1'b0;
                        bp_mode1 <= 1'b1;
                        flip_mode1 <= 1'b0;
                        
                        TRUE0_reg <= TRUE0;
                        TRUE1_reg <= TRUE1;
                        VSAB_OUT_reg <= VSAB_OUT;
                        PBIT_OUT_reg <= PBIT_OUT;
                        VAR3 <= VAR3;
						VAR3_refr <= VAR3_refr;
                        flip_counter3 <= flip_counter3;
                        
                        if (do_trial==1'b1) begin
                            FP_PUn <= 1'b0;
                            if (restart_flag2==1'b1) begin
                                VAR2 <= VAR2;
								VAR2_refr <= VAR2_refr;
                                flip_counter2 <= 0;
                            end else begin
                                VAR2 <= VAR2 ^ Var_to_flip;
								VAR2_refr <= Var_to_flip;
                                flip_counter2 <= flip_counter2 + 1;
                            end
                            restart_flag2 <= 1'b0;
                            fp_mode2 <= 1'b1;
                            bp_mode2 <= 1'b0;
                            flip_mode2 <= 1'b0;
                            
                            if (restart_flag3==1'b0) begin
                                fp_mode3 <= 1'b0;
                                bp_mode3 <= 1'b0;
                                flip_mode3 <= 1'b1;
                                if (unsat==1'b1) begin
                                    if (flip_counter3 > max_flips) begin
                                        if (restart_counter >= max_restarts) begin
                                            state <= s_IDLE;
                                            content_out <= {content_out[255:92],restart_counter,flip_counter3,VAR3,1'b0};
                                        end else begin
                                            state <= s_SOLVE_RESTART;
                                            content_out <= content_out;
                                        end
                                    end else begin
                                        state <= s_SOLVE_FLIP;
                                        content_out <= content_out;
                                    end
                                end else begin 
                                    state <= s_IDLE;
                                    content_out <= {content_out[255:92],restart_counter,flip_counter3,VAR3,1'b1};
                                end
                            end else begin
                                fp_mode3 <= 1'b0;
                                bp_mode3 <= 1'b0;
                                flip_mode3 <= 1'b0;
                                content_out <= content_out;
                                state <= s_SOLVE_FLIP;
                            end 
                            
                        end else begin
                            FP_PUn <= 1'b0;
                            VAR2 <= VAR2;
							VAR2_refr <= VAR2_refr;
                            flip_counter2 <= flip_counter2;
                            restart_flag2 <= restart_flag2;
                            fp_mode2 <= 1'b0;
                            bp_mode2 <= 1'b0;
                            flip_mode2 <= 1'b0;
                            
                            fp_mode3 <= 1'b0;
                            bp_mode3 <= 1'b0;
                            flip_mode3 <= 1'b0;
                            content_out <= content_out;
                            state <= s_SOLVE_FLIP;
                        end
                    end 
                    
                s_SOLVE_FLIP: begin
                        prng_en <= 1'b1;
                        restart_counter <= restart_counter;
                        no_refr_sG <= no_refr_sG;
                        no_refr_pG <= no_refr_pG;
                        refr_pG_sH <= refr_pG_sH;
                        refr_pG_pH <= refr_pG_pH;
                        prngbits_randVar <= PRNG_BITS[5:0];
                        
                        flip_counter1 <= flip_counter1;
                        VAR1 <= VAR1;
						VAR1_refr <= VAR1_refr;
                        fp_mode1 <= 1'b0;
                        bp_mode1 <= 1'b0;
                        flip_mode1 <= 1'b1;
                        
                        if (unsat==1'b1) begin
                            if (flip_counter1 > max_flips) begin
                                if (restart_counter >= max_restarts) begin
                                    state <= s_IDLE;
                                    content_out <= {content_out[255:92],restart_counter,flip_counter1,VAR1,1'b0};
                                end else begin
                                    state <= s_SOLVE_RESTART;
                                    content_out <= content_out;
                                end
                            end else begin
                                state <= s_SOLVE_FP;
                                content_out <= content_out;
                            end
                        end else begin 
                            state <= s_IDLE;
                            content_out <= {content_out[255:92],restart_counter,flip_counter1,VAR1,1'b1};
                        end
                        
                        TRUE0_reg <= TRUE0;
                        TRUE1_reg <= TRUE1;
                        VSAB_OUT_reg <= VSAB_OUT;
                        PBIT_OUT_reg <= PBIT_OUT;
                        VAR2 <= VAR2;
						VAR2_refr <= VAR2_refr;
                        flip_counter2 <= flip_counter2;
                            
                        if (do_trial==1'b1) begin
                            FP_PUn <= 1'b0;
                            fp_mode2 <= 1'b0;
                            bp_mode2 <= 1'b1;
                            flip_mode2 <= 1'b0;
                            
                            if (restart_flag3==1'b1) begin
                                VAR3 <= VAR3;
								VAR3_refr <= VAR3_refr;
                                flip_counter3 <= 0;
                            end else begin
                                VAR3 <= VAR3 ^ Var_to_flip;
								VAR3_refr <= Var_to_flip;
                                flip_counter3 <= flip_counter3 + 1;
                            end
                            restart_flag3 <= 1'b0;
                            fp_mode3 <= 1'b1;
                            bp_mode3 <= 1'b0;
                            flip_mode3 <= 1'b0;
                            
                        end else begin
                            FP_PUn <= 1'b0;
                            fp_mode2 <= 1'b0;
                            bp_mode2 <= 1'b0;
                            flip_mode2 <= 1'b0;
                            
                            VAR3 <= VAR3;
							VAR3_refr <= VAR3_refr;
                            flip_counter3 <= flip_counter3;
                            restart_flag3 <= restart_flag3;
                            fp_mode3 <= 1'b0;
                            bp_mode3 <= 1'b0;
                            flip_mode3 <= 1'b0;
                        end
                    end                   
                s_SOLVE_RESTART: begin
                        FP_PUn <= 1'b0;
                        prng_en <= 1'b1;
                        no_refr_sG <= no_refr_sG;
                        no_refr_pG <= no_refr_pG;
                        refr_pG_sH <= refr_pG_sH;
                        refr_pG_pH <= refr_pG_pH;
                        fp_mode1 <= 1'b0;
                        bp_mode1 <= 1'b0;
                        flip_mode1 <= 1'b0;
                        fp_mode2 <= 1'b0;
                        bp_mode2 <= 1'b0;
                        flip_mode2 <= 1'b0;
                        fp_mode3 <= 1'b0;
                        bp_mode3 <= 1'b0;
                        flip_mode3 <= 1'b0;
                        flip_counter1 <= 0;
                        flip_counter2 <= 0;
                        flip_counter3 <= 0;
                        restart_flag1 <= 1'b1;
                        restart_flag2 <= 1'b1;
                        restart_flag3 <= 1'b1;
                        TRUE0_reg <= 0;
                        TRUE1_reg <= 0;
                        VSAB_OUT_reg <= 0;
                        PBIT_OUT_reg <= 0;
                        VAR1_refr <= 0;
                        VAR2_refr <= 0;
                        VAR3_refr <= 0;
                        if (do_trial==1'b1 && rng_init_cycle_counter==3) begin
                            VAR1 <= VAR1;
                            VAR2 <= rng_buffer[63:0] & variable_mask;
                            VAR3 <= rng_buffer[127:64] & variable_mask;
                        end else if (rng_init_cycle_counter==2) begin
                            VAR1 <= rng_buffer[63:0] & variable_mask;
                            VAR2 <= VAR2;
                            VAR3 <= VAR3;
                        end else begin
                            VAR1 <= VAR1;
                            VAR2 <= VAR2;
                            VAR3 <= VAR3;
                        end
                                                
                        if (rng_init_cycle_counter < 5) begin
                            state <= s_SOLVE_RESTART;
                            rng_init_cycle_counter <= rng_init_cycle_counter + 1;
                            restart_counter <= restart_counter;
                        end else begin
                            state <= s_SOLVE_FP;
                            rng_init_cycle_counter <= 0;
                            restart_counter <= restart_counter + 1;
                        end
                    end
                        
                s_PRNG_TEST1: begin
                        prng_en <= 1'b0;
                        state <= s_PRNG_TEST2;
                    end
                s_PRNG_TEST2: begin
                        content_out <= {content_out[255:128],PRNG_BITS[127:0]};
                        state <= s_IDLE;
                    end
                default: begin
                            BUSY <= 1'b0;
                            state <= s_IDLE;
                            pbit_test_ext_mode <= 1'b0;
                            pbit_test_int_mode <= 1'b0;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            fp_mode1 <= 1'b0;
                            fp_mode2 <= 1'b0;
                            fp_mode3 <= 1'b0;
                            bp_mode1 <= 1'b0;
                            bp_mode2 <= 1'b0;
                            bp_mode3 <= 1'b0;
                            flip_mode1 <= 1'b0;
                            flip_mode2 <= 1'b0;
                            flip_mode3 <= 1'b0;
                            prog_mode <= 1'b0;
                            prog_bl_en <= 1'b0;
                            prog_wl_en <= 1'b0;
                            prog_bl_wait_counter <= 1'b0;
                            prog_wl_wait_counter <= 1'b0;
                            prog_postwl_wait_counter <= 1'b0;
                            VAR1 <= VAR1_init;
                            VAR2 <= VAR2_init;
                            VAR3 <= VAR3_init;
                            VAR1_refr <= 0;
                            VAR2_refr <= 0;
                            VAR3_refr <= 0;
                            prngbits_randVar <= 0;
                            restart_flag1 <= 1'b1;
                            restart_flag2 <= 1'b1;
                            restart_flag3 <= 1'b1;
                            flip_counter1 <= 0;
                            flip_counter2 <= 0;
                            flip_counter3 <= 0;
                            TRUE0_reg <= 0;
                            TRUE1_reg <= 0;
                            VSAB_OUT_reg <= 0;
                            PBIT_OUT_reg <= 0;
                            prng_en <= 1'b0;
                            content_out <= 0;
                            rng_init_cycle_counter <= 0;
                            restart_counter <= 1;
                            no_refr_sG <= 1'b0;
                            no_refr_pG <= 1'b0;
                            refr_pG_sH <= 1'b0;
                            refr_pG_pH <= 1'b0;
                            FP_PUn <= 1'b1;
                            bp_pbit_test_mode <= 1'b0;
                         end
           endcase
        end
    end
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule

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


///////////////////////////////////////////////////////////////////////////////////32-BIT OUTPUT XORMIX PRNG/////////////////////////////////////////////////////////////////////////////////////////////////
module xormix128
    #(
        parameter streams = 1
    )
    (
        
        // clock and synchronous reset
        input wire clk,
        input wire rst,
        
        // configuration
        input wire [127 : 0] seed_x,
        input wire [128 * streams - 1 : 0] seed_y,
        
        // random number generator
        input wire enable,
        output wire [128 * streams - 1 : 0] result
        
    );
    
    localparam [128 * 128 - 1 : 0] salts = {
        128'h426d334d0210953d4fbc5eb23baa5b89, 128'hc660367182530702a8940562e769aa34, 128'h20afd57548c2a8194cae459746ef3ae2, 128'h6e6705040215fb0cc52b1723b77d8ca7,
        128'h96a7aabc97aeaf611bdb8ecfba049814, 128'h03c6b7bc51586c46c24dabc28e5104c1, 128'h2c009fa5c7f106bbb3c1825b2df6a2f6, 128'h8264b4091f7515269929e1ae0304ba9e,
        128'hea225519f1f55c7c16e4e2042546cf60, 128'h7a6982ded6aa1dfa91281fd5ec28196d, 128'h2136944a515be3f2c586e97599de219a, 128'h46d6eb2ac8cf719a2f12eb3b24e43b6b,
        128'hd6fe5e4c9f390bb6a5523bdaa7d672ce, 128'h9b99ae3537b38828c33f629c27654c29, 128'hbabeb4db43e98bfa20a036758e06ead4, 128'h6fe1bd7b2bd57f1d247318da9d130d0a,
        128'hb333a13878ed6467afc644cc4a7fba8a, 128'h0deea11cc253bddcc56da2d3f7a67ebc, 128'h11b01d55dd67c0c6e42ebea0b91fe54f, 128'h957b133698028d825c50a7eddc43a709,
        128'h7aa46106c2c9f687828e598d46c3b205, 128'h026439f83ae85ad94a127c8b01990c54, 128'hd5ae4ce8a7ce08fcffafc51ae8a5fb93, 128'hfdf7d79bc286586dc82f31311f9e6fca,
        128'hb334f15329dccb8cd1fd224b16e58d79, 128'h2863d4577783878fd8a58035655c3deb, 128'hda03176c01e50cdfe333b2d35fa015b6, 128'hf7ad24f6275633672634c1d79f45892d,
        128'h77b676851c7abda850afc4b495085f2c, 128'h3a6f475c1ecb7c13d996cd4441425a97, 128'h5ded207cd2e59c3da8fab36f9a21157f, 128'haa5cd73b8a0940b4fc5b3ac93926cd6a,
        128'ha355f9fd7fbf38fbcc8af45404fcc6be, 128'h397e57c92f9861547b24ca77b1cea27c, 128'h43cb709d85da0e5015a892a614986841, 128'h16e10d8df52cc48442a5d5256969aa9a,
        128'hbcbfbb13f986a39653cfbf7152d255d2, 128'h8aed916e4d36e7d3441a670f9380f30d, 128'hdbeaae962a0a698f5088ffd970256144, 128'h47128844e1e9270bf8df480e46fb4bc6,
        128'h65a35232d8d0dbe4790a2a7edd383fe0, 128'hdf182f5cab14cd39cf622a6d3bff6107, 128'h304931f308d9a27c11fb3a34ebedbe58, 128'h6950dd6b52bccfa99b73077b4199b59c,
        128'h65bc59d13c9f1c020606c022e177884c, 128'h857e76882355a43174069f24aaef94f3, 128'h20c9d2c922f18772e15b109bc8816f21, 128'he996c824b1a3b36d7bf40c8bf34821d5,
        128'hc8282c0619a4ab4ab3bb0c8667adf5ec, 128'h3696ca65addca66ffe04506afccfd23f, 128'hf3c2b154f0073720e761fae8b3d9d4cd, 128'h57960c3e5964c51b258678211c569f01,
        128'hc3c09bd89e26a8d21639de509e92ea9e, 128'hecd0cfe2ef3a2b6297a49e801f6214fe, 128'hc8d9279162d7730eca5dde8c906754f6, 128'h2a58c173ee11d4cafbc52f5cd9fc10bb,
        128'h923c62e69bde4f75b7b11297d6d46d4e, 128'hbfd591a612ab72bf2e682e54723518c7, 128'h17542b21cbec8d1495d843f20f9358b1, 128'haee9cf0e3d634e786dbe13197f40cc43,
        128'hb1af2c9c8c29a4e474d2338b5bad0afb, 128'ha0e7875e6c8cad2ef005cbf2adbb271c, 128'h730e3687735b1889b88a8e07cf291032, 128'hc5fbf5c3a47655d67e027925e7675b94,
        128'he20c664651c3d42328707a583af04239, 128'h0db87bc5c1e6728379b2d3a9b29b5521, 128'h97d615c53cd4923c614d38a4b90171b2, 128'hafd9af4b5cf7191f1ea35cb9fd2e62f9,
        128'h5e684ded016cb40d387f22aea9be95c6, 128'hb50a5ea77901f55f0434eb9ae66b5b33, 128'h6c65832f23f43eae6ef671a872141a82, 128'h80d258457c5bc95074c8d42a5a86f753,
        128'hae5910192d2aa1f4812c455df6cf92d0, 128'hc7feacc68d29d6fac50981d3c4088e92, 128'he3264b5d279d0575b9ec55cb7c363c39, 128'h02b67174dc3c1d518733c6cd6eb481e5,
        128'h7e1e701939f16165359190cf59a54f04, 128'he0bd8f5a2afeb40288b78f95c2b1984f, 128'h9a69338b783383a3f77adc87e60bcd0f, 128'h51981d2ac6601c9d7618b748f434fe31,
        128'hd9bf1cdf18b5d798beff10e60b0f9ac6, 128'h5933613e9f3214ebd8f5cd3857a43a64, 128'hd1d1ea95a0e8c0bf3d5e8a1f3bdac15b, 128'hf37135381111fd49faa63ff210faa19e,
        128'h85c76e9db31ad05530bb301a56b5218e, 128'h4c09a5bcf925c18d83718e4b5e59cb10, 128'h22b34c2e328f75bdc413ba90f1784dec, 128'hb7ab9b30669a5a6070e8ebe1e1b3a93e,
        128'h5e6024e9ee3f909d7ea8be62f7d37e6f, 128'h360f32162410c113d593ba723fc7d8c6, 128'hc8e4c9c9ff5231667370d2ffaaf50692, 128'hbf53a13583b45c0c767602e169da1734,
        128'h89d5524900fe6b6701072fd7e66b3aa3, 128'h301d9ba87df8d36c59a70c4f5c903b9d, 128'h658f170a3d5eb1382859bd534c03eddc, 128'hb499352d4c2c6d328f36503aa9322a10,
        128'h0e0a135ebd4ade22fa6502f6572ce3b5, 128'hf4ca5329109c00d36cefa419fabae38e, 128'hf5474098a6f8e72c88a90385e1bb7ec4, 128'h992ecb2546eba50e3c3a38d31856c3be,
        128'h20a9e692001abc41d2675a5ef558c9ca, 128'h3129867e0d1cae8743365f3838f1a6f2, 128'h14e1dbdb706146c87ccd29aa9617940c, 128'h7331f65d083f981679bdb371e10deab6,
        128'he0cda84666200d77794f864e524e3d05, 128'h0c2437807aaa24ff76d338b2696cbd46, 128'he8ebde2abd705c86d8f9fd86993a5e7b, 128'h0e751da1db416c312ebdc43faa118a3d,
        128'hb87010456ab8d88b8dd4c95dc5d17fc8, 128'ha30c5a4fca8b3b774f1f20a17431ea84, 128'h0102213a944f7a3b11412a294eaec4e3, 128'h5401edc6eacf9376c9b1740ae1682c7c,
        128'h51690ae0ba825d13e93a50422bf7c93e, 128'h131b25f5290a2d7c300c62a1f3f988a7, 128'h8333c010a7a2c1de068d13b2573889f5, 128'he84ed06e8ef90d826a4794d71bfde238,
        128'h0bfadd9ea78537202f0dc6387e490584, 128'h44c0eaa7acea07dc067157b612a796d0, 128'h58c7d8956ee996cb3201f2fcb2913077, 128'hd4d69acbbb4ef412be6edd8b7b1da9c4,
        128'hbb051ea62ebdb876a498e6edd1a7fff8, 128'hf91ab0c9d06a6fab8f59b935b3e19ad0, 128'hb310cd417e865701852c0f137baa77c1, 128'h9575b7768be3b6f63b37be5e9323f719,
        128'h103dca29fc314d3f05e11fe401cf6fbb, 128'h381bbba7d431439e3a7e57b7273176a3, 128'h7ff3ef25ad7380b8adf9a9bdbff1223e, 128'h13262f1ed94d35de5037b5ab9dbc3488
    };
    
    reg [127 : 0] r_state_x;
    reg [128 * streams - 1 : 0] r_state_y;
    
    reg [128 * streams - 1 : 0] v_state_y1;
    reg [128 * streams - 1 : 0] v_state_y2;
    
    reg [127 : 0] v_mixin;
    reg [127 : 0] v_mixup;
    reg [127 : 0] v_res;
    
    integer i;
    
    assign result = r_state_y;
    
    always @(*) begin
        
        for (i = 0; i < streams; i = i + 1) begin
            v_mixin = r_state_x ^ salts[128 * i +: 128];
            v_mixup = r_state_y[128 * ((i + 1) % streams) +: 128];
            v_res[  0] = v_mixup[  0] ^ (v_mixup[ 47] & ~v_mixup[ 61]) ^ v_mixup[ 56] ^ v_mixup[ 62] ^ v_mixin[(i +  68) % 128];
            v_res[  1] = v_mixup[  1] ^ (v_mixup[ 48] & ~v_mixup[ 62]) ^ v_mixup[ 57] ^ v_mixup[ 63] ^ v_mixin[(i +  77) % 128];
            v_res[  2] = v_mixup[  2] ^ (v_mixup[ 49] & ~v_mixup[ 63]) ^ v_mixup[ 58] ^ v_mixup[ 64] ^ v_mixin[(i +  52) % 128];
            v_res[  3] = v_mixup[  3] ^ (v_mixup[ 50] & ~v_mixup[ 64]) ^ v_mixup[ 59] ^ v_mixup[ 65] ^ v_mixin[(i + 101) % 128];
            v_res[  4] = v_mixup[  4] ^ (v_mixup[ 51] & ~v_mixup[ 65]) ^ v_mixup[ 60] ^ v_mixup[ 66] ^ v_mixin[(i + 107) % 128];
            v_res[  5] = v_mixup[  5] ^ (v_mixup[ 52] & ~v_mixup[ 66]) ^ v_mixup[ 61] ^ v_mixup[ 67] ^ v_mixin[(i + 124) % 128];
            v_res[  6] = v_mixup[  6] ^ (v_mixup[ 53] & ~v_mixup[ 67]) ^ v_mixup[ 62] ^ v_mixup[ 68] ^ v_mixin[(i + 117) % 128];
            v_res[  7] = v_mixup[  7] ^ (v_mixup[ 54] & ~v_mixup[ 68]) ^ v_mixup[ 63] ^ v_mixup[ 69] ^ v_mixin[(i + 113) % 128];
            v_res[  8] = v_mixup[  8] ^ (v_mixup[ 55] & ~v_mixup[ 69]) ^ v_mixup[ 64] ^ v_mixup[ 70] ^ v_mixin[(i +  96) % 128];
            v_res[  9] = v_mixup[  9] ^ (v_mixup[ 56] & ~v_mixup[ 70]) ^ v_mixup[ 65] ^ v_mixup[ 71] ^ v_mixin[(i +  92) % 128];
            v_res[ 10] = v_mixup[ 10] ^ (v_mixup[ 57] & ~v_mixup[ 71]) ^ v_mixup[ 66] ^ v_mixup[ 72] ^ v_mixin[(i +   7) % 128];
            v_res[ 11] = v_mixup[ 11] ^ (v_mixup[ 58] & ~v_mixup[ 72]) ^ v_mixup[ 67] ^ v_mixup[ 73] ^ v_mixin[(i +  25) % 128];
            v_res[ 12] = v_mixup[ 12] ^ (v_mixup[ 59] & ~v_mixup[ 73]) ^ v_mixup[ 68] ^ v_mixup[ 74] ^ v_mixin[(i +  21) % 128];
            v_res[ 13] = v_mixup[ 13] ^ (v_mixup[ 60] & ~v_mixup[ 74]) ^ v_mixup[ 69] ^ v_mixup[ 75] ^ v_mixin[(i +  28) % 128];
            v_res[ 14] = v_mixup[ 14] ^ (v_mixup[ 61] & ~v_mixup[ 75]) ^ v_mixup[ 70] ^ v_mixup[ 76] ^ v_mixin[(i +  60) % 128];
            v_res[ 15] = v_mixup[ 15] ^ (v_mixup[ 62] & ~v_mixup[ 76]) ^ v_mixup[ 71] ^ v_mixup[ 77] ^ v_mixin[(i +   1) % 128];
            v_res[ 16] = v_mixup[ 16] ^ (v_mixup[ 63] & ~v_mixup[ 77]) ^ v_mixup[ 72] ^ v_mixup[ 78] ^ v_mixin[(i +  17) % 128];
            v_res[ 17] = v_mixup[ 17] ^ (v_mixup[ 64] & ~v_mixup[ 78]) ^ v_mixup[ 73] ^ v_mixup[ 79] ^ v_mixin[(i +  26) % 128];
            v_res[ 18] = v_mixup[ 18] ^ (v_mixup[ 65] & ~v_mixup[ 79]) ^ v_mixup[ 74] ^ v_mixup[ 80] ^ v_mixin[(i +  44) % 128];
            v_res[ 19] = v_mixup[ 19] ^ (v_mixup[ 66] & ~v_mixup[ 80]) ^ v_mixup[ 75] ^ v_mixup[ 81] ^ v_mixin[(i +  27) % 128];
            v_res[ 20] = v_mixup[ 20] ^ (v_mixup[ 67] & ~v_mixup[ 81]) ^ v_mixup[ 76] ^ v_mixup[ 82] ^ v_mixin[(i +  59) % 128];
            v_res[ 21] = v_mixup[ 21] ^ (v_mixup[ 68] & ~v_mixup[ 82]) ^ v_mixup[ 77] ^ v_mixup[ 83] ^ v_mixin[(i + 127) % 128];
            v_res[ 22] = v_mixup[ 22] ^ (v_mixup[ 69] & ~v_mixup[ 83]) ^ v_mixup[ 78] ^ v_mixup[ 84] ^ v_mixin[(i +  46) % 128];
            v_res[ 23] = v_mixup[ 23] ^ (v_mixup[ 70] & ~v_mixup[ 84]) ^ v_mixup[ 79] ^ v_mixup[ 85] ^ v_mixin[(i + 110) % 128];
            v_res[ 24] = v_mixup[ 24] ^ (v_mixup[ 71] & ~v_mixup[ 85]) ^ v_mixup[ 80] ^ v_mixup[ 86] ^ v_mixin[(i +  83) % 128];
            v_res[ 25] = v_mixup[ 25] ^ (v_mixup[ 72] & ~v_mixup[ 86]) ^ v_mixup[ 81] ^ v_mixup[ 87] ^ v_mixin[(i +  98) % 128];
            v_res[ 26] = v_mixup[ 26] ^ (v_mixup[ 73] & ~v_mixup[ 87]) ^ v_mixup[ 82] ^ v_mixup[ 88] ^ v_mixin[(i +  54) % 128];
            v_res[ 27] = v_mixup[ 27] ^ (v_mixup[ 74] & ~v_mixup[ 88]) ^ v_mixup[ 83] ^ v_mixup[ 89] ^ v_mixin[(i + 126) % 128];
            v_res[ 28] = v_mixup[ 28] ^ (v_mixup[ 75] & ~v_mixup[ 89]) ^ v_mixup[ 84] ^ v_mixup[ 90] ^ v_mixin[(i +  29) % 128];
            v_res[ 29] = v_mixup[ 29] ^ (v_mixup[ 76] & ~v_mixup[ 90]) ^ v_mixup[ 85] ^ v_mixup[ 91] ^ v_mixin[(i +  95) % 128];
            v_res[ 30] = v_mixup[ 30] ^ (v_mixup[ 77] & ~v_mixup[ 91]) ^ v_mixup[ 86] ^ v_mixup[ 92] ^ v_mixin[(i +   0) % 128];
            v_res[ 31] = v_mixup[ 31] ^ (v_mixup[ 78] & ~v_mixup[ 92]) ^ v_mixup[ 87] ^ v_mixup[ 93] ^ v_mixin[(i +  20) % 128];
            v_res[ 32] = v_mixup[ 32] ^ (v_mixup[ 79] & ~v_mixup[ 93]) ^ v_mixup[ 88] ^ v_mixup[ 94] ^ v_mixin[(i +  66) % 128];
            v_res[ 33] = v_mixup[ 33] ^ (v_mixup[ 80] & ~v_mixup[ 94]) ^ v_mixup[ 89] ^ v_mixup[ 95] ^ v_mixin[(i +  89) % 128];
            v_res[ 34] = v_mixup[ 34] ^ (v_mixup[ 81] & ~v_mixup[ 95]) ^ v_mixup[ 90] ^ v_mixup[ 96] ^ v_mixin[(i +   9) % 128];
            v_res[ 35] = v_mixup[ 35] ^ (v_mixup[ 82] & ~v_mixup[ 96]) ^ v_mixup[ 91] ^ v_mixup[ 97] ^ v_mixin[(i +  19) % 128];
            v_res[ 36] = v_mixup[ 36] ^ (v_mixup[ 83] & ~v_mixup[ 97]) ^ v_mixup[ 92] ^ v_mixup[ 98] ^ v_mixin[(i +  91) % 128];
            v_res[ 37] = v_mixup[ 37] ^ (v_mixup[ 84] & ~v_mixup[ 98]) ^ v_mixup[ 93] ^ v_mixup[ 99] ^ v_mixin[(i +  10) % 128];
            v_res[ 38] = v_mixup[ 38] ^ (v_mixup[ 85] & ~v_mixup[ 99]) ^ v_mixup[ 94] ^ v_mixup[100] ^ v_mixin[(i +  58) % 128];
            v_res[ 39] = v_mixup[ 39] ^ (v_mixup[ 86] & ~v_mixup[100]) ^ v_mixup[ 95] ^ v_mixup[101] ^ v_mixin[(i + 120) % 128];
            v_res[ 40] = v_mixup[ 40] ^ (v_mixup[ 87] & ~v_mixup[101]) ^ v_mixup[ 96] ^ v_mixup[102] ^ v_mixin[(i +  11) % 128];
            v_res[ 41] = v_mixup[ 41] ^ (v_mixup[ 88] & ~v_mixup[102]) ^ v_mixup[ 97] ^ v_mixup[103] ^ v_mixin[(i + 100) % 128];
            v_res[ 42] = v_mixup[ 42] ^ (v_mixup[ 89] & ~v_mixup[103]) ^ v_mixup[ 98] ^ v_mixup[104] ^ v_mixin[(i +  49) % 128];
            v_res[ 43] = v_mixup[ 43] ^ (v_mixup[ 90] & ~v_mixup[104]) ^ v_mixup[ 99] ^ v_mixup[105] ^ v_mixin[(i +  82) % 128];
            v_res[ 44] = v_mixup[ 44] ^ (v_mixup[ 91] & ~v_mixup[105]) ^ v_mixup[100] ^ v_mixup[106] ^ v_mixin[(i +  75) % 128];
            v_res[ 45] = v_mixup[ 45] ^ (v_mixup[ 92] & ~v_mixup[106]) ^ v_mixup[101] ^ v_mixup[107] ^ v_mixin[(i +  16) % 128];
            v_res[ 46] = v_mixup[ 46] ^ (v_mixup[ 93] & ~v_mixup[107]) ^ v_mixup[102] ^ v_mixup[108] ^ v_mixin[(i +  36) % 128];
            v_res[ 47] = v_mixup[ 47] ^ (v_mixup[ 94] & ~v_mixup[108]) ^ v_mixup[103] ^ v_mixup[109] ^ v_mixin[(i + 103) % 128];
            v_res[ 48] = v_mixup[ 48] ^ (v_mixup[ 95] & ~v_mixup[109]) ^ v_mixup[104] ^ v_mixup[110] ^ v_mixin[(i +  62) % 128];
            v_res[ 49] = v_mixup[ 49] ^ (v_mixup[ 96] & ~v_mixup[110]) ^ v_mixup[105] ^ v_mixup[111] ^ v_mixin[(i +  50) % 128];
            v_res[ 50] = v_mixup[ 50] ^ (v_mixup[ 97] & ~v_mixup[111]) ^ v_mixup[106] ^ v_mixup[112] ^ v_mixin[(i +  65) % 128];
            v_res[ 51] = v_mixup[ 51] ^ (v_mixup[ 98] & ~v_mixup[112]) ^ v_mixup[107] ^ v_mixup[113] ^ v_mixin[(i + 112) % 128];
            v_res[ 52] = v_mixup[ 52] ^ (v_mixup[ 99] & ~v_mixup[113]) ^ v_mixup[108] ^ v_mixup[114] ^ v_mixin[(i +  24) % 128];
            v_res[ 53] = v_mixup[ 53] ^ (v_mixup[100] & ~v_mixup[114]) ^ v_mixup[109] ^ v_mixup[115] ^ v_mixin[(i +  33) % 128];
            v_res[ 54] = v_mixup[ 54] ^ (v_mixup[101] & ~v_mixup[115]) ^ v_mixup[110] ^ v_mixup[116] ^ v_mixin[(i +  51) % 128];
            v_res[ 55] = v_mixup[ 55] ^ (v_mixup[102] & ~v_mixup[116]) ^ v_mixup[111] ^ v_mixup[117] ^ v_mixin[(i +  86) % 128];
            v_res[ 56] = v_mixup[ 56] ^ (v_mixup[103] & ~v_mixup[117]) ^ v_mixup[112] ^ v_mixup[118] ^ v_mixin[(i +  40) % 128];
            v_res[ 57] = v_mixup[ 57] ^ (v_mixup[104] & ~v_mixup[118]) ^ v_mixup[113] ^ v_mixup[119] ^ v_mixin[(i + 102) % 128];
            v_res[ 58] = v_mixup[ 58] ^ (v_mixup[105] & ~v_mixup[119]) ^ v_mixup[114] ^ v_mixup[120] ^ v_mixin[(i +  48) % 128];
            v_res[ 59] = v_mixup[ 59] ^ (v_mixup[106] & ~v_mixup[120]) ^ v_mixup[115] ^ v_mixup[121] ^ v_mixin[(i +  81) % 128];
            v_res[ 60] = v_mixup[ 60] ^ (v_mixup[107] & ~v_mixup[121]) ^ v_mixup[116] ^ v_mixup[122] ^ v_mixin[(i + 125) % 128];
            v_res[ 61] = v_mixup[ 61] ^ (v_mixup[108] & ~v_mixup[122]) ^ v_mixup[117] ^ v_mixup[123] ^ v_mixin[(i +  34) % 128];
            v_res[ 62] = v_mixup[ 62] ^ (v_mixup[109] & ~v_mixup[123]) ^ v_mixup[118] ^ v_mixup[124] ^ v_mixin[(i +  56) % 128];
            v_res[ 63] = v_mixup[ 63] ^ (v_mixup[110] & ~v_mixup[124]) ^ v_mixup[119] ^ v_mixup[125] ^ v_mixin[(i +  73) % 128];
            v_state_y1[128 * i +: 128] = {v_res, r_state_y[128 * i + 64 +: 64]};
        end
        
        for (i = 0; i < streams; i = i + 1) begin
            v_mixin = r_state_x ^ salts[128 * i +: 128];
            v_mixup = v_state_y1[128 * ((i + 1) % streams) +: 128];
            v_res[  0] = v_mixup[  0] ^ (v_mixup[ 47] & ~v_mixup[ 61]) ^ v_mixup[ 56] ^ v_mixup[ 62] ^ v_mixin[(i +  32) % 128];
            v_res[  1] = v_mixup[  1] ^ (v_mixup[ 48] & ~v_mixup[ 62]) ^ v_mixup[ 57] ^ v_mixup[ 63] ^ v_mixin[(i + 118) % 128];
            v_res[  2] = v_mixup[  2] ^ (v_mixup[ 49] & ~v_mixup[ 63]) ^ v_mixup[ 58] ^ v_mixup[ 64] ^ v_mixin[(i +  78) % 128];
            v_res[  3] = v_mixup[  3] ^ (v_mixup[ 50] & ~v_mixup[ 64]) ^ v_mixup[ 59] ^ v_mixup[ 65] ^ v_mixin[(i +  69) % 128];
            v_res[  4] = v_mixup[  4] ^ (v_mixup[ 51] & ~v_mixup[ 65]) ^ v_mixup[ 60] ^ v_mixup[ 66] ^ v_mixin[(i +  45) % 128];
            v_res[  5] = v_mixup[  5] ^ (v_mixup[ 52] & ~v_mixup[ 66]) ^ v_mixup[ 61] ^ v_mixup[ 67] ^ v_mixin[(i +   6) % 128];
            v_res[  6] = v_mixup[  6] ^ (v_mixup[ 53] & ~v_mixup[ 67]) ^ v_mixup[ 62] ^ v_mixup[ 68] ^ v_mixin[(i +  93) % 128];
            v_res[  7] = v_mixup[  7] ^ (v_mixup[ 54] & ~v_mixup[ 68]) ^ v_mixup[ 63] ^ v_mixup[ 69] ^ v_mixin[(i +  53) % 128];
            v_res[  8] = v_mixup[  8] ^ (v_mixup[ 55] & ~v_mixup[ 69]) ^ v_mixup[ 64] ^ v_mixup[ 70] ^ v_mixin[(i + 116) % 128];
            v_res[  9] = v_mixup[  9] ^ (v_mixup[ 56] & ~v_mixup[ 70]) ^ v_mixup[ 65] ^ v_mixup[ 71] ^ v_mixin[(i +  84) % 128];
            v_res[ 10] = v_mixup[ 10] ^ (v_mixup[ 57] & ~v_mixup[ 71]) ^ v_mixup[ 66] ^ v_mixup[ 72] ^ v_mixin[(i +   3) % 128];
            v_res[ 11] = v_mixup[ 11] ^ (v_mixup[ 58] & ~v_mixup[ 72]) ^ v_mixup[ 67] ^ v_mixup[ 73] ^ v_mixin[(i +  97) % 128];
            v_res[ 12] = v_mixup[ 12] ^ (v_mixup[ 59] & ~v_mixup[ 73]) ^ v_mixup[ 68] ^ v_mixup[ 74] ^ v_mixin[(i +  99) % 128];
            v_res[ 13] = v_mixup[ 13] ^ (v_mixup[ 60] & ~v_mixup[ 74]) ^ v_mixup[ 69] ^ v_mixup[ 75] ^ v_mixin[(i +  39) % 128];
            v_res[ 14] = v_mixup[ 14] ^ (v_mixup[ 61] & ~v_mixup[ 75]) ^ v_mixup[ 70] ^ v_mixup[ 76] ^ v_mixin[(i +  70) % 128];
            v_res[ 15] = v_mixup[ 15] ^ (v_mixup[ 62] & ~v_mixup[ 76]) ^ v_mixup[ 71] ^ v_mixup[ 77] ^ v_mixin[(i + 119) % 128];
            v_res[ 16] = v_mixup[ 16] ^ (v_mixup[ 63] & ~v_mixup[ 77]) ^ v_mixup[ 72] ^ v_mixup[ 78] ^ v_mixin[(i +  72) % 128];
            v_res[ 17] = v_mixup[ 17] ^ (v_mixup[ 64] & ~v_mixup[ 78]) ^ v_mixup[ 73] ^ v_mixup[ 79] ^ v_mixin[(i +  14) % 128];
            v_res[ 18] = v_mixup[ 18] ^ (v_mixup[ 65] & ~v_mixup[ 79]) ^ v_mixup[ 74] ^ v_mixup[ 80] ^ v_mixin[(i +  64) % 128];
            v_res[ 19] = v_mixup[ 19] ^ (v_mixup[ 66] & ~v_mixup[ 80]) ^ v_mixup[ 75] ^ v_mixup[ 81] ^ v_mixin[(i + 121) % 128];
            v_res[ 20] = v_mixup[ 20] ^ (v_mixup[ 67] & ~v_mixup[ 81]) ^ v_mixup[ 76] ^ v_mixup[ 82] ^ v_mixin[(i +  76) % 128];
            v_res[ 21] = v_mixup[ 21] ^ (v_mixup[ 68] & ~v_mixup[ 82]) ^ v_mixup[ 77] ^ v_mixup[ 83] ^ v_mixin[(i +  22) % 128];
            v_res[ 22] = v_mixup[ 22] ^ (v_mixup[ 69] & ~v_mixup[ 83]) ^ v_mixup[ 78] ^ v_mixup[ 84] ^ v_mixin[(i + 104) % 128];
            v_res[ 23] = v_mixup[ 23] ^ (v_mixup[ 70] & ~v_mixup[ 84]) ^ v_mixup[ 79] ^ v_mixup[ 85] ^ v_mixin[(i +  63) % 128];
            v_res[ 24] = v_mixup[ 24] ^ (v_mixup[ 71] & ~v_mixup[ 85]) ^ v_mixup[ 80] ^ v_mixup[ 86] ^ v_mixin[(i + 106) % 128];
            v_res[ 25] = v_mixup[ 25] ^ (v_mixup[ 72] & ~v_mixup[ 86]) ^ v_mixup[ 81] ^ v_mixup[ 87] ^ v_mixin[(i +  15) % 128];
            v_res[ 26] = v_mixup[ 26] ^ (v_mixup[ 73] & ~v_mixup[ 87]) ^ v_mixup[ 82] ^ v_mixup[ 88] ^ v_mixin[(i +   2) % 128];
            v_res[ 27] = v_mixup[ 27] ^ (v_mixup[ 74] & ~v_mixup[ 88]) ^ v_mixup[ 83] ^ v_mixup[ 89] ^ v_mixin[(i +  42) % 128];
            v_res[ 28] = v_mixup[ 28] ^ (v_mixup[ 75] & ~v_mixup[ 89]) ^ v_mixup[ 84] ^ v_mixup[ 90] ^ v_mixin[(i +  41) % 128];
            v_res[ 29] = v_mixup[ 29] ^ (v_mixup[ 76] & ~v_mixup[ 90]) ^ v_mixup[ 85] ^ v_mixup[ 91] ^ v_mixin[(i +  18) % 128];
            v_res[ 30] = v_mixup[ 30] ^ (v_mixup[ 77] & ~v_mixup[ 91]) ^ v_mixup[ 86] ^ v_mixup[ 92] ^ v_mixin[(i + 123) % 128];
            v_res[ 31] = v_mixup[ 31] ^ (v_mixup[ 78] & ~v_mixup[ 92]) ^ v_mixup[ 87] ^ v_mixup[ 93] ^ v_mixin[(i + 114) % 128];
            v_res[ 32] = v_mixup[ 32] ^ (v_mixup[ 79] & ~v_mixup[ 93]) ^ v_mixup[ 88] ^ v_mixup[ 94] ^ v_mixin[(i +   8) % 128];
            v_res[ 33] = v_mixup[ 33] ^ (v_mixup[ 80] & ~v_mixup[ 94]) ^ v_mixup[ 89] ^ v_mixup[ 95] ^ v_mixin[(i + 115) % 128];
            v_res[ 34] = v_mixup[ 34] ^ (v_mixup[ 81] & ~v_mixup[ 95]) ^ v_mixup[ 90] ^ v_mixup[ 96] ^ v_mixin[(i + 108) % 128];
            v_res[ 35] = v_mixup[ 35] ^ (v_mixup[ 82] & ~v_mixup[ 96]) ^ v_mixup[ 91] ^ v_mixup[ 97] ^ v_mixin[(i +  85) % 128];
            v_res[ 36] = v_mixup[ 36] ^ (v_mixup[ 83] & ~v_mixup[ 97]) ^ v_mixup[ 92] ^ v_mixup[ 98] ^ v_mixin[(i +  80) % 128];
            v_res[ 37] = v_mixup[ 37] ^ (v_mixup[ 84] & ~v_mixup[ 98]) ^ v_mixup[ 93] ^ v_mixup[ 99] ^ v_mixin[(i +  37) % 128];
            v_res[ 38] = v_mixup[ 38] ^ (v_mixup[ 85] & ~v_mixup[ 99]) ^ v_mixup[ 94] ^ v_mixup[100] ^ v_mixin[(i +  35) % 128];
            v_res[ 39] = v_mixup[ 39] ^ (v_mixup[ 86] & ~v_mixup[100]) ^ v_mixup[ 95] ^ v_mixup[101] ^ v_mixin[(i +  13) % 128];
            v_res[ 40] = v_mixup[ 40] ^ (v_mixup[ 87] & ~v_mixup[101]) ^ v_mixup[ 96] ^ v_mixup[102] ^ v_mixin[(i +  30) % 128];
            v_res[ 41] = v_mixup[ 41] ^ (v_mixup[ 88] & ~v_mixup[102]) ^ v_mixup[ 97] ^ v_mixup[103] ^ v_mixin[(i +  87) % 128];
            v_res[ 42] = v_mixup[ 42] ^ (v_mixup[ 89] & ~v_mixup[103]) ^ v_mixup[ 98] ^ v_mixup[104] ^ v_mixin[(i +  79) % 128];
            v_res[ 43] = v_mixup[ 43] ^ (v_mixup[ 90] & ~v_mixup[104]) ^ v_mixup[ 99] ^ v_mixup[105] ^ v_mixin[(i +  61) % 128];
            v_res[ 44] = v_mixup[ 44] ^ (v_mixup[ 91] & ~v_mixup[105]) ^ v_mixup[100] ^ v_mixup[106] ^ v_mixin[(i +   4) % 128];
            v_res[ 45] = v_mixup[ 45] ^ (v_mixup[ 92] & ~v_mixup[106]) ^ v_mixup[101] ^ v_mixup[107] ^ v_mixin[(i + 109) % 128];
            v_res[ 46] = v_mixup[ 46] ^ (v_mixup[ 93] & ~v_mixup[107]) ^ v_mixup[102] ^ v_mixup[108] ^ v_mixin[(i + 111) % 128];
            v_res[ 47] = v_mixup[ 47] ^ (v_mixup[ 94] & ~v_mixup[108]) ^ v_mixup[103] ^ v_mixup[109] ^ v_mixin[(i +  43) % 128];
            v_res[ 48] = v_mixup[ 48] ^ (v_mixup[ 95] & ~v_mixup[109]) ^ v_mixup[104] ^ v_mixup[110] ^ v_mixin[(i +  67) % 128];
            v_res[ 49] = v_mixup[ 49] ^ (v_mixup[ 96] & ~v_mixup[110]) ^ v_mixup[105] ^ v_mixup[111] ^ v_mixin[(i +  55) % 128];
            v_res[ 50] = v_mixup[ 50] ^ (v_mixup[ 97] & ~v_mixup[111]) ^ v_mixup[106] ^ v_mixup[112] ^ v_mixin[(i +  23) % 128];
            v_res[ 51] = v_mixup[ 51] ^ (v_mixup[ 98] & ~v_mixup[112]) ^ v_mixup[107] ^ v_mixup[113] ^ v_mixin[(i +  12) % 128];
            v_res[ 52] = v_mixup[ 52] ^ (v_mixup[ 99] & ~v_mixup[113]) ^ v_mixup[108] ^ v_mixup[114] ^ v_mixin[(i +  74) % 128];
            v_res[ 53] = v_mixup[ 53] ^ (v_mixup[100] & ~v_mixup[114]) ^ v_mixup[109] ^ v_mixup[115] ^ v_mixin[(i +  47) % 128];
            v_res[ 54] = v_mixup[ 54] ^ (v_mixup[101] & ~v_mixup[115]) ^ v_mixup[110] ^ v_mixup[116] ^ v_mixin[(i + 105) % 128];
            v_res[ 55] = v_mixup[ 55] ^ (v_mixup[102] & ~v_mixup[116]) ^ v_mixup[111] ^ v_mixup[117] ^ v_mixin[(i +  90) % 128];
            v_res[ 56] = v_mixup[ 56] ^ (v_mixup[103] & ~v_mixup[117]) ^ v_mixup[112] ^ v_mixup[118] ^ v_mixin[(i +  94) % 128];
            v_res[ 57] = v_mixup[ 57] ^ (v_mixup[104] & ~v_mixup[118]) ^ v_mixup[113] ^ v_mixup[119] ^ v_mixin[(i +  71) % 128];
            v_res[ 58] = v_mixup[ 58] ^ (v_mixup[105] & ~v_mixup[119]) ^ v_mixup[114] ^ v_mixup[120] ^ v_mixin[(i + 122) % 128];
            v_res[ 59] = v_mixup[ 59] ^ (v_mixup[106] & ~v_mixup[120]) ^ v_mixup[115] ^ v_mixup[121] ^ v_mixin[(i +  57) % 128];
            v_res[ 60] = v_mixup[ 60] ^ (v_mixup[107] & ~v_mixup[121]) ^ v_mixup[116] ^ v_mixup[122] ^ v_mixin[(i +  31) % 128];
            v_res[ 61] = v_mixup[ 61] ^ (v_mixup[108] & ~v_mixup[122]) ^ v_mixup[117] ^ v_mixup[123] ^ v_mixin[(i +  88) % 128];
            v_res[ 62] = v_mixup[ 62] ^ (v_mixup[109] & ~v_mixup[123]) ^ v_mixup[118] ^ v_mixup[124] ^ v_mixin[(i +   5) % 128];
            v_res[ 63] = v_mixup[ 63] ^ (v_mixup[110] & ~v_mixup[124]) ^ v_mixup[119] ^ v_mixup[125] ^ v_mixin[(i +  38) % 128];
            v_state_y2[128 * i +: 128] = {v_res, v_state_y1[128 * i + 64 +: 64]};
        end
        
    end
    
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            
            r_state_x <= seed_x;
            r_state_y <= seed_y;
            
        end else if (enable == 1'b1) begin
            
            r_state_x[  0] <= r_state_x[ 93] ^ r_state_x[ 67] ^ r_state_x[ 22] ^ r_state_x[113] ^ r_state_x[ 35];
            r_state_x[  1] <= r_state_x[ 38] ^ r_state_x[ 84] ^ r_state_x[ 91] ^ r_state_x[ 47] ^ r_state_x[ 95] ^ r_state_x[124];
            r_state_x[  2] <= r_state_x[114] ^ r_state_x[ 68] ^ r_state_x[ 23] ^ r_state_x[  3] ^ r_state_x[ 17];
            r_state_x[  3] <= r_state_x[ 50] ^ r_state_x[ 29] ^ r_state_x[127] ^ r_state_x[ 54] ^ r_state_x[ 20] ^ r_state_x[ 39];
            r_state_x[  4] <= r_state_x[ 69] ^ r_state_x[ 19] ^ r_state_x[  1] ^ r_state_x[  7] ^ r_state_x[108];
            r_state_x[  5] <= r_state_x[ 77] ^ r_state_x[ 69] ^ r_state_x[ 43] ^ r_state_x[ 87] ^ r_state_x[ 28] ^ r_state_x[121];
            r_state_x[  6] <= r_state_x[103] ^ r_state_x[ 62] ^ r_state_x[ 50] ^ r_state_x[ 96] ^ r_state_x[118];
            r_state_x[  7] <= r_state_x[  6] ^ r_state_x[ 49] ^ r_state_x[125] ^ r_state_x[ 63] ^ r_state_x[ 46] ^ r_state_x[ 87];
            r_state_x[  8] <= r_state_x[ 92] ^ r_state_x[  5] ^ r_state_x[ 45] ^ r_state_x[  3] ^ r_state_x[ 95];
            r_state_x[  9] <= r_state_x[ 55] ^ r_state_x[ 37] ^ r_state_x[ 10] ^ r_state_x[101] ^ r_state_x[107] ^ r_state_x[ 84];
            r_state_x[ 10] <= r_state_x[ 21] ^ r_state_x[ 32] ^ r_state_x[ 46] ^ r_state_x[ 19] ^ r_state_x[113];
            r_state_x[ 11] <= r_state_x[116] ^ r_state_x[ 34] ^ r_state_x[  8] ^ r_state_x[ 41] ^ r_state_x[ 47] ^ r_state_x[ 93];
            r_state_x[ 12] <= r_state_x[ 37] ^ r_state_x[125] ^ r_state_x[ 38] ^ r_state_x[102] ^ r_state_x[ 40];
            r_state_x[ 13] <= r_state_x[ 72] ^ r_state_x[ 89] ^ r_state_x[127] ^ r_state_x[ 31] ^ r_state_x[113] ^ r_state_x[ 51];
            r_state_x[ 14] <= r_state_x[ 87] ^ r_state_x[  6] ^ r_state_x[ 59] ^ r_state_x[  3] ^ r_state_x[  9];
            r_state_x[ 15] <= r_state_x[ 66] ^ r_state_x[  5] ^ r_state_x[ 52] ^ r_state_x[ 18] ^ r_state_x[ 56] ^ r_state_x[ 75];
            r_state_x[ 16] <= r_state_x[ 28] ^ r_state_x[ 33] ^ r_state_x[ 14] ^ r_state_x[ 27] ^ r_state_x[ 98];
            r_state_x[ 17] <= r_state_x[  7] ^ r_state_x[ 72] ^ r_state_x[  9] ^ r_state_x[  2] ^ r_state_x[ 30] ^ r_state_x[ 29];
            r_state_x[ 18] <= r_state_x[106] ^ r_state_x[110] ^ r_state_x[ 40] ^ r_state_x[ 98] ^ r_state_x[ 42];
            r_state_x[ 19] <= r_state_x[100] ^ r_state_x[ 60] ^ r_state_x[ 30] ^ r_state_x[105] ^ r_state_x[ 28] ^ r_state_x[ 50];
            r_state_x[ 20] <= r_state_x[ 63] ^ r_state_x[  5] ^ r_state_x[ 51] ^ r_state_x[ 41] ^ r_state_x[ 57];
            r_state_x[ 21] <= r_state_x[108] ^ r_state_x[ 12] ^ r_state_x[ 14] ^ r_state_x[ 35] ^ r_state_x[ 36] ^ r_state_x[ 96];
            r_state_x[ 22] <= r_state_x[ 56] ^ r_state_x[ 73] ^ r_state_x[ 62] ^ r_state_x[ 86] ^ r_state_x[ 26];
            r_state_x[ 23] <= r_state_x[ 58] ^ r_state_x[ 91] ^ r_state_x[119] ^ r_state_x[ 44] ^ r_state_x[ 65] ^ r_state_x[ 89];
            r_state_x[ 24] <= r_state_x[ 34] ^ r_state_x[123] ^ r_state_x[100] ^ r_state_x[111] ^ r_state_x[ 59];
            r_state_x[ 25] <= r_state_x[124] ^ r_state_x[119] ^ r_state_x[ 72] ^ r_state_x[ 61] ^ r_state_x[ 19] ^ r_state_x[ 63];
            r_state_x[ 26] <= r_state_x[  5] ^ r_state_x[ 78] ^ r_state_x[114] ^ r_state_x[ 27] ^ r_state_x[ 55];
            r_state_x[ 27] <= r_state_x[ 41] ^ r_state_x[ 32] ^ r_state_x[ 54] ^ r_state_x[ 52] ^ r_state_x[ 67] ^ r_state_x[ 11];
            r_state_x[ 28] <= r_state_x[ 33] ^ r_state_x[ 89] ^ r_state_x[  7] ^ r_state_x[ 14] ^ r_state_x[ 71];
            r_state_x[ 29] <= r_state_x[109] ^ r_state_x[ 17] ^ r_state_x[ 80] ^ r_state_x[ 94] ^ r_state_x[ 54] ^ r_state_x[ 11];
            r_state_x[ 30] <= r_state_x[117] ^ r_state_x[ 29] ^ r_state_x[ 30] ^ r_state_x[ 33] ^ r_state_x[  0];
            r_state_x[ 31] <= r_state_x[ 31] ^ r_state_x[ 85] ^ r_state_x[127] ^ r_state_x[102] ^ r_state_x[ 96] ^ r_state_x[ 95];
            r_state_x[ 32] <= r_state_x[ 80] ^ r_state_x[ 42] ^ r_state_x[ 82] ^ r_state_x[101] ^ r_state_x[ 68];
            r_state_x[ 33] <= r_state_x[ 55] ^ r_state_x[ 85] ^ r_state_x[ 80] ^ r_state_x[ 95] ^ r_state_x[105] ^ r_state_x[ 70];
            r_state_x[ 34] <= r_state_x[122] ^ r_state_x[116] ^ r_state_x[ 88] ^ r_state_x[ 41] ^ r_state_x[ 22];
            r_state_x[ 35] <= r_state_x[ 97] ^ r_state_x[116] ^ r_state_x[ 36] ^ r_state_x[ 83] ^ r_state_x[ 82] ^ r_state_x[123];
            r_state_x[ 36] <= r_state_x[ 21] ^ r_state_x[ 82] ^ r_state_x[ 54] ^ r_state_x[111] ^ r_state_x[101];
            r_state_x[ 37] <= r_state_x[ 99] ^ r_state_x[ 76] ^ r_state_x[  8] ^ r_state_x[ 10] ^ r_state_x[ 48] ^ r_state_x[126];
            r_state_x[ 38] <= r_state_x[  8] ^ r_state_x[ 90] ^ r_state_x[ 48] ^ r_state_x[ 56] ^ r_state_x[117];
            r_state_x[ 39] <= r_state_x[111] ^ r_state_x[120] ^ r_state_x[ 77] ^ r_state_x[ 53] ^ r_state_x[123] ^ r_state_x[ 79];
            r_state_x[ 40] <= r_state_x[104] ^ r_state_x[ 38] ^ r_state_x[108] ^ r_state_x[106] ^ r_state_x[102];
            r_state_x[ 41] <= r_state_x[ 13] ^ r_state_x[ 26] ^ r_state_x[118] ^ r_state_x[120] ^ r_state_x[ 14] ^ r_state_x[ 73];
            r_state_x[ 42] <= r_state_x[ 24] ^ r_state_x[122] ^ r_state_x[ 12] ^ r_state_x[  1] ^ r_state_x[ 65];
            r_state_x[ 43] <= r_state_x[ 18] ^ r_state_x[ 33] ^ r_state_x[ 94] ^ r_state_x[ 76] ^ r_state_x[ 64] ^ r_state_x[  4];
            r_state_x[ 44] <= r_state_x[  9] ^ r_state_x[102] ^ r_state_x[ 31] ^ r_state_x[ 24] ^ r_state_x[ 86];
            r_state_x[ 45] <= r_state_x[ 16] ^ r_state_x[ 45] ^ r_state_x[ 39] ^ r_state_x[ 31] ^ r_state_x[ 67] ^ r_state_x[108];
            r_state_x[ 46] <= r_state_x[ 33] ^ r_state_x[ 58] ^ r_state_x[  0] ^ r_state_x[ 81] ^ r_state_x[ 93];
            r_state_x[ 47] <= r_state_x[ 63] ^ r_state_x[110] ^ r_state_x[ 74] ^ r_state_x[ 56] ^ r_state_x[ 47] ^ r_state_x[ 23];
            r_state_x[ 48] <= r_state_x[ 96] ^ r_state_x[ 37] ^ r_state_x[ 32] ^ r_state_x[ 56] ^ r_state_x[ 97];
            r_state_x[ 49] <= r_state_x[ 35] ^ r_state_x[ 18] ^ r_state_x[ 93] ^ r_state_x[ 12] ^ r_state_x[105] ^ r_state_x[121];
            r_state_x[ 50] <= r_state_x[  2] ^ r_state_x[112] ^ r_state_x[117] ^ r_state_x[ 76] ^ r_state_x[ 51];
            r_state_x[ 51] <= r_state_x[  6] ^ r_state_x[106] ^ r_state_x[110] ^ r_state_x[ 68] ^ r_state_x[ 13] ^ r_state_x[ 15];
            r_state_x[ 52] <= r_state_x[ 12] ^ r_state_x[ 76] ^ r_state_x[107] ^ r_state_x[ 16] ^ r_state_x[121];
            r_state_x[ 53] <= r_state_x[124] ^ r_state_x[ 95] ^ r_state_x[ 85] ^ r_state_x[ 28] ^ r_state_x[ 13] ^ r_state_x[  6];
            r_state_x[ 54] <= r_state_x[123] ^ r_state_x[ 28] ^ r_state_x[  5] ^ r_state_x[ 61] ^ r_state_x[ 59];
            r_state_x[ 55] <= r_state_x[ 26] ^ r_state_x[ 76] ^ r_state_x[ 30] ^ r_state_x[ 99] ^ r_state_x[ 25] ^ r_state_x[ 16];
            r_state_x[ 56] <= r_state_x[ 66] ^ r_state_x[ 89] ^ r_state_x[122] ^ r_state_x[ 79] ^ r_state_x[103];
            r_state_x[ 57] <= r_state_x[107] ^ r_state_x[ 15] ^ r_state_x[ 29] ^ r_state_x[ 34] ^ r_state_x[ 83] ^ r_state_x[116];
            r_state_x[ 58] <= r_state_x[ 16] ^ r_state_x[ 53] ^ r_state_x[107] ^ r_state_x[ 98] ^ r_state_x[ 37];
            r_state_x[ 59] <= r_state_x[ 49] ^ r_state_x[104] ^ r_state_x[ 94] ^ r_state_x[109] ^ r_state_x[112] ^ r_state_x[ 79];
            r_state_x[ 60] <= r_state_x[ 12] ^ r_state_x[ 57] ^ r_state_x[ 61] ^ r_state_x[ 70] ^ r_state_x[ 20];
            r_state_x[ 61] <= r_state_x[ 29] ^ r_state_x[ 97] ^ r_state_x[ 71] ^ r_state_x[ 78] ^ r_state_x[ 53] ^ r_state_x[ 74];
            r_state_x[ 62] <= r_state_x[ 16] ^ r_state_x[108] ^ r_state_x[111] ^ r_state_x[ 90] ^ r_state_x[  1];
            r_state_x[ 63] <= r_state_x[ 59] ^ r_state_x[ 91] ^ r_state_x[114] ^ r_state_x[122] ^ r_state_x[ 50] ^ r_state_x[ 99];
            r_state_x[ 64] <= r_state_x[113] ^ r_state_x[125] ^ r_state_x[ 26] ^ r_state_x[ 57] ^ r_state_x[ 51];
            r_state_x[ 65] <= r_state_x[100] ^ r_state_x[ 85] ^ r_state_x[114] ^ r_state_x[ 86] ^ r_state_x[106] ^ r_state_x[121];
            r_state_x[ 66] <= r_state_x[ 81] ^ r_state_x[ 21] ^ r_state_x[ 42] ^ r_state_x[  9] ^ r_state_x[ 15];
            r_state_x[ 67] <= r_state_x[ 63] ^ r_state_x[127] ^ r_state_x[ 45] ^ r_state_x[ 18] ^ r_state_x[ 13] ^ r_state_x[ 74];
            r_state_x[ 68] <= r_state_x[ 53] ^ r_state_x[ 55] ^ r_state_x[  2] ^ r_state_x[ 46] ^ r_state_x[ 84];
            r_state_x[ 69] <= r_state_x[ 29] ^ r_state_x[ 67] ^ r_state_x[ 62] ^ r_state_x[125] ^ r_state_x[127] ^ r_state_x[ 84];
            r_state_x[ 70] <= r_state_x[  8] ^ r_state_x[ 55] ^ r_state_x[ 78] ^ r_state_x[ 53] ^ r_state_x[ 41];
            r_state_x[ 71] <= r_state_x[ 11] ^ r_state_x[ 81] ^ r_state_x[ 37] ^ r_state_x[125] ^ r_state_x[ 32] ^ r_state_x[ 61];
            r_state_x[ 72] <= r_state_x[ 94] ^ r_state_x[ 82] ^ r_state_x[ 91] ^ r_state_x[ 58] ^ r_state_x[ 46];
            r_state_x[ 73] <= r_state_x[ 43] ^ r_state_x[ 15] ^ r_state_x[119] ^ r_state_x[ 47] ^ r_state_x[ 87] ^ r_state_x[ 62];
            r_state_x[ 74] <= r_state_x[126] ^ r_state_x[ 85] ^ r_state_x[ 82] ^ r_state_x[ 93] ^ r_state_x[ 90];
            r_state_x[ 75] <= r_state_x[ 15] ^ r_state_x[ 99] ^ r_state_x[ 59] ^ r_state_x[  4] ^ r_state_x[ 65] ^ r_state_x[  0];
            r_state_x[ 76] <= r_state_x[ 64] ^ r_state_x[ 17] ^ r_state_x[ 12] ^ r_state_x[ 10] ^ r_state_x[120];
            r_state_x[ 77] <= r_state_x[  1] ^ r_state_x[ 31] ^ r_state_x[115] ^ r_state_x[ 45] ^ r_state_x[ 43] ^ r_state_x[ 64];
            r_state_x[ 78] <= r_state_x[123] ^ r_state_x[ 24] ^ r_state_x[  7] ^ r_state_x[ 66] ^ r_state_x[ 73];
            r_state_x[ 79] <= r_state_x[103] ^ r_state_x[ 39] ^ r_state_x[ 54] ^ r_state_x[ 59] ^ r_state_x[ 74] ^ r_state_x[ 78];
            r_state_x[ 80] <= r_state_x[ 53] ^ r_state_x[ 12] ^ r_state_x[ 57] ^ r_state_x[100] ^ r_state_x[115];
            r_state_x[ 81] <= r_state_x[107] ^ r_state_x[ 39] ^ r_state_x[ 80] ^ r_state_x[ 75] ^ r_state_x[ 94] ^ r_state_x[ 49];
            r_state_x[ 82] <= r_state_x[ 25] ^ r_state_x[  1] ^ r_state_x[ 88] ^ r_state_x[124] ^ r_state_x[ 58];
            r_state_x[ 83] <= r_state_x[ 75] ^ r_state_x[103] ^ r_state_x[ 86] ^ r_state_x[ 79] ^ r_state_x[ 88] ^ r_state_x[ 28];
            r_state_x[ 84] <= r_state_x[ 19] ^ r_state_x[ 40] ^ r_state_x[ 88] ^ r_state_x[ 24] ^ r_state_x[118];
            r_state_x[ 85] <= r_state_x[ 83] ^ r_state_x[ 77] ^ r_state_x[ 97] ^ r_state_x[ 50] ^ r_state_x[ 10] ^ r_state_x[118];
            r_state_x[ 86] <= r_state_x[126] ^ r_state_x[112] ^ r_state_x[ 64] ^ r_state_x[107] ^ r_state_x[ 88];
            r_state_x[ 87] <= r_state_x[ 83] ^ r_state_x[ 25] ^ r_state_x[ 40] ^ r_state_x[ 20] ^ r_state_x[  2] ^ r_state_x[ 75];
            r_state_x[ 88] <= r_state_x[ 32] ^ r_state_x[ 37] ^ r_state_x[111] ^ r_state_x[ 51] ^ r_state_x[ 99];
            r_state_x[ 89] <= r_state_x[ 11] ^ r_state_x[120] ^ r_state_x[ 18] ^ r_state_x[ 84] ^ r_state_x[ 26] ^ r_state_x[ 52];
            r_state_x[ 90] <= r_state_x[123] ^ r_state_x[101] ^ r_state_x[ 66] ^ r_state_x[ 68] ^ r_state_x[  1];
            r_state_x[ 91] <= r_state_x[  8] ^ r_state_x[ 68] ^ r_state_x[123] ^ r_state_x[116] ^ r_state_x[ 23] ^ r_state_x[122];
            r_state_x[ 92] <= r_state_x[ 56] ^ r_state_x[ 31] ^ r_state_x[ 78] ^ r_state_x[ 36] ^ r_state_x[ 42];
            r_state_x[ 93] <= r_state_x[ 38] ^ r_state_x[ 40] ^ r_state_x[ 89] ^ r_state_x[  4] ^ r_state_x[111] ^ r_state_x[ 73];
            r_state_x[ 94] <= r_state_x[ 63] ^ r_state_x[118] ^ r_state_x[109] ^ r_state_x[ 46] ^ r_state_x[ 44];
            r_state_x[ 95] <= r_state_x[ 92] ^ r_state_x[ 53] ^ r_state_x[110] ^ r_state_x[ 52] ^ r_state_x[119] ^ r_state_x[ 40];
            r_state_x[ 96] <= r_state_x[ 69] ^ r_state_x[  2] ^ r_state_x[ 72] ^ r_state_x[  3] ^ r_state_x[120];
            r_state_x[ 97] <= r_state_x[ 43] ^ r_state_x[ 17] ^ r_state_x[ 14] ^ r_state_x[106] ^ r_state_x[122] ^ r_state_x[ 69];
            r_state_x[ 98] <= r_state_x[ 70] ^ r_state_x[ 41] ^ r_state_x[ 60] ^ r_state_x[ 51] ^ r_state_x[ 13];
            r_state_x[ 99] <= r_state_x[ 18] ^ r_state_x[ 74] ^ r_state_x[ 75] ^ r_state_x[100] ^ r_state_x[ 61] ^ r_state_x[ 60];
            r_state_x[100] <= r_state_x[115] ^ r_state_x[ 38] ^ r_state_x[ 92] ^ r_state_x[ 65] ^ r_state_x[  4];
            r_state_x[101] <= r_state_x[ 75] ^ r_state_x[ 34] ^ r_state_x[ 44] ^ r_state_x[ 72] ^ r_state_x[ 79] ^ r_state_x[ 63];
            r_state_x[102] <= r_state_x[ 57] ^ r_state_x[  2] ^ r_state_x[ 20] ^ r_state_x[ 79] ^ r_state_x[ 27];
            r_state_x[103] <= r_state_x[ 45] ^ r_state_x[ 35] ^ r_state_x[109] ^ r_state_x[ 49] ^ r_state_x[ 39] ^ r_state_x[ 96];
            r_state_x[104] <= r_state_x[ 20] ^ r_state_x[ 90] ^ r_state_x[103] ^ r_state_x[ 60] ^ r_state_x[117];
            r_state_x[105] <= r_state_x[  6] ^ r_state_x[  3] ^ r_state_x[ 79] ^ r_state_x[115] ^ r_state_x[  8] ^ r_state_x[ 81];
            r_state_x[106] <= r_state_x[102] ^ r_state_x[ 36] ^ r_state_x[ 83] ^ r_state_x[112] ^ r_state_x[ 71];
            r_state_x[107] <= r_state_x[ 42] ^ r_state_x[126] ^ r_state_x[ 62] ^ r_state_x[113] ^ r_state_x[ 43] ^ r_state_x[ 30];
            r_state_x[108] <= r_state_x[ 50] ^ r_state_x[ 69] ^ r_state_x[ 35] ^ r_state_x[ 47] ^ r_state_x[113];
            r_state_x[109] <= r_state_x[104] ^ r_state_x[ 23] ^ r_state_x[ 65] ^ r_state_x[ 77] ^ r_state_x[ 67] ^ r_state_x[117];
            r_state_x[110] <= r_state_x[ 44] ^ r_state_x[ 68] ^ r_state_x[  0] ^ r_state_x[ 80] ^ r_state_x[ 19];
            r_state_x[111] <= r_state_x[ 20] ^ r_state_x[ 27] ^ r_state_x[114] ^ r_state_x[105] ^ r_state_x[101] ^ r_state_x[ 66];
            r_state_x[112] <= r_state_x[ 43] ^ r_state_x[119] ^ r_state_x[116] ^ r_state_x[109] ^ r_state_x[ 21];
            r_state_x[113] <= r_state_x[116] ^ r_state_x[ 70] ^ r_state_x[  0] ^ r_state_x[105] ^ r_state_x[ 71] ^ r_state_x[  4];
            r_state_x[114] <= r_state_x[ 72] ^ r_state_x[ 22] ^ r_state_x[115] ^ r_state_x[ 43] ^ r_state_x[ 34];
            r_state_x[115] <= r_state_x[ 91] ^ r_state_x[ 21] ^ r_state_x[ 45] ^ r_state_x[104] ^ r_state_x[ 74] ^ r_state_x[105];
            r_state_x[116] <= r_state_x[ 58] ^ r_state_x[103] ^ r_state_x[ 30] ^ r_state_x[ 13] ^ r_state_x[108];
            r_state_x[117] <= r_state_x[  5] ^ r_state_x[ 97] ^ r_state_x[ 71] ^ r_state_x[  0] ^ r_state_x[ 47] ^ r_state_x[  9];
            r_state_x[118] <= r_state_x[ 22] ^ r_state_x[ 35] ^ r_state_x[124] ^ r_state_x[126] ^ r_state_x[120];
            r_state_x[119] <= r_state_x[ 52] ^ r_state_x[ 66] ^ r_state_x[106] ^ r_state_x[ 11] ^ r_state_x[104] ^ r_state_x[ 17];
            r_state_x[120] <= r_state_x[ 38] ^ r_state_x[ 64] ^ r_state_x[  7] ^ r_state_x[102] ^ r_state_x[ 24];
            r_state_x[121] <= r_state_x[ 10] ^ r_state_x[ 90] ^ r_state_x[ 25] ^ r_state_x[ 81] ^ r_state_x[ 92] ^ r_state_x[ 77];
            r_state_x[122] <= r_state_x[ 19] ^ r_state_x[ 60] ^ r_state_x[ 87] ^ r_state_x[ 92] ^ r_state_x[ 48];
            r_state_x[123] <= r_state_x[ 11] ^ r_state_x[ 95] ^ r_state_x[ 27] ^ r_state_x[ 36] ^ r_state_x[ 22] ^ r_state_x[ 98];
            r_state_x[124] <= r_state_x[  9] ^ r_state_x[ 23] ^ r_state_x[ 81] ^ r_state_x[ 44] ^ r_state_x[ 93];
            r_state_x[125] <= r_state_x[ 49] ^ r_state_x[ 73] ^ r_state_x[ 88] ^ r_state_x[ 98] ^ r_state_x[112] ^ r_state_x[121];
            r_state_x[126] <= r_state_x[ 48] ^ r_state_x[ 70] ^ r_state_x[ 86] ^ r_state_x[ 23] ^ r_state_x[ 59];
            r_state_x[127] <= r_state_x[ 97] ^ r_state_x[ 29] ^ r_state_x[ 48] ^ r_state_x[110] ^ r_state_x[ 34] ^ r_state_x[107];
            
            r_state_y <= v_state_y2;
            
        end
    end
    
endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

