module GINT2AChipletTop(
    input iocell_clock_io_pad, iocell_clock2_io_pad,
	
    // clock_io arrives via a fake non-pad input for CTS
    input clock_io, clock2_io,
    input iocell_reset_io_pad,
    input iocell_CS1_pad, iocell_SDI1_pad,
    input iocell_START_pad, iocell_CS2_pad,
    output iocell_BUSY_pad, iocell_SDO1_pad,
	
	//Analog Wires
    inout ref0_pad, ref1_pad, ref2_pad, extA_pad, extB_pad, vrefp1_pad, vrefp2_pad, vrefp3_pad, vrefn1_pad, vrefn2_pad, vrefn3_pad, VDD, VSS, AVDD, AVSS,
	
    // fake outputs for SDC
	output RWLF_pre, RWLBS_pre, RWLBZ_pre, MB_SEL, PBIT_SEL, DRDN_WBLp, DRUPn_WBLp, DRDN_WBLn, DRUPn_WBLn, WWL_pre, VSAB_EN, VSAF_EN, PBIT_EN, FP_PUn, BP_PUnS, BP_PUnZ, rn0, rn1, rn2, rn3, rp0, rp1, rp2, rp3);

//Analog wires below:
wire ref0, ref1, ref3, extA, extB, vref_p1, vref_p2, vref_p3, vref_n1, vref_n2, vref_n3;

wire io_ring_bias, io_ring_hvps, io_ring_poc;
wire VDD, VSS, DVDD, DVSS, AVDD, AVSS;

wire clock_io, reset_io, CS1, SDI1;
wire [63:0] PBIT_OUT;
wire [255:0] TRUE0;
wire [255:0] TRUE1;
wire [63:0] VSAB_OUT;
wire BUSY, SDO1;
// wire TX_READY;
wire [63:0] PBIT_SEL;
wire [63:0] MB_SEL;
wire [127:0] RWLF_pre;
wire [255:0] RWLBS_pre, RWLBZ_pre;
wire [127:0] DRUPn_WBLn;
wire [127:0] DRUPn_WBLp;
wire [127:0] DRDN_WBLn;
wire [127:0] DRDN_WBLp;
wire [127:0] BP_PUnS, BP_PUnZ;
wire [255:0] WWL_pre;
wire VSAF_EN, VSAB_EN, PBIT_EN, FP_PUn;

wire [63:0] rn0, rn1, rn2, rn3, rp0, rp1, rp2, rp3;

wire clock2_io, START, CS2;

main_control main_control(
	.clk(clock_io),
    .rst(reset_io),
	.CS1(CS1),
	.SDI1(SDI1),
	.clk2(clock2_io),
	.START(START),
	.CS2(CS2),
	.PBIT_OUT(PBIT_OUT),
	.TRUE0(TRUE0),
	.TRUE1(TRUE1),
	.VSAB_OUT(VSAB_OUT),
	.BUSY(BUSY),
	.SDO1(SDO1),
	.PBIT_SEL(PBIT_SEL),
	.rn0(rn0),
	.rn1(rn1),
	.rn2(rn2),
	.rn3(rn3),
	.rp0(rp0),
	.rp1(rp1),
	.rp2(rp2),
	.rp3(rp3),
	.RWLF_pre(RWLF_pre),
	.RWLBS_pre(RWLBS_pre),
	.RWLBZ_pre(RWLBZ_pre),
	.MB_SEL(MB_SEL),
	.BP_PUnS(BP_PUnS),
	.BP_PUnZ(BP_PUnZ),
	.DRDN_WBLp(DRDN_WBLp),
	.DRUPn_WBLp(DRUPn_WBLp),
	.DRDN_WBLn(DRDN_WBLn),
	.DRUPn_WBLn(DRUPn_WBLn),
	.WWL_pre(WWL_pre),
	.VSAF_EN(VSAF_EN),
	.VSAB_EN(VSAB_EN),
	.FP_PUn(FP_PUn),
	.PBIT_EN(PBIT_EN)
);


array_with_periph a (

    //inputs
	.BP_PUnS(BP_PUnS),
	.BP_PUnZ(BP_PUnZ),
	.DRDN_WBLn(DRDN_WBLn),
	.DRDN_WBLp(DRDN_WBLp),
	.DRUPn_WBLn(DRUPn_WBLn),
	.DRUPn_WBLp(DRUPn_WBLp),
	.FP_PUn(FP_PUn),
	.MB_SEL(MB_SEL),
	.PBIT_EN(PBIT_EN),
	.PBIT_SEL(PBIT_SEL),
	.RWLBS_pre(RWLBS_pre),
	.RWLBZ_pre(RWLBZ_pre),
	.RWLF_pre(RWLF_pre),
	.VSAB_EN(VSAB_EN),
	.VSAF_EN(VSAF_EN),
	.WWL_pre(WWL_pre),
	.rn0(rn0),
	.rn1(rn1),
	.rn2(rn2),
	.rn3(rn3),
	.rp0(rp0),
	.rp1(rp1),
	.rp2(rp2),
	.rp3(rp3),
	
    //outputs
    .PBIT_OUT(PBIT_OUT),
    .TRUE0(TRUE0),
    .TRUE1(TRUE1),
    .VSAB_OUT(VSAB_OUT),
	
    //analog signal
    .ref0(ref0),
    .ref1(ref1),
    .ref2(ref2),
    .extA(extA),
    .extB(extB),
	.vref_p1(vref_p1),
    .vref_p2(vref_p2),
	.vref_p3(vref_p3),
	.vref_n1(vref_n1),
    .vref_n2(vref_n2),
	.vref_n3(vref_n3),
	
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

// wire iocell_BUSY_pad;
SRC_BI_SDS_33V_STB iocell_BUSY(
    .PAD(iocell_BUSY_pad),
    .I(BUSY),
    .OEN(1'b0),
    // .C(1'b0),
    .REN(1'b0),
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
    .OEN(1'b0),
    // .C(1'b0),
    .REN(1'b0),
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

ANC_BI_DWR_33V iocell_vrefp1 (
    .ANIN(vrefp1_pad),
    .RIN(vref_p1),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

ANC_BI_DWR_33V iocell_vrefp2 (
    .ANIN(vrefp2_pad),
    .RIN(vref_p2),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

ANC_BI_DWR_33V iocell_vrefp3 (
    .ANIN(vrefp3_pad),
    .RIN(vref_p3),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

ANC_BI_DWR_33V iocell_vrefn1 (
    .ANIN(vrefn1_pad),
    .RIN(vref_n1),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

ANC_BI_DWR_33V iocell_vrefn2 (
    .ANIN(vrefn2_pad),
    .RIN(vref_n2),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

ANC_BI_DWR_33V iocell_vrefn3 (
    .ANIN(vrefn3_pad),
    .RIN(vref_n3),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);

PWC_VD_ANA_12V iocell_AVDD[4:0] (
    .AVDD(AVDD),
    .POC(io_ring_poc),
    .HVPS(io_ring_hvps),
    .BIAS(io_ring_bias),
    .VDD(VDD), .VSS(VSS), .DVDD(DVDD), .DVSS(DVSS)
);
PWC_VS_ANA_12V iocell_AVSS[5:0] (
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