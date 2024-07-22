// Wrapper around wizard-generated event receiver GTX block
//
// Provides word framing and access to dynamic reconfiguration port.
// Can't use manual or automatic bit slide to achieve framing since this
// leaves the recovered clock at a variable bit offset from the event
// generator reference clock.  Instead the transceiver is reset until it
// starts up with correct framing.  This has a 99.9% chance of happening
// within 135 attempts ((19/20)^135=0.983e-3).

module evrGTXwrapper #(
    parameter DEBUG = "false"
    ) (
    input              sysClk,
    input       [31:0] sysGPIO_OUT,

    input              csrStrobe,
    output wire [31:0] csrStatus,

    input              drpStrobe,
    output wire [31:0] drpStatus,

    input              refClk,
    input              RX_P,
    input              RX_N,
    output             TX_P,
    output             TX_N,
    output             evrTxClk,

    output wire                            evrClk,
    output wire                            evrRxSynchronized,
    (*mark_debug=DEBUG*) output reg [15:0] evrChars,
    (*mark_debug=DEBUG*) output reg  [1:0] evrCharIsK,
    (*mark_debug=DEBUG*) output reg  [1:0] evrCharIsComma);

(*mark_debug=DEBUG*) wire [15:0] rxData;
(*mark_debug=DEBUG*) wire [1:0] rxIsK, rxIsComma, rxNotInTable, rxDispErr;

//////////////////////////////////////////////////////////////////////////////
// Receiver alignment detection
localparam COMMAS_NEEDED = 60;
localparam COMMA_COUNTER_RELOAD = COMMAS_NEEDED - 1;
localparam COMMA_COUNTER_WIDTH = $clog2(COMMA_COUNTER_RELOAD+1) + 1;
(*mark_debug=DEBUG*) reg [COMMA_COUNTER_WIDTH-1:0] commaCounter =
                                                           COMMA_COUNTER_RELOAD;
wire rxIsAligned = commaCounter[COMMA_COUNTER_WIDTH-1];
assign evrRxSynchronized = rxIsAligned;
// K character can only appear on word 0
wire rxDataErr = (rxNotInTable != 0) || rxIsK[1] || (rxDispErr != 0);

wire sysSlideRequest;
(*ASYNC_REG="true"*) reg slideRequest_m = 0;
reg slideRequest_d0 = 0, slideRequest_d1 = 0;
(*mark_debug=DEBUG*) reg bitSlide = 0;
always @(posedge evrClk) begin
    slideRequest_m  <= sysSlideRequest;
    slideRequest_d0 <= slideRequest_m;
    slideRequest_d1 <= slideRequest_d0;
    bitSlide <= slideRequest_d0 && !slideRequest_d1;

    if (rxIsAligned && !rxDataErr) begin
        evrChars <= rxData;
        evrCharIsK <= rxIsK;
        evrCharIsComma <= rxIsComma;
    end
    else begin
        evrChars <= 0;
        evrCharIsK <= 0;
        evrCharIsComma <= 0;
    end

    if (rxDataErr) begin
        commaCounter <= COMMA_COUNTER_RELOAD;
    end
    else if (!rxIsAligned && rxIsK[0] && (rxData[7:0] == 8'hBC)) begin
        commaCounter <= commaCounter - 1;
    end
end

//////////////////////////////////////////////////////////////////////////////
// MGT dynamic reconfiguration port control/status
localparam DRP_DATA_WIDTH          = 16;
localparam DRP_ADDR_WIDTH          = 9;
localparam DRP_RESET_CONTROL_WIDTH = 6;
localparam DRP_RESET_STATUS_WIDTH  = 7;
wire                               drp_en, drp_we, drp_rdy;
wire          [DRP_ADDR_WIDTH-1:0] drp_addr;
wire          [DRP_DATA_WIDTH-1:0] drp_di, drp_do;
(*mark_debug=DEBUG*) wire [DRP_RESET_CONTROL_WIDTH-1:0] mgtControl;
(*mark_debug=DEBUG*) wire  [DRP_RESET_STATUS_WIDTH-1:0] mgtStatus;
drpControl #(
    .DRP_DATA_WIDTH(DRP_DATA_WIDTH),
    .DRP_ADDR_WIDTH(DRP_ADDR_WIDTH),
    .RESET_CONTROL_WIDTH(DRP_RESET_CONTROL_WIDTH),
    .RESET_STATUS_WIDTH(DRP_RESET_STATUS_WIDTH))
  drpControl (
    .clk(sysClk),
    .strobe(drpStrobe),
    .dataIn(sysGPIO_OUT),
    .dataOut(drpStatus),
    .resetControl(mgtControl),
    .resetStatus(mgtStatus),
    .drp_en(drp_en),
    .drp_we(drp_we),
    .drp_rdy(drp_rdy),
    .drp_addr(drp_addr),
    .drp_di(drp_di),
    .drp_do(drp_do));

/////////////////////////////////////////////////////////////////////
// MGT (GTX)

wire rxoutclk;
BUFG evrClkBUFG (.I(rxoutclk), .O(evrClk));
wire txoutclk;
BUFG evrTxClkBUFG (.I(txoutclk), .O(evrTxClk));
//=========================================================================================
/* MGT control signals table
 ___________________________________________________________________
| GPIO INDEX   |  HEX VALUE   | MGT INDEX     | MGT CONNECTIONS     |
|--------------|--------------|---------------|---------------------|
| GPIO_OUT[30] | (0x40000000) | MGTcontrol[5] | sysSlideRequest	    |
| GPIO_OUT[29] | (0x20000000) | MGTcontrol[4] | gttxreset           |
| GPIO_OUT[28] | (0x10000000) | MGTcontrol[3] | rxpmareset          |
| GPIO_OUT[27] | (0x08000000) | MGTcontrol[2] | gtrxreset           |
| GPIO_OUT[26] | (0x04000000) | MGTcontrol[1] | cpllreset 		    |
| GPIO_OUT[25] | (0x02000000) | MGTcontrol[0] | soft reset tx / rx  |
'-------------------------------------------------------------------' */
wire gttxreset, rxpmareset, gtrxreset, cpllreset, softreset;
assign {sysSlideRequest,
        gttxreset,
        rxpmareset,
        gtrxreset,
        cpllreset,
        softreset} = mgtControl;

/* MGT status signals table
___________________________________________________________________
| GPIO INDEX  |  HEX VALUE   | MGT INDEX    | MGT CONNECTIONS      |
|-------------|--------------|--------------|----------------------|
| GPIO_IN[30] | (0x40000000) | mgtStatus[6] | rxIsAligned          |
| GPIO_IN[29] | (0x20000000) | mgtStatus[5] | rxresetdone          |
| GPIO_IN[28] | (0x10000000) | mgtStatus[4] | cplllock             |
| GPIO_IN[27] | (0x08000000) | mgtStatus[3] | cpllfbclklost        |
| GPIO_IN[26] | (0x04000000) | mgtStatus[2] | rx_fsm_reset_done    |
| GPIO_IN[25] | (0x02000000) | mgtStatus[1] | tx_fsm_reset_done    |
| GPIO_IN[24] | (0x01000000) | mgtStatus[0] | txresetdone          |
'------------------------------------------------------------------' */
wire txresetdone, rxresetdone, cplllock, cpllfbclklost, rx_fsm_reset_done, tx_fsm_reset_done;
assign mgtStatus = {rxIsAligned,
                    rxresetdone,
                    cplllock,
                    cpllfbclklost,
                    rx_fsm_reset_done,
                    tx_fsm_reset_done,
                    txresetdone};
//=========================================================================================

wire [4:0] rxPhaseMonitor, rxSlipMonitor;
assign csrStatus = { 22'b0, rxSlipMonitor, rxPhaseMonitor };

localparam LOOPBACK = 3'd4; // 4 == Far end PMA loopback

evrmgt evrmgt_i (
    .sysclk_in(sysClk), // input wire sysclk_in
    .soft_reset_tx_in(softreset), // input wire soft_reset_tx_in
    .soft_reset_rx_in(softreset), // input wire soft_reset_rx_in
    .dont_reset_on_data_error_in(1'b1), // input wire dont_reset_on_data_error_in
    .gt0_tx_fsm_reset_done_out(tx_fsm_reset_done), // output wire gt0_tx_fsm_reset_done_out
    .gt0_rx_fsm_reset_done_out(rx_fsm_reset_done), // output wire gt0_rx_fsm_reset_done_out
    .gt0_data_valid_in(1'b1), // input wire gt0_data_valid_in

    //_________________________________________________________________________
    //GT0  (X0Y0)
    //____________________________CHANNEL PORTS________________________________
    //------------------------------- CPLL Ports -------------------------------
    .gt0_cpllfbclklost_out   (cpllfbclklost), // output wire gt0_cpllfbclklost_out
    .gt0_cplllock_out        (cplllock), // output wire gt0_cplllock_out
    .gt0_cplllockdetclk_in   (sysClk), // input wire gt0_cplllockdetclk_in
    .gt0_cpllreset_in        (cpllreset), // input wire gt0_cpllreset_in
    //------------------------ Channel - Clocking Ports ------------------------
    .gt0_gtrefclk0_in        (refClk), // input wire gt0_gtrefclk0_in
    .gt0_gtrefclk1_in        (1'b0), // input wire gt0_gtrefclk1_in
    //-------------------------- Channel - DRP Ports  --------------------------
    //-------------------------- Channel - DRP Ports  --------------------------
    .gt0_drpaddr_in          (drp_addr), // input wire [8:0] gt0_drpaddr_in
    .gt0_drpclk_in           (sysClk), // input wire gt0_drpclk_in
    .gt0_drpdi_in            (drp_di), // input wire [15:0] gt0_drpdi_in
    .gt0_drpdo_out           (drp_do), // output wire [15:0] gt0_drpdo_out
    .gt0_drpen_in            (drp_en), // input wire gt0_drpen_in
    .gt0_drprdy_out          (drp_rdy), // output wire gt0_drprdy_out
    .gt0_drpwe_in            (drp_we), // input wire gt0_drpwe_in
    //------------------------- Digital Monitor Ports --------------------------
    .gt0_dmonitorout_out     (), // output wire [7:0] gt0_dmonitorout_out
    //----------------------------- Loopback Ports -----------------------------
    .gt0_loopback_in         (LOOPBACK), // input wire [2:0] gt0_loopback_in
    //------------------- RX Initialization and Reset Ports --------------------
    .gt0_eyescanreset_in     (1'b0), // input wire gt0_eyescanreset_in
    .gt0_rxuserrdy_in        (1'b1), // input wire gt0_rxuserrdy_in
    //------------------------ RX Margin Analysis Ports ------------------------
    .gt0_eyescandataerror_out(), // output wire gt0_eyescandataerror_out
    .gt0_eyescantrigger_in   (1'b0), // input wire gt0_eyescantrigger_in
    //---------------- Receive Ports - FPGA RX Interface Ports -----------------
    .gt0_rxusrclk_in         (evrClk), // input wire gt0_rxusrclk_in
    .gt0_rxusrclk2_in        (evrClk), // input wire gt0_rxusrclk2_in
    //---------------- Receive Ports - FPGA RX interface Ports -----------------
    .gt0_rxdata_out          (rxData), // output wire [15:0] gt0_rxdata_out
    //---------------- Receive Ports - RX 8B/10B Decoder Ports -----------------
    .gt0_rxdisperr_out       (rxDispErr), // output wire [1:0] gt0_rxdisperr_out
    .gt0_rxnotintable_out    (rxNotInTable), // output wire [1:0] gt0_rxnotintable_out
    //------------------------- Receive Ports - RX AFE -------------------------
    .gt0_gtxrxp_in           (RX_P), // input wire gt0_gtxrxp_in
    //---------------------- Receive Ports - RX AFE Ports ----------------------
    .gt0_gtxrxn_in           (RX_N), // input wire gt0_gtxrxn_in
    //----------------- Receive Ports - RX Buffer Bypass Ports -----------------
    .gt0_rxphmonitor_out     (rxPhaseMonitor), // output wire [4:0] gt0_rxphmonitor_out
    .gt0_rxphslipmonitor_out (rxSlipMonitor), // output wire [4:0] gt0_rxphslipmonitor_out
    //------------------- Receive Ports - RX Equalizer Ports -------------------
    .gt0_rxdfelpmreset_in    (1'b0), // input wire gt0_rxdfelpmreset_in
    .gt0_rxmonitorout_out    (), // output wire [6:0] gt0_rxmonitorout_out
    .gt0_rxmonitorsel_in     (2'b01), // input wire [1:0] gt0_rxmonitorsel_in
    //------------- Receive Ports - RX Fabric Output Control Ports -------------

    .gt0_rxoutclk_out        (rxoutclk), // output wire gt0_rxoutclk_out
    .gt0_rxoutclkfabric_out  (), // output wire gt0_rxoutclkfabric_out
    //----------- Receive Ports - RX Initialization and Reset Ports ------------
    .gt0_gtrxreset_in        (gtrxreset), // input wire gt0_gtrxreset_in
    .gt0_rxpmareset_in       (rxpmareset), // input wire gt0_rxpmareset_in
    //-------------------- Receive Ports - RX gearbox ports --------------------
    .gt0_rxslide_in          (bitSlide), // input wire gt0_rxslide_in
    //----------------- Receive Ports - RX8B/10B Decoder Ports -----------------
    .gt0_rxchariscomma_out   (rxIsComma), // output wire [1:0] gt0_rxchariscomma_out
    .gt0_rxcharisk_out       (rxIsK), // output wire [1:0] gt0_rxcharisk_out
    //------------ Receive Ports -RX Initialization and Reset Ports ------------
    .gt0_rxresetdone_out     (rxresetdone), // output wire gt0_rxresetdone_out
    //------------------- TX Initialization and Reset Ports --------------------
    .gt0_gttxreset_in        (gttxreset), // input wire gt0_gttxreset_in
    .gt0_txuserrdy_in        (1'b1), // input wire gt0_txuserrdy_in
    //---------------- Transmit Ports - FPGA TX Interface Ports ----------------
    .gt0_txusrclk_in         (evrTxClk), // input wire gt0_txusrclk_in
    .gt0_txusrclk2_in        (evrTxClk), // input wire gt0_txusrclk2_in
    //---------------- Transmit Ports - TX Data Path interface -----------------
    .gt0_txdata_in           (16'h0), // input wire [15:0] gt0_txdata_in
    //-------------- Transmit Ports - TX Driver and OOB signaling --------------
    .gt0_gtxtxn_out          (TX_N), // output wire gt0_gtxtxn_out
    .gt0_gtxtxp_out          (TX_P), // output wire gt0_gtxtxp_out
    //--------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    .gt0_txoutclk_out        (txoutclk), // output wire gt0_txoutclk_out
    .gt0_txoutclkfabric_out  (), // output wire gt0_txoutclkfabric_out
    .gt0_txoutclkpcs_out     (), // output wire gt0_txoutclkpcs_out
    //------------------- Transmit Ports - TX Gearbox Ports --------------------
    .gt0_txcharisk_in        (2'h0), // input wire [1:0] gt0_txcharisk_in
    //----------- Transmit Ports - TX Initialization and Reset Ports -----------
    .gt0_txresetdone_out     (txresetdone), // output wire gt0_txresetdone_out

    //____________________________COMMON PORTS________________________________
    .gt0_qplloutclk_in(1'b0), // input wire gt0_qplloutclk_in
    .gt0_qplloutrefclk_in(1'b0) // input wire gt0_qplloutrefclk_in
);

///////////////////////////////////////////////////////////////////////////////
// Xilinx Answer Record 43339
// Instantiate a GTXE2_COMMON even though QPLL is unused.
// Needed to set BIAS_CFG properly.

localparam WRAPPER_SIM_GTRESET_SPEEDUP ="false";
localparam SIM_VERSION = "4.0";
localparam QPLL_FBDIV_IN = 10'b0000100000;
localparam QPLL_FBDIV_RATIO = 1'b1;

wire [15:0] tied_to_ground_vec_i = 0;
wire tied_to_ground_i = 0;
wire tied_to_vcc_i = 1;
wire GT0_GTREFCLK0_COMMON_IN = refClk;
wire GT0_QPLLLOCKDETCLK_IN = sysClk;
wire GT0_QPLLRESET_IN = cpllreset;
wire GT0_QPLLLOCK_OUT;
wire GT0_QPLLREFCLKLOST_OUT;

// This code copied verbatim from the answer record:

//_________________________________________________________________________
    //_________________________________________________________________________
    //_________________________GTXE2_COMMON____________________________________

    GTXE2_COMMON #
    (
            // Simulation attributes
            .SIM_RESET_SPEEDUP   (WRAPPER_SIM_GTRESET_SPEEDUP),
            .SIM_QPLLREFCLK_SEL  (3'b001),
            .SIM_VERSION         (SIM_VERSION),


           //----------------COMMON BLOCK Attributes---------------
            .BIAS_CFG                               (64'h0000040000001000),
            .COMMON_CFG                             (32'h00000000),
            .QPLL_CFG                               (27'h06801C1),
            .QPLL_CLKOUT_CFG                        (4'b0000),
            .QPLL_COARSE_FREQ_OVRD                  (6'b010000),
            .QPLL_COARSE_FREQ_OVRD_EN               (1'b0),
            .QPLL_CP                                (10'b0000011111),
            .QPLL_CP_MONITOR_EN                     (1'b0),
            .QPLL_DMONITOR_SEL                      (1'b0),
            .QPLL_FBDIV                             (QPLL_FBDIV_IN),
            .QPLL_FBDIV_MONITOR_EN                  (1'b0),
            .QPLL_FBDIV_RATIO                       (QPLL_FBDIV_RATIO),
            .QPLL_INIT_CFG                          (24'h000006),
            .QPLL_LOCK_CFG                          (16'h21E8),
            .QPLL_LPF                               (4'b1111),
            .QPLL_REFCLK_DIV                        (1)

    )
    gtxe2_common_0_i
    (
        //----------- Common Block  - Dynamic Reconfiguration Port (DRP) -----------
        .DRPADDR                        (tied_to_ground_vec_i[7:0]),
        .DRPCLK                         (tied_to_ground_i),
        .DRPDI                          (tied_to_ground_vec_i[15:0]),
        .DRPDO                          (),
        .DRPEN                          (tied_to_ground_i),
        .DRPRDY                         (),
        .DRPWE                          (tied_to_ground_i),
        //-------------------- Common Block  - Ref Clock Ports ---------------------
        .GTGREFCLK                      (tied_to_ground_i),
        .GTNORTHREFCLK0                 (tied_to_ground_i),
        .GTNORTHREFCLK1                 (tied_to_ground_i),
        .GTREFCLK0                      (GT0_GTREFCLK0_COMMON_IN),
        .GTREFCLK1                      (tied_to_ground_i),
        .GTSOUTHREFCLK0                 (tied_to_ground_i),
        .GTSOUTHREFCLK1                 (tied_to_ground_i),
        //----------------------- Common Block - QPLL Ports ------------------------
        .QPLLDMONITOR                   (),
        .QPLLFBCLKLOST                  (),
        .QPLLLOCK                       (GT0_QPLLLOCK_OUT),
        .QPLLLOCKDETCLK                 (GT0_QPLLLOCKDETCLK_IN),
        .QPLLLOCKEN                     (tied_to_vcc_i),
        .QPLLOUTCLK                     (),
        .QPLLOUTREFCLK                  (),
        .QPLLOUTRESET                   (tied_to_ground_i),
        .QPLLPD                         (tied_to_ground_i),
        .QPLLREFCLKLOST                 (GT0_QPLLREFCLKLOST_OUT),
        .QPLLREFCLKSEL                  (3'b001),
        .QPLLRESET                      (GT0_QPLLRESET_IN),
        .QPLLRSVD1                      (16'b0000000000000000),
        .QPLLRSVD2                      (5'b11111),
        .REFCLKOUTMONITOR               (),
        //--------------------------- Common Block Ports ---------------------------
        .BGBYPASSB                      (tied_to_vcc_i),
        .BGMONITORENB                   (tied_to_vcc_i),
        .BGPDB                          (tied_to_vcc_i),
        .BGRCALOVRD                     (5'b00000),
        .PMARSVD                        (8'b00000000),
        .RCALENB                        (tied_to_vcc_i)

    );

endmodule
