module GINT1AChipletTop(
    input iocell_clock_io_pad, iocell_clock2_io_pad,
    // clock_io arrives via a fake non-pad input for CTS
    input clock_io, clock2_io,
    input iocell_reset_io_pad,
    input iocell_CS1_pad, iocell_SDI1_pad,
    input iocell_BP_MUX_SAMPLED_pad,
    input iocell_START_pad, iocell_CS2_pad,
    output iocell_BUSY_pad, iocell_SDO1_pad,
    // output iocell_TX_READY_pad,
    output iocell_BP_MUX_READY_pad,
    inout ref0_pad, ref1_pad, ref2_pad, ext0_pad, extA_pad, extB_pad,
    inout BP_MUX_OUT_pad[7:0],
    // fake outputs for SDC
    output VSAF_EN, VSAB_EN, FP_PUn, BP_PUn, WTA_EN, RESETn,
    output RWLF_pre, RWLB_pre, WTA_SEL0, WTA_SEL1, LIT_SEL, BP_MUX_SEL, DRDN_WBLp, DRDN_WBLn, DRUPn_WBLp, DRUPn_WBLn, WWL_pre, 
);

//Analog wires below:
wire ref0, ref1, ref3;

wire io_ring_bias, io_ring_hvps, io_ring_poc;
wire VDD, VSS, DVDD, DVSS, AVDD, AVSS;

wire clock_io, reset_io, CS1, SDI1;
wire [63:0] WTA_OUT;
wire WTA_VALID;
wire [255:0] TRUE0;
wire [255:0] TRUE1;
wire [63:0] VSAB_OUT;
wire BP_MUX_SAMPLED;
wire BUSY, SDO1;
// wire TX_READY;
wire [63:0] WTA_SEL0;
wire [63:0] WTA_SEL1;
wire [127:0] RWLF_pre;
wire [255:0] RWLB_pre;
wire [63:0] LIT_SEL;
wire [15:0] BP_MUX_SEL;
wire [127:0] DRUPn_WBLn;
wire [127:0] DRUPn_WBLp;
wire [127:0] DRDN_WBLn;
wire [127:0] DRDN_WBLp;
wire [255:0] WWL_pre;
wire VSAF_EN, VSAB_EN, FP_PUn, BP_PUn, BP_MUX_READY, WTA_EN, RESETn;
wire [7:0] BP_MUX_OUT;

wire clock2_io, START, CS2;

main_control_new mc (
    .clk(clock_io),
    .clk2(clock2_io),
    .rst(reset_io),
    .CS1(CS1),
    .CS2(CS2),
    .START(START),
    .SDI1(SDI1),
    .WTA_OUT(WTA_OUT),
    .WTA_VALID(WTA_VALID),
    .TRUE0(TRUE0),
    .TRUE1(TRUE1),
    .VSAB_OUT(VSAB_OUT),
    .BP_MUX_SAMPLED(BP_MUX_SAMPLED),
    .BUSY(BUSY),
    .SDO1(SDO1),
    // .TX_READY(TX_READY),
    .WTA_SEL0(WTA_SEL0),
    .WTA_SEL1(WTA_SEL1),
    .RWLF_pre(RWLF_pre),
    .RWLB_pre(RWLB_pre),
    .LIT_SEL(LIT_SEL),
    .BP_MUX_SEL(BP_MUX_SEL),
    .DRUPn_WBLn(DRUPn_WBLn),
    .DRUPn_WBLp(DRUPn_WBLp),
    .DRDN_WBLn(DRDN_WBLn),
    .DRDN_WBLp(DRDN_WBLp),
    .WWL_pre(WWL_pre),
    .VSAF_EN(VSAF_EN),
    .VSAB_EN(VSAB_EN),
    .FP_PUn(FP_PUn),
    .BP_PUn(BP_PUn),
    .BP_MUX_READY(BP_MUX_READY),
    .WTA_EN(WTA_EN)
    // .RESETn(RESETn)
);



array_with_periph_encorr a (
    //inputs
    // .clk(clock_io),
    // .rst(reset_io),
    .WTA_SEL0(WTA_SEL0),
    .WTA_SEL1(WTA_SEL1),
    .RWLF_pre(RWLF_pre),
    .RWLB_pre(RWLB_pre),
    .LIT_SEL(LIT_SEL),
    .BP_MUX_SEL(BP_MUX_SEL),
    .DRDN_WBLp(DRDN_WBLp),
    .DRUPn_WBLp(DRUPn_WBLp),
    .DRDN_WBLn(DRDN_WBLn),
    .DRUPn_WBLn(DRUPn_WBLn),
    .WWL_pre(WWL_pre),
    .VSAF_EN(VSAF_EN),
    .VSAB_EN(VSAB_EN),
    .FP_PUn(FP_PUn),
    .BP_PUn(BP_PUn),
    .WTA_EN(WTA_EN),
    // .RESETN(RESETn),
    //outputs
    .WTA_VALID(WTA_VALID),
    .WTA_OUT(WTA_OUT),
    .TRUE0(TRUE0),
    .TRUE1(TRUE1),
    .VSAB_OUT(VSAB_OUT),
    //analog signal
    .ref0(ref0),
    .ref1(ref1),
    .ref2(ref2),
    .ext0(ext0),
    .extA(extA),
    .extB(extB),
    .BP_MUX_OUT(BP_MUX_OUT),
    //power
    .AVDD(AVDD),
    .AVSS(AVSS),
    .VDD(VDD),
    .VSS(VSS)
);

STC_IN_001_33V_NC iocell_clock2_io (
    .PAD(iocell_clock2_io_pad),
    .C(clock2_io),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

STC_IN_001_33V_NC iocell_START (
    .PAD(iocell_START_pad),
    .C(START),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

STC_IN_001_33V_NC iocell_CS2 (
    .PAD(iocell_CS2_pad),
    .C(CS2),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

STC_IN_001_33V_NC iocell_BP_MUX_SAMPLED(
    .PAD(iocell_BP_MUX_SAMPLED_pad),
    .C(BP_MUX_SAMPLED),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);


// wire iocell_clock_io_pad;
STC_IN_001_33V_NC iocell_clock_io(
    .PAD(iocell_clock_io_pad),
    .C(clock_io),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

// wire iocell_reset_io_pad;
STC_IN_001_33V_NC iocell_reset_io(
    .PAD(iocell_reset_io_pad),
    .C(reset_io),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

// wire iocell_CS1_pad;
STC_IN_001_33V_NC iocell_CS1(
    .PAD(iocell_CS1_pad),
    .C(CS1),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

// wire iocell_SDI1_pad;
STC_IN_001_33V_NC iocell_SDI1(
    .PAD(iocell_SDI1_pad),
    .C(SDI1),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

SRC_BI_SDS_33V_STB iocell_BP_MUX_READY(
    .PAD(iocell_BP_MUX_READY_pad),
    .I(BP_MUX_READY),
    .OEN(1'b1),
    // .C(1'b0),
    .REN(1'b1),
    .SMT(1'b0),
    .SR(1'b0),
    .P1(1'b0),
    .P2(1'b0),
    .E1(1'b0),
    .E2(1'b1),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .POS(1'b0),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

// wire iocell_BUSY_pad;
SRC_BI_SDS_33V_STB iocell_BUSY(
    .PAD(iocell_BUSY_pad),
    .I(BUSY),
    .OEN(1'b1),
    // .C(1'b0),
    .REN(1'b1),
    .SMT(1'b0),
    .SR(1'b0),
    .P1(1'b0),
    .P2(1'b0),
    .E1(1'b0),
    .E2(1'b1),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .POS(1'b0),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

// wire iocell_SDO1_pad;
SRC_BI_SDS_33V_STB iocell_SDO1 (
    .PAD(iocell_SDO1_pad),
    .I(SDO1),
    .OEN(1'b1),
    // .C(1'b0),
    .REN(1'b1),
    .SMT(1'b0),
    .SR(1'b0),
    .P1(1'b0),
    .P2(1'b0),
    .E1(1'b0),
    .E2(1'b1),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .POS(1'b0),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

// wire iocell_TX_READY_pad;
// SRC_BI_SDS_33V_STB iocell_TX_READY (
//     .PAD(iocell_TX_READY_pad),
//     .I(TX_READY),
//     .OEN(1'b1),
//     // .C(1'b0),
//     .REN(1'b0),
//     .SMT(1'b0),
//     .SR(1'b0),
//     .P1(1'b0),
//     .P2(1'b0),
//     .E1(1'b0),
//     .E2(1'b0),
//     .POC(io_ring_poc),
//     .HVPS(io_ring_hvps),
//     .BIAS(io_ring_bias),
//     .POS(1'b0),
//     .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
// );

ANC_BI_DWR_33V iocell_ref0 (
    .ANIN(ref0_pad),
    .RIN(ref0),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

ANC_BI_DWR_33V iocell_ref1 (
    .ANIN(ref1_pad),
    .RIN(ref1),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

ANC_BI_DWR_33V iocell_ref2 (
    .ANIN(ref2_pad),
    .RIN(ref2),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

ANC_BI_DWR_33V iocell_ext0 (
    .ANIN(ext0_pad),
    .RIN(ext0),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
ANC_BI_DWR_33V iocell_extA (
    .ANIN(extA_pad),
    .RIN(extA),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
ANC_BI_DWR_33V iocell_extB (
    .ANIN(extB_pad),
    .RIN(extB),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

ANC_BI_DWR_33V iocell_BP_MUX_OUT[7:0] (
    .ANIN(BP_MUX_OUT_pad),
    .RIN(BP_MUX_OUT),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

PWC_VD_ANA_12V iocell_AVDD[2:0] (
    .AVDD(AVDD),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
PWC_VS_ANA_12V iocell_AVSS[2:0] (
    .AVSS(AVSS),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

PWC_VD_RDO_33V iocell_DVDD [1:0] (
    .POC(io_ring_poc), .HVPS(io_ring_hvps), .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
PWC_VD_PDO_33V iocell_DVDD_control (
    .SEL18(1'b0),
    .POC(io_ring_poc), .HVPS(io_ring_hvps), .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
PWC_VS_RDO_33V iocell_DVSS[1:0] (
    .POC(io_ring_poc), .HVPS(io_ring_hvps), .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
PWC_VD_RCD_12V iocell_VDD [5:0] (
    .POC(io_ring_poc), .HVPS(io_ring_hvps), .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
PWC_VS_RCD_12V iocell_VSS [5:0] (
    .POC(io_ring_poc), .HVPS(io_ring_hvps), .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

SPC_CO_001_33V corner_cell_0 (
    .POC(io_ring_poc), .HVPS(io_ring_hvps), .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
SPC_CO_001_33V corner_cell_1 (
    .POC(io_ring_poc), .HVPS(io_ring_hvps), .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
SPC_CO_001_33V corner_cell_2 (
    .POC(io_ring_poc), .HVPS(io_ring_hvps), .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
SPC_CO_001_33V corner_cell_3 (
    .POC(io_ring_poc), .HVPS(io_ring_hvps), .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

endmodule