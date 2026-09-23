`timescale 1ns / 1ps

module main_control(input clk,
  input rst,
  input CS1,
  input SDI1,
  input [63:0] WTA_OUT,
  input WTA_VALID,
  input [255:0] TRUE0,
  input [255:0] TRUE1,
  input [63:0] VSAB_OUT,
  input BP_MUX_SAMPLED,
  output reg BUSY,
  output reg SDO1,
  output reg TX_READY,
  output wire [63:0] WTA_SEL0,
  output wire [63:0] WTA_SEL1,
  output wire [127:0] RWLF_pre,
  output wire [255:0] RWLB_pre,
  output wire [63:0] LIT_SEL,
  output wire [15:0] BP_MUX_SEL,
  output wire [127:0] DRDN_WBLp,
  output wire [127:0] DRUPn_WBLp,
  output wire [127:0] DRDN_WBLn,
  output wire [127:0] DRUPn_WBLn,
  output wire [255:0] WWL_pre,
  output wire VSAF_EN,
  output wire VSAB_EN,
  output reg FP_PUn,
  output reg BP_PUn,
  output reg BP_MUX_READY,
  output reg WTA_EN,
  output reg RESETn);
	
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
reg wta_test_mode;
reg fp_vsa_test_mode;
reg bp_vsa_test_mode;
reg bp_wta_test_mode;
reg bp_mux_test_mode;
reg bmp_mode;
reg bbp_mode;
reg bwp_mode;
reg fp_mode;
reg prog_mode;
reg flip_mode;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////INTERMEDIATE WIRES, MODULES (DECODERS) AND REGISTERS USED DURING TEST MODES///////////////////////////////////////
wire [5:0] v_exta_address; //Encodes address of WTA input branch where V_exta is to be applied
wire [5:0] v_extb_address; //Encodes address of WTA input branch where V_extb is to be applied
wire [63:0] wta_va_decoded, wta_vb_decoded;
wire [127:0] fp_wl_test;   // 128x1 input obtained from input shift-register to be applied to RWLF_pre during FP_VSA_TEST mode
wire [255:0] bp_wl_test;
wire [63:0] lit_sel_test;
wire [63:0] bp_wta_sel_test;
wire [3:0] bp_mux_sel_decIn;

assign v_exta_address = content[9:4];
assign v_extb_address = content[15:10];
assign fp_wl_test = content[131:4];
assign bp_wl_test = content[259:4];
assign lit_sel_test = content[323:260];
assign bp_wta_sel_test = content[387:324];
assign bp_mux_sel_decIn = content[263:260];

decoder6Bit WTA_Va_Decoder (wta_test_mode,v_exta_address,wta_va_decoded);
decoder6Bit WTA_Vb_Decoder (wta_test_mode,v_extb_address,wta_vb_decoded);
decoder4Bit BP_Mux_Decoder (bp_mux_test_mode,bp_mux_sel_decIn,BP_MUX_SEL);
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
wire [12:0] p_noise;
wire [255:0] clause_mask, randClause_sel_l0;
wire unsat;
wire [63:0] variable_mask, randVar_sel_l0;
wire candVar_present, random_walk_flag;

assign max_flips = {1'b0,content[83:68]};
assign p_noise = {1'b0,content[95:84]};
assign variable_mask = content[159:96];
assign clause_mask = content[415:160];

reg [255:0] TRUE0_reg, TRUE1_reg;
reg [7:0] prngbits_randClause;
reg [5:0] prngbits_randVar;
reg [63:0] memvar_mask;
reg [63:0] shonning_chosenVar, bv0_chosenVar, wta_chosenVar;
reg [12:0] sampled_noise;
reg [63:0] candVar_reg;
reg take_random_walk, bv0_present, wta_valid_reg, restart_flag;
reg [63:0] VAR_flipped;
reg [16:0] flip_counter;

randClauseSelect randClauseSelect_UUT (TRUE0_reg,clause_mask,prngbits_randClause,randClause_sel_l0,unsat);
randVarSelect randVarSelect_UUT (candVar_reg,memvar_mask,prngbits_randVar,randVar_sel_l0,candVar_present);

assign random_walk_flag = (sampled_noise > p_noise) ? 1'b1 : 1'b0;

always @(*)
    begin
    if (flip_mode==1'b1) begin
        if (bv0_present==1'b1) begin
            VAR_flipped = VAR ^ bv0_chosenVar;
        end else if ((take_random_walk) | (~take_random_walk&~wta_valid_reg)) begin
            VAR_flipped = VAR ^ shonning_chosenVar;
        end else begin
            VAR_flipped = VAR ^ wta_chosenVar;
        end
    end else begin
        VAR_flipped = 0;
    end  
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////PRNG MODULE INSTANTIATION AND RELEVANT WIRES & REGISTERS////////////////////////////////////////
wire [31:0] seed_x, seed_y;
wire [31:0] PRNG_BITS;          //Output signals from the PRNG circuit module

assign seed_x = content[35:4];
assign seed_y = content[67:36];

reg prng_rst, prng_en;

xormix32 #(.streams(1)) prng_core (
  .clk(clk), .rst(prng_rst), .seed_x(seed_x),
  .seed_y(seed_y), .enable(prng_en),
  .result(PRNG_BITS)
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////MIXED SIGNAL CORE SIGNAL GENERATION////////////////////////////////////////

assign VSAF_EN = clk_p & (fp_vsa_test_mode | fp_mode);
assign VSAB_EN = clk_p & (bp_vsa_test_mode | bbp_mode | bmp_mode);

genvar i;
for (i=0; i<64; i=i+1) begin  : WTA_SEL0_logic
    assign WTA_SEL0[i] = (wta_va_decoded[i] & wta_test_mode) | (bp_wta_sel_test[i] & bp_wta_test_mode) | (bwp_mode & memvar_mask[i]);                          
    assign WTA_SEL1[i] = (wta_vb_decoded[i] & wta_test_mode) | (bp_wta_sel_test[i] & bp_wta_test_mode) | (bwp_mode & memvar_mask[i]);
    assign LIT_SEL[i] = ((bp_vsa_test_mode | bp_wta_test_mode) & lit_sel_test[i]) | (bmp_mode & VAR[i]) | ((bbp_mode | bwp_mode) & ~VAR[i]);
    assign LIT[2*i] = variable_mask[i] & VAR[i];
    assign LIT[2*i+1] = variable_mask[i] & ~VAR[i];
end

genvar n;
for (n=0; n<128; n=n+1) begin  : FP_WLn_logic
    assign RWLF_pre[n] = (fp_mode & LIT[n]) | (fp_wl_test[n] & fp_vsa_test_mode);
    assign DRDN_WBLp[n] = prog_bl_en & ~prog_bl_p[n];
	assign DRUPn_WBLp[n] = prog_bl_en & ~prog_bl_p[n] | ~prog_bl_en;
	assign DRDN_WBLn[n] = prog_bl_en & prog_bl_p[n];
	assign DRUPn_WBLn[n] = prog_bl_en & prog_bl_p[n] | ~prog_bl_en;
end

genvar m;
for (m=0; m<256; m=m+1) begin  : BP_WLm_logic
    assign RWLB_pre[m] = (bmp_mode & S[m]) | ((bbp_mode | bwp_mode) & Z[m]) | (bp_wl_test[m] & (bp_vsa_test_mode | bp_wta_test_mode | bp_mux_test_mode));
    assign WWL_pre[m] = prog_wl_decOut[m] & prog_wl_en;      
    assign S[m] = TRUE0_reg[m] & randClause_sel_l0[m];
    assign Z[m] = ~TRUE0_reg[m] & TRUE1_reg[m] & clause_mask[m];     
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



///////////////////////////////////////////////////////////////////////////////////FSM STATE ENCODINGS & REGISTER/////////////////////////////////////////////////////////////////////////////////////////////////
parameter size = 5;
parameter s_IDLE = 5'b00000, s_DIN_DECODE = 5'b00001, s_WTA_TEST1 = 5'b00010, s_WTA_TEST2 = 5'b00011, s_DOUT = 5'b00100, s_FP_VSA_TEST1 = 5'b00101, s_FP_VSA_TEST2 = 5'b00110, s_BP_VSA_TEST1 = 5'b00111, s_BP_VSA_TEST2 = 5'b01000, s_BP_WTA_TEST1 = 5'b01001, s_BP_WTA_TEST2 = 5'b01010, s_BP_WTA_TEST3 = 5'b01011, s_BP_MUX_TEST1 = 5'b01100, s_BP_MUX_TEST2 = 5'b01101;
parameter s_PROG_BL1 = 5'b01110, s_PROG_WL = 5'b01111, s_PROG_BL2 = 5'b10000, s_SOLVE_FP = 5'b10001, s_SOLVE_RC = 5'b10010, s_SOLVE_BMP = 5'b10011, s_SOLVE_BBP = 5'b10100, s_SOLVE_BWP = 5'b10101, s_SOLVE_FLIP = 5'b10110, s_PRNG_TEST = 5'b10111;
reg [size-1:0] state; //FSM state register
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////MAIN FSM/////////////////////////////////////////////////////////////////////////////////////////////////
    
    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            BUSY <= 1'b0;
            SDO1 <= 1'b0;
            state <= s_IDLE;
            WTA_EN <= 1'b0;
            content <= 0;
            RESETn <= 1'b0;
            r_Bit_Index <= 255;
            TX_READY <= 1'b0;
            content_out <= 0;
            fp_vsa_test_mode <= 1'b0;
            bp_vsa_test_mode <= 1'b0;
            fp_mode <= 1'b0;
            bbp_mode <= 1'b0;
            bwp_mode <= 1'b0;
            bmp_mode <= 1'b0;
            wta_test_mode <= 1'b0;
            bp_wta_test_mode <= 1'b0;
            bp_mux_test_mode <= 1'b0;
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
            prngbits_randClause <= 0;
            prngbits_randVar <= 0;
            memvar_mask <= 0;
            flip_mode <= 1'b0;
            restart_flag <= 1'b1;
            flip_counter <= 0;
            TRUE0_reg <= 0;
            TRUE1_reg <= 0;
            wta_valid_reg <= 1'b0;
            bv0_present <= 1'b0;
            take_random_walk <= 1'b0;
            wta_chosenVar <= 0;
            bv0_chosenVar <= 0;
            shonning_chosenVar <= 0;
            candVar_reg <= 0;
            sampled_noise <= 0;
            prng_rst <= 1'b0;
            prng_en <= 1'b0;
        end else begin
            case(state)
                s_IDLE: begin
                        fp_vsa_test_mode <= 1'b0;
                        bp_vsa_test_mode <= 1'b0;
                        fp_mode <= 1'b0;
                        bmp_mode <= 1'b0;
                        bbp_mode <= 1'b0;
                        bwp_mode <= 1'b0;
                        bp_wta_test_mode <= 1'b0;
                        wta_test_mode <= 1'b0;
                        FP_PUn <= 1'b1;
                        WTA_EN <= 1'b0;
                        RESETn <= 1'b0;
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
                        prngbits_randClause <= 0;
                        prngbits_randVar <= 0;
                        memvar_mask <= 0;
                        restart_flag <= 1'b1;
                        flip_mode <= 1'b0;
                        flip_counter <= 0;
                        TRUE0_reg <= 0;
                        TRUE1_reg <= 0;
                        wta_valid_reg <= 1'b0;
                        bv0_present <= 1'b0;
                        take_random_walk <= 1'b0;
                        wta_chosenVar <= 0;
                        bv0_chosenVar <= 0;
                        shonning_chosenVar <= 0;
                        candVar_reg <= 0;
                        sampled_noise <= 0;
                        prng_rst <= 1'b0;
                        prng_en <= 1'b0;
                        content_out <= 0;
                        if (CS1 == 1'b0) begin
                            BUSY <= 1'b1;
                            SDO1 <= 1'b0;
                            content <= {content[INPUT_SR_WIDTH-2:0],SDI1};
                            state <= s_DIN_DECODE;
                        end else begin
                            BUSY <= 1'b0;
                            SDO1 <= 1'b0;
                            content <= content;
                            state <= s_IDLE;
                        end
                    end
                s_DIN_DECODE: begin
                        prog_bl_en <= 1'b0;
                        prog_wl_en <= 1'b0;
                        prog_bl_wait_counter <= 1'b0;
                        prog_wl_wait_counter <= 1'b0;
                        prog_postwl_wait_counter <= 1'b0;
                        VAR <= content[67:4];
                        restart_flag <= 1'b1;
                        if (CS1 == 1'b0) begin
                            content <= {content[INPUT_SR_WIDTH-2:0],SDI1};
                            state <= s_DIN_DECODE;
                            wta_test_mode <= 1'b0;
                            prog_mode <= 1'b0;
                            FP_PUn <= 1'b1;
                            BP_PUn <= 1'b1;
                            prng_rst <= 1'b0;
                            prng_en <= 1'b0;
                        end else begin
                            content <= content;
                            if (content[3:0]==4'b0000) begin
                                state <= s_WTA_TEST1;
                                wta_test_mode <= 1'b1;
                                prog_mode <= 1'b0;
                                FP_PUn <= 1'b1;
                                BP_PUn <= 1'b1;
                                prng_rst <= 1'b0;
                                prng_en <= 1'b0;
                            end else if (content[3:0]==4'b0001) begin
                                state <= s_FP_VSA_TEST1;
                                wta_test_mode <= 1'b0;
                                prog_mode <= 1'b0;
                                FP_PUn <= 1'b0;
                                BP_PUn <= 1'b1;
                                prng_rst <= 1'b0;
                                prng_en <= 1'b0;
                            end else if (content[3:0]==4'b0010) begin
                                state <= s_BP_VSA_TEST1;
                                wta_test_mode <= 1'b0;
                                prog_mode <= 1'b0;
                                FP_PUn <= 1'b1;
                                BP_PUn <= 1'b0;
                                prng_rst <= 1'b0;
                                prng_en <= 1'b0;
                            end else if (content[3:0]==4'b0011) begin
                                state <= s_BP_WTA_TEST1;
                                wta_test_mode <= 1'b0;
                                prog_mode <= 1'b0;
                                FP_PUn <= 1'b1;
                                BP_PUn <= 1'b0;
                                prng_rst <= 1'b0;
                                prng_en <= 1'b0;
                            end else if (content[3:0]==4'b0100) begin
                                state <= s_BP_MUX_TEST1;
                                wta_test_mode <= 1'b0;
                                prog_mode <= 1'b0;
                                FP_PUn <= 1'b1;
                                BP_PUn <= 1'b0;
                                prng_rst <= 1'b0;
                                prng_en <= 1'b0;
                            end else if (content[3:0]==4'b0101) begin
                                state <= s_PROG_BL1;
                                wta_test_mode <= 1'b0;
                                prog_mode <= 1'b1;
                                FP_PUn <= 1'b1;
                                BP_PUn <= 1'b1;
                                prng_rst <= 1'b0;
                                prng_en <= 1'b0;
                            end else if (content[3:0]==4'b0110) begin
                                state <= s_SOLVE_FP;
                                wta_test_mode <= 1'b0;
                                prog_mode <= 1'b0;
                                FP_PUn <= 1'b0;
                                BP_PUn <= 1'b1;
                                prng_rst <= 1'b0;
                                prng_en <= 1'b1;
                            end else if (content[3:0]==4'b0111) begin
                                state <= s_IDLE;
                                wta_test_mode <= 1'b0;
                                prog_mode <= 1'b0;
                                FP_PUn <= 1'b1;
                                BP_PUn <= 1'b1;
                                prng_rst <= 1'b1;
                                prng_en <= 1'b0;
                            end else if (content[3:0]==4'b1000) begin
                                state <= s_PRNG_TEST;
                                wta_test_mode <= 1'b0;
                                prog_mode <= 1'b0;
                                FP_PUn <= 1'b1;
                                BP_PUn <= 1'b1;
                                prng_rst <= 1'b0;
                                prng_en <= 1'b1;
                            end else begin
                                state <= s_IDLE;
                                wta_test_mode <= 1'b0;
                                prog_mode <= 1'b0;
                                FP_PUn <= 1'b1;
                                BP_PUn <= 1'b1;
                                prng_rst <= 1'b0;
                                prng_en <= 1'b0;
                            end
                        end
                    end
                s_WTA_TEST1: begin
                        content <= content;
                        wta_test_mode <= 1'b1;
                        WTA_EN <= 1'b1;
                        RESETn <= 1'b1;
                        state <= s_WTA_TEST2;
                    end
                s_WTA_TEST2: begin
                        content <= content;
                        wta_test_mode <= 1'b1;
                        WTA_EN <= 1'b0;
                        RESETn <= 1'b0;
                        content_out <= {content_out[255:65],WTA_VALID,WTA_OUT};
                        state <= s_DOUT;
                    end
                s_DOUT: begin
                        content <= content;
                        wta_test_mode <= 1'b0;
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
                        state <= s_BP_VSA_TEST2;
                    end
                 s_BP_VSA_TEST2: begin
                        content <= content;
                        bp_vsa_test_mode <= 1'b0;
                        BP_PUn <= 1'b1;
                        state <= s_DOUT;
                        content_out[255:0] <= {content_out[255:64],VSAB_OUT[63:0]};
                    end
                s_BP_WTA_TEST1: begin
                        content <= content;
                        bp_wta_test_mode <= 1'b1;
                        BP_PUn <= 1'b0;
                        state <= s_BP_WTA_TEST2;
                    end
                s_BP_WTA_TEST2: begin
                        content <= content;
                        bp_wta_test_mode <= 1'b1;
                        BP_PUn <= 1'b0;
                        WTA_EN <= 1'b1;
                        RESETn <= 1'b1;
                        state <= s_BP_WTA_TEST3;
                    end
                s_BP_WTA_TEST3: begin
                        content <= content;
                        bp_wta_test_mode <= 1'b0;
                        BP_PUn <= 1'b1;
                        WTA_EN <= 1'b0;
                        RESETn <= 1'b0;
                        state <= s_DOUT;
                        content_out <= {content_out[255:65],WTA_VALID,WTA_OUT};
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
                        prng_en <= 1'b1;
                        if (restart_flag==1'b1) begin
                            VAR <= content[67:4];
                            flip_counter <= 0;
                        end else begin
                            VAR <= VAR_flipped;
                            flip_counter <= flip_counter + 1;
                        end
                        restart_flag <= 1'b0;
                        fp_mode <= 1'b1;
                        FP_PUn <= 1'b0;
                        state <= s_SOLVE_RC;
                    end
                s_SOLVE_RC: begin
                        content <= content;
                        prng_en <= 1'b1;
                        flip_counter <= flip_counter;
                        VAR <= VAR;
                        fp_mode <= 1'b0;
                        FP_PUn <= 1'b1;
                        BP_PUn <= 1'b0;
                        TRUE0_reg <= TRUE0;
                        TRUE1_reg <= TRUE1;
                        prngbits_randClause <= PRNG_BITS[7:0];
                        state <= s_SOLVE_BMP;
                    end
                s_SOLVE_BMP: begin
                        content <= content;
                        flip_counter <= flip_counter;
                        VAR <= VAR;
                        fp_mode <= 1'b0;
                        FP_PUn <= 1'b1;
                        TRUE0_reg <= TRUE0_reg;
                        TRUE1_reg <= TRUE1_reg;
                        prngbits_randClause <= prngbits_randClause;
                        if (unsat==1'b1) begin
                            if (flip_counter > max_flips) begin
                                state <= s_DOUT;
                                content_out <= {content_out[255:82],flip_counter,VAR,1'b0};
                                BP_PUn <= 1'b1;
                                bmp_mode <= 1'b0;
                                prng_en <= 1'b0;
                            end else begin
                                state <= s_SOLVE_BBP;
                                content_out <= content_out;
                                BP_PUn <= 1'b0;
                                bmp_mode <= 1'b1;
                                prng_en <= 1'b1;
                            end
                        end else begin 
                            state <= s_DOUT;
                            content_out <= {content_out[255:82],flip_counter,VAR,1'b1};
                            BP_PUn <= 1'b1;
                            bmp_mode <= 1'b0;
                            prng_en <= 1'b0;
                        end
                    end
                s_SOLVE_BBP: begin
                        content <= content;
                        prng_en <= 1'b1;
                        flip_counter <= flip_counter;
                        VAR <= VAR;
                        fp_mode <= 1'b0;
                        bmp_mode <= 1'b0;
                        bbp_mode <= 1'b1;
                        FP_PUn <= 1'b1;
                        BP_PUn <= 1'b0;
                        memvar_mask <= variable_mask & ~VSAB_OUT;
                        candVar_reg <= 64'hFFFFFFFFFFFFFFFF;
                        TRUE0_reg <= TRUE0_reg;
                        TRUE1_reg <= TRUE1_reg;
                        prngbits_randClause <= prngbits_randClause;
                        prngbits_randVar <= PRNG_BITS[13:8];
                        state <= s_SOLVE_BWP;
                    end
                s_SOLVE_BWP: begin
                        content <= content;
                        prng_en <= 1'b1;
                        flip_counter <= flip_counter;
                        VAR <= VAR;
                        fp_mode <= 1'b0;
                        bmp_mode <= 1'b0;
                        bbp_mode <= 1'b0;
                        bwp_mode <= 1'b1;
                        FP_PUn <= 1'b1;
                        BP_PUn <= 1'b0;
                        memvar_mask <= memvar_mask;
                        candVar_reg <= VSAB_OUT;
                        TRUE0_reg <= TRUE0_reg;
                        TRUE1_reg <= TRUE1_reg;
                        prngbits_randClause <= prngbits_randClause;
                        prngbits_randVar <= PRNG_BITS[13:8];
                        sampled_noise <= {1'b0,PRNG_BITS[25:14]};
                        shonning_chosenVar <= randVar_sel_l0;
                        WTA_EN <= 1'b1;
                        RESETn <= 1'b1;
                        state <= s_SOLVE_FLIP;
                    end
                s_SOLVE_FLIP: begin
                        content <= content;
                        prng_en <= 1'b1;
                        flip_counter <= flip_counter;
                        VAR <= VAR;
                        fp_mode <= 1'b0;
                        bmp_mode <= 1'b0;
                        bbp_mode <= 1'b0;
                        bwp_mode <= 1'b0;
                        flip_mode <= 1'b1;
                        FP_PUn <= 1'b0;
                        BP_PUn <= 1'b1;
                        memvar_mask <= memvar_mask;
                        candVar_reg <= 0;
                        TRUE0_reg <= TRUE0_reg;
                        TRUE1_reg <= TRUE1_reg;
                        prngbits_randClause <= prngbits_randClause;
                        prngbits_randVar <= prngbits_randVar;
                        shonning_chosenVar <= shonning_chosenVar;
                        bv0_chosenVar <= randVar_sel_l0;
                        wta_chosenVar <= WTA_OUT;
                        WTA_EN <= 1'b0;
                        RESETn <= 1'b0;
                        take_random_walk <= random_walk_flag;
                        bv0_present <= candVar_present;
                        wta_valid_reg <= WTA_VALID;
                        state <= s_SOLVE_FP;
                    end
                s_PRNG_TEST: begin
                        content <= content;
                        content_out <= {content_out[255:32],PRNG_BITS[31:0]};
                        prng_en <= 1'b0;
                        state <= s_DOUT;
                    end
                default: begin
                            BUSY <= 1'b0;
                            SDO1 <= 1'b0;
                            TX_READY <= 1'b0;
                            content <= 0;
                            state <= s_IDLE;
                            fp_vsa_test_mode <= 1'b0;
                            bp_vsa_test_mode <= 1'b0;
                            bp_wta_test_mode <= 1'b0;
                            bp_mux_test_mode <= 1'b0;
                            BP_MUX_READY <= 1'b0;
                            fp_mode <= 1'b0;
                            bmp_mode <= 1'b0;
                            bbp_mode <= 1'b0;
                            bwp_mode <= 1'b0;
                            wta_test_mode <= 1'b0;
                            WTA_EN <= 1'b0;
                            RESETn <= 1'b0;
                            FP_PUn <= 1'b1;
                            BP_PUn <= 1'b1;
                            prog_mode <= 1'b0;
                            r_Bit_Index <= 255;
                            prog_bl_wait_counter <= 1'b0;
                            prog_wl_wait_counter <= 1'b0;
                            prog_postwl_wait_counter <= 1'b0;
                            VAR <= content[67:4];
                            prngbits_randClause <= 0;
                            prngbits_randVar <= 0;
                            memvar_mask <= 0;
                            flip_mode <= 1'b0;
                            flip_counter <= 0;
                            TRUE0_reg <= 0;
                            TRUE1_reg <= 0;
                            wta_valid_reg <= 1'b0;
                            bv0_present <= 1'b0;
                            take_random_walk <= 1'b0;
                            wta_chosenVar <= 0;
                            bv0_chosenVar <= 0;
                            shonning_chosenVar <= 0;
                            candVar_reg <= 0;
                            sampled_noise <= 0;
                            prng_rst <= 1'b0;
                            prng_en <= 1'b0;
                            content_out <= 0;
                         end
           endcase
        end
    end
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule

