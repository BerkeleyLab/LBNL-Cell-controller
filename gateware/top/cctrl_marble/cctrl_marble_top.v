module cctrl_marble_top #(
  parameter PILOT_TONE_REFERENCE_DIRECT_OUTPUT_ENABLE = "false"
  ) (
  input  wire        S6_TO_K7_CLK_1,  // TODO - What is this?

  output wire  [5:0] kintexLEDs,      // TODO - Will this exist on marble port?

  input  wire        Uart_RxD,        // DONE
  output wire        Uart_TxD,        // DONE

  input  wire        GTX_REF_312_3_N, GTX_REF_312_3_P,  // TODO - What is this?
  input  wire        GTX_REF_125_N, GTX_REF_125_P,  // TODO - What is this?
  output wire        SIT9122_ENABLE,  // TODO - Clock generator enable.
                                      // Gates clock to GTX_REF0_P/N (MGTREFCLK0P/N_116)
                                      // On marble U2A (ADN4600ACPZ) output is not gated, but has a nRST (CLKMUX_RST)
                                      // which comes from I2C I/O expander P1_7 (U39 pin 17)
                                      // There's also SI570_OE from the same expander P0_0

  inout  wire        QSFP_SCL,        // TODO - Marble not directly connected to QSFP I2C bus. Goes through TCA9517 mux now.
  inout  wire        QSFP_SDA,        // TODO - Marble not directly connected to QSFP I2C bus. Goes through TCA9517 mux now.
  input  wire        QSFP1_PRESENT_N, // TODO - Marble connects to QSFP config via PCA9555 I2C I/O expander (U34)
  output wire        QSFP1_LPMODE, QSFP1_RESET_N, QSFP1_MODSEL_N,// TODO - Marble connects to QSFP config via PCA9555 I2C I/O expander (U34)
  input  wire  [2:0] QSFP1_RX_N, QSFP1_RX_P, // DONE (will need to comment unused out of XDC)
  output wire  [2:1] QSFP1_TX_N, QSFP1_TX_P, // DONE (will need to comment unused out of XDC)
  input  wire        QSFP2_PRESENT_N, // TODO - Marble connects to QSFP config via PCA9555 I2C I/O expander (U34)
  output wire        QSFP2_LPMODE, QSFP2_RESET_N, QSFP2_MODSEL_N, // TODO - Marble connects to QSFP config via PCA9555 I2C I/O expander (U34)
  input  wire  [3:0] QSFP2_RX_N, QSFP2_RX_P, // DONE (will need to comment unused out of XDC)
  output wire  [3:0] QSFP2_TX_N, QSFP2_TX_P, // DONE (will need to comment unused out of XDC)

  input  wire        epicsUDPrxData,  // TODO - No longer at top level (does not leave FPGA)
  output wire        epicsUDPtxData,  // TODO - No longer at top level (does not leave FPGA)

  //output wire  [9:0] K7_EXT_IO,       // DONE - Removed (unused in application)

  //inout  wire        PILOT_TONE_I2C_SCL,PILOT_TONE_I2C_SDA, // DONE - Not implemented in marble
  //output wire        PILOT_TONE_REFCLK_P, PILOT_TONE_REFCLK_N, // DONE - Not implemented in marble port
  input  wire        INTLK_RELAY_NO,    // TOP FMC LA 31P (FMC G33) (Zest P1:HDMI_CEC, P2:P2_ADC_CSB_0)
  output wire        INTLK_RELAY_CTL,   // TOP FMC LA 31N (FMC G34) (Zest P1:HDMI_SCL, P2:P2_ADC_CSB_1)
  input  wire        INTLK_RESET_BUTTON_N,  // TOP FMC LA 22P (FMC G24) (Zest P1:ADC_D0A_N_1, P2:P2_AD7794_FCLK)

  output wire        FP_LED0_RED, FP_LED0_GRN,  // TODO - Will these exist on marble port?
  output wire        FP_LED1_RED, FP_LED1_GRN,  // TODO - Will these exist on marble port?
  output wire        FP_LED2_RED, FP_LED2_GRN,  // TODO - Will these exist on marble port?
  //output wire        FP_TEST_POINT, // DONE - Unused in application

  input  wire        ffbUDPrxData,  // TODO - No longer at top level (does not leave FPGA)
  output wire        ffbUDPtxData,  // TODO - No longer at top level (does not leave FPGA)

  input  wire        spareUDPrxData,// TODO - No longer at top level (does not leave FPGA)
  output wire        spareUDPtxData // TODO - No longer at top level (does not leave FPGA)
  );

//////////////////////////////////////////////////////////////////////////////
// Static outputs
assign SIT9122_ENABLE = 1'b1;
assign ffbUDPtxData = 1'b1;
assign spareUDPtxData = 1'b1;

//////////////////////////////////////////////////////////////////////////////
// The clock domains
// Net names starting with 'evr' are in the event receiver clock domain.
// Net names starting with 'aurora' are in the Aurora user clock domain.
parameter SYSCLK_RATE = 100000000;
wire sysClk, evrClk, auroraUserClk, clk200, ethRefClk125;
wire sysReset_n;

//////////////////////////////////////////////////////////////////////////////
// General-purpose I/O block
`include "gpioIDX.v"
wire                    [31:0] GPIO_IN[0:GPIO_IDX_COUNT-1];
wire                    [31:0] GPIO_OUT;
wire      [GPIO_IDX_COUNT-1:0] GPIO_STROBES;
wire [(GPIO_IDX_COUNT*32)-1:0] GPIO_IN_FLATTENED;
genvar i;
generate
for (i = 0 ; i < GPIO_IDX_COUNT ; i = i + 1) begin : gpio_flatten
    assign GPIO_IN_FLATTENED[ (i*32)+31 : (i*32)+0 ] = GPIO_IN[i];
end
endgenerate

//////////////////////////////////////////////////////////////////////////////
// Timekeeping
reg [31:0] secondsSinceBoot, microsecondsSinceBoot;
reg [$clog2(SYSCLK_RATE/1000000)-1:0] microsecondsDivider=SYSCLK_RATE/1000000-1;
reg             [$clog2(1000000)-1:0] secondsDivider = 1000000-1;
reg usTick = 0, sTick = 0;
always @(posedge sysClk) begin
    if (microsecondsDivider == 0) begin
        microsecondsDivider <= SYSCLK_RATE/1000000-1;
        usTick <= 1;
    end
    else begin
        microsecondsDivider <= microsecondsDivider - 1;
        usTick <= 0;
    end
    if (usTick) begin
        microsecondsSinceBoot <= microsecondsSinceBoot + 1;
        if (secondsDivider == 0) begin
            secondsDivider <= 1000000-1;
            sTick <= 1;
        end
        else begin
            secondsDivider <= secondsDivider - 1;
        end
    end
    else begin
        sTick <= 0;
    end
    if (sTick) begin
        secondsSinceBoot <= secondsSinceBoot + 1;
    end
end
assign GPIO_IN[GPIO_IDX_SECONDS]      = secondsSinceBoot;
assign GPIO_IN[GPIO_IDX_MICROSECONDS] = microsecondsSinceBoot;

// Get EVR timestamp to system clock domain
wire [63:0] evrTimestamp, sysTimestamp;
forwardData #(.DATA_WIDTH(64))
  forwardData(.inClk(evrClk),
              .inData(evrTimestamp),
              .outClk(sysClk),
              .outData(sysTimestamp));

//////////////////////////////////////////////////////////////////////////////
// QSFP monitoring
parameter QSFP_COUNT = 2;
reg [$clog2(QSFP_COUNT)+6:0] qsfpReadAddress;
wire [15:0] qsfpReadData;
assign GPIO_IN[GPIO_IDX_QSFP_IIC] = {{16-QSFP_COUNT{1'b0}},
                                     QSFP2_PRESENT_N, QSFP1_PRESENT_N,
                                     qsfpReadData};
always @(posedge sysClk) begin
    if (GPIO_STROBES[GPIO_IDX_QSFP_IIC]) begin
        qsfpReadAddress <= GPIO_OUT[$clog2(QSFP_COUNT)+6:0];
    end
end
qsfpReadout #(.QSFP_COUNT(QSFP_COUNT),
              .dbg("false"),
              .CLOCK_RATE(SYSCLK_RATE),
              .BIT_RATE(100000)) qsfpReadout (
                             .clk(sysClk),
                             .readAddress(qsfpReadAddress),
                             .readData(qsfpReadData),
                             .PRESENT_n({QSFP2_PRESENT_N, QSFP1_PRESENT_N}),
                             .RESET_n({QSFP2_RESET_N, QSFP1_RESET_N}),
                             .MODSEL_n({QSFP2_MODSEL_N, QSFP1_MODSEL_N}),
                             .LPMODE({QSFP2_LPMODE, QSFP1_LPMODE}),
                             .SCL(QSFP_SCL),
                             .SDA(QSFP_SDA));

/////////////////////////////////////////////////////////////////////////////
// Event receiver
wire [7:0] evrTriggerBus, evrDataBus;
wire evrFAmarker, evrIsSynchronized, evrHeartbeatPresent;
reg sysFAenable = 0, evrFAenable_m, evrFAenable;
evrSync evrSync(.clk(evrClk),
                .triggerIn(evrTriggerBus[0]),
                .FAenable(evrFAenable),
                .FAmarker(evrFAmarker),
                .isSynchronized(evrIsSynchronized),
                .triggered(evrHeartbeatPresent));
assign GPIO_IN[GPIO_IDX_EVENT_STATUS] = { 29'b0,
                                          evrRxLocked,
                                          evrIsSynchronized,
                                          evrHeartbeatPresent };
always @(posedge evrClk) begin
    evrFAenable_m <= sysFAenable;
    evrFAenable   <= evrFAenable_m;
end
reg auroraFAmarker_m, auroraFAmarker, auroraFAmarker_d, auroraFAstrobe;
always @(posedge auroraUserClk) begin
    auroraFAmarker_m <= evrFAmarker;
    auroraFAmarker   <= auroraFAmarker_m;
    auroraFAmarker_d <= auroraFAmarker;
    auroraFAstrobe <= (auroraFAmarker && !auroraFAmarker_d);
end
reg sysFAmarker_m, sysFAmarker, sysFAmarker_d, sysFAstrobe;
always @(posedge sysClk) begin
    sysFAmarker_m <= evrFAmarker;
    sysFAmarker   <= sysFAmarker_m;
    sysFAmarker_d <= sysFAmarker;
    sysFAstrobe <= (sysFAmarker && !sysFAmarker_d);
end

//////////////////////////////////////////////////////////////////////////////
// BPM and cell readout
wire pll_not_locked_out, gt0_qplllock_out, gt0_qpllrefclklost_out, gtxResetOut;
reg sysGTXreset = 1, sysAuroraReset = 1, auroraReset_m = 1, auroraReset = 1;
always @(posedge sysClk) begin
    if (GPIO_STROBES[GPIO_IDX_AURORA_CSR]) begin
        sysGTXreset    <= GPIO_OUT[0];
        sysAuroraReset <= GPIO_OUT[1];
        sysFAenable    <= GPIO_OUT[2];
    end
end
always @(posedge auroraUserClk) begin
    auroraReset_m <= sysAuroraReset;
    auroraReset   <= auroraReset_m;
end
assign GPIO_IN[GPIO_IDX_AURORA_CSR] = { 8'b0,
     CELL_CW_AuroraCoreStatus_hard_err, CELL_CCW_AuroraCoreStatus_hard_err,
     BPM_CW_AuroraCoreStatus_hard_err, BPM_CCW_AuroraCoreStatus_hard_err,
     CELL_CW_AuroraCoreStatus_soft_err, CELL_CCW_AuroraCoreStatus_soft_err,
     BPM_CW_AuroraCoreStatus_soft_err, BPM_CCW_AuroraCoreStatus_soft_err,
     CELL_CW_AuroraCoreStatus_channel_up, CELL_CCW_AuroraCoreStatus_channel_up,
     BPM_CW_AuroraCoreStatus_channel_up, BPM_CCW_AuroraCoreStatus_channel_up,
     pll_not_locked_out, gt0_qplllock_out, gt0_qpllrefclklost_out, gtxResetOut,
     5'b0, sysFAenable, sysAuroraReset, sysGTXreset };

/////////////////////////////////////////////////////////////////////////////
// Event receiver GTX
localparam EVR_DEBUG = "false";
wire        evr_mgt_drp_den, evr_mgt_drp_drdy, evr_mgt_drp_dwe;
wire [15:0] evr_mgt_drp_di, evr_mgt_drp_do;
wire  [8:0] evr_mgt_drp_daddr;
(* mark_debug=EVR_DEBUG *) wire  [1:0] evr_mgt_chariscomma, evr_mgt_charisk;
(* mark_debug=EVR_DEBUG *) wire  [1:0] evr_notintable;
(* mark_debug=EVR_DEBUG *) wire [15:0] evr_mgt_par_data;
(* mark_debug=EVR_DEBUG *) wire        evr_mgt_reset_done;

evr_mgt_top #(.COMMA_IS_LSB_FORCE(1)) evr_mgt_top_i (
         .reset(gtReset),
         .ref_clk(ethRefClk125),
         .drp_clk(sysClk),
         .drp_den(evr_mgt_drp_den),
         .drp_dwe(evr_mgt_drp_dwe),
         .drp_daddr(evr_mgt_drp_daddr),
         .drp_di(evr_mgt_drp_di),
         .drp_drdy(evr_mgt_drp_drdy),
         .drp_do(evr_mgt_drp_do),
         .rx_in_n(QSFP1_RX_N[0]),
         .rx_in_p(QSFP1_RX_P[0]),
         .rec_clk_out(evrClk),
         .rx_par_data_out(evr_mgt_par_data),
         .chariscomma(evr_mgt_chariscomma),
         .notintable(evr_notintable),
         .charisk(evr_mgt_charisk),
         .reset_done(evr_mgt_reset_done));

// Announce that receiver clock is locked only when all
// characters have been valid 8b/10b codes for a while.
(* mark_debug = EVR_DEBUG *) reg       evrRxLocked = 0;
                             reg [3:0] evrGoodCount = 0;
always @(posedge evrClk) begin
    if (|evr_notintable) begin
        evrRxLocked <= 0;
        evrGoodCount <= 0;
    end
    else if (evrGoodCount == 15) begin
        evrRxLocked <= 1;
    end
    else begin
        evrGoodCount <= evrGoodCount + 1;
    end
end

//////////////////////////////////////////////////////////////////////////////
// Event stream logger
evrLogger #(.ADDR_WIDTH(8))
  evrLogger (
    .sysClk(sysClk),
    .sysCsrStrobe(GPIO_STROBES[GPIO_IDX_EVENT_LOG_CSR]),
    .sysGpioOut(GPIO_OUT),
    .sysCsr(GPIO_IN[GPIO_IDX_EVENT_LOG_CSR]),
    .sysDataTicks(GPIO_IN[GPIO_IDX_EVENT_LOG_TICKS]),
    .evrClk(evrClk),
    .evrTVALID(!evr_mgt_charisk[0]),
    .evrTDATA(evr_mgt_par_data[7:0]));

//////////////////////////////////////////////////////////////////////////////
// Aurora streams

// BPM CCW link
wire        BPM_CCW_AXI_STREAM_RX_tlast, BPM_CCW_AXI_STREAM_RX_tvalid;
wire [31:0] BPM_CCW_AXI_STREAM_RX_tdata;
wire        BPM_CCW_AuroraCoreStatus_channel_up;
wire        BPM_CCW_AuroraCoreStatus_crc_pass_fail;
wire        BPM_CCW_AuroraCoreStatus_crc_valid;
wire        BPM_CCW_AuroraCoreStatus_frame_err;
wire        BPM_CCW_AuroraCoreStatus_hard_err;
wire        BPM_CCW_AuroraCoreStatus_lane_up;
wire        BPM_CCW_AuroraCoreStatus_rx_resetdone_out;
wire        BPM_CCW_AuroraCoreStatus_soft_err;
wire        BPM_CCW_AuroraCoreStatus_tx_lock;
wire        BPM_CCW_AuroraCoreStatus_tx_resetdone_out;

// BPM CW link
wire        BPM_CW_AXI_STREAM_RX_tlast, BPM_CW_AXI_STREAM_RX_tvalid;
wire [31:0] BPM_CW_AXI_STREAM_RX_tdata;
wire        BPM_CW_AuroraCoreStatus_channel_up;
wire        BPM_CW_AuroraCoreStatus_crc_pass_fail;
wire        BPM_CW_AuroraCoreStatus_crc_valid;
wire        BPM_CW_AuroraCoreStatus_frame_err;
wire        BPM_CW_AuroraCoreStatus_hard_err;
wire        BPM_CW_AuroraCoreStatus_lane_up;
wire        BPM_CW_AuroraCoreStatus_rx_resetdone_out;
wire        BPM_CW_AuroraCoreStatus_soft_err;
wire        BPM_CW_AuroraCoreStatus_tx_lock;
wire        BPM_CW_AuroraCoreStatus_tx_resetdone_out;

// Cell CCW link
localparam CELL_AXI_DEBUG = "false";
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CCW_AXI_STREAM_TX_tvalid;
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CCW_AXI_STREAM_TX_tready;
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CCW_AXI_STREAM_TX_tlast;
(* mark_debug = CELL_AXI_DEBUG *) wire [31:0] CELL_CCW_AXI_STREAM_TX_tdata;
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CCW_AXI_STREAM_RX_tvalid;
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CCW_AXI_STREAM_RX_tlast;
(* mark_debug = CELL_AXI_DEBUG *) wire [31:0] CELL_CCW_AXI_STREAM_RX_tdata;
wire        CELL_CCW_AuroraCoreStatus_channel_up;
wire        CELL_CCW_AuroraCoreStatus_crc_pass_fail;
wire        CELL_CCW_AuroraCoreStatus_crc_valid;
wire        CELL_CCW_AuroraCoreStatus_frame_err;
wire        CELL_CCW_AuroraCoreStatus_hard_err;
wire        CELL_CCW_AuroraCoreStatus_lane_up;
wire        CELL_CCW_AuroraCoreStatus_rx_resetdone_out;
wire        CELL_CCW_AuroraCoreStatus_soft_err;
wire        CELL_CCW_AuroraCoreStatus_tx_lock;
wire        CELL_CCW_AuroraCoreStatus_tx_resetdone_out;

// Cell CW link
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CW_AXI_STREAM_TX_tvalid;
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CW_AXI_STREAM_TX_tready;
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CW_AXI_STREAM_TX_tlast;
(* mark_debug = CELL_AXI_DEBUG *) wire [31:0] CELL_CW_AXI_STREAM_TX_tdata;
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CW_AXI_STREAM_RX_tvalid;
(* mark_debug = CELL_AXI_DEBUG *) wire        CELL_CW_AXI_STREAM_RX_tlast;
(* mark_debug = CELL_AXI_DEBUG *) wire [31:0] CELL_CW_AXI_STREAM_RX_tdata;
wire        CELL_CW_AuroraCoreStatus_channel_up;
wire        CELL_CW_AuroraCoreStatus_crc_pass_fail;
wire        CELL_CW_AuroraCoreStatus_crc_valid;
wire        CELL_CW_AuroraCoreStatus_frame_err;
wire        CELL_CW_AuroraCoreStatus_hard_err;
wire        CELL_CW_AuroraCoreStatus_lane_up;
wire        CELL_CW_AuroraCoreStatus_rx_resetdone_out;
wire        CELL_CW_AuroraCoreStatus_soft_err;
wire        CELL_CW_AuroraCoreStatus_tx_lock;
wire        CELL_CW_AuroraCoreStatus_tx_resetdone_out;

//////////////////////////////////////////////////////////////////////////////
// Read and coalesce data from BPM links
wire [31:0] localBPMs_tdata;
wire        localBPMs_tvalid, localBPMs_tlast;
wire  [1:0] bpmCCWstatusCode,    bpmCWstatusCode;
wire        bpmCCWstatusStrobe,  bpmCWstatusStrobe;
wire  [2:0] sysCellStatusCode;
wire        sysCellStatusStrobe;

wire [111:0] localBPMvalues;      // Aurora user clock domain
wire         localBPMvaluesVALID; // Aurora user clock domain

wire [31:0] BRAM_BPM_SETPOINTS_WDATA;
wire [15:0] BRAM_BPM_SETPOINTS_ADDR;
wire        BRAM_BPM_SETPOINTS_WENABLE;
wire [31:0] BRAM_BPM_SETPOINTS_RDATA;

reg localFOFBcontrol = 0;
wire fofbEnabled;
always @(posedge sysClk) begin
    if (GPIO_STROBES[GPIO_IDX_FOFB_CSR]) localFOFBcontrol <= GPIO_OUT[0];
end
assign GPIO_IN[GPIO_IDX_FOFB_CSR] = {{29{1'b0}},
                               fofbEnabled, 1'b0, localFOFBcontrol};

readBPMlinks #(.faStrobeDebug("false"),
               .bpmSetpointDebug("false"),
               .ccwInDebug("false"),
               .cwInDebug("false"),
               .mergedDebug("false"),
               .outDebug("false"),
               .stateDebug("false"))
  readBPMlinks (
         .sysClk(sysClk),
         .sysCsrStrobe(GPIO_STROBES[GPIO_IDX_BPMLINKS_CSR]),
         .GPIO_OUT(GPIO_OUT),
         .sysCsr(GPIO_IN[GPIO_IDX_BPMLINKS_CSR]),
         .sysAdditionalStatus(GPIO_IN[GPIO_IDX_BPMLINKS_EXTRA_STATUS]),
         .sysRxBitmap(GPIO_IN[GPIO_IDX_BPM_RX_BITMAP]),
         .sysLocalFOFBenabled(localFOFBcontrol),
         .sysSetpointWriteData(BRAM_BPM_SETPOINTS_WDATA),
         .sysSetpointAddress(BRAM_BPM_SETPOINTS_ADDR),
         .sysSetpointWriteEnable(BRAM_BPM_SETPOINTS_WENABLE),
         .sysSetpointReadData(BRAM_BPM_SETPOINTS_RDATA),
         .auroraUserClk(auroraUserClk),
         .auroraFAstrobe(auroraFAstrobe),
         .BPM_CCW_AXI_STREAM_RX_tdata(BPM_CCW_AXI_STREAM_RX_tdata),
         .BPM_CCW_AXI_STREAM_RX_tvalid(BPM_CCW_AXI_STREAM_RX_tvalid),
         .BPM_CCW_AXI_STREAM_RX_tlast(BPM_CCW_AXI_STREAM_RX_tlast),
         .BPM_CCW_AXI_STREAM_RX_CRC_pass(BPM_CCW_AuroraCoreStatus_crc_pass_fail),
         .BPM_CCW_AXI_STREAM_RX_CRC_valid(BPM_CCW_AuroraCoreStatus_crc_valid),
         .CCWstatusStrobe(bpmCCWstatusStrobe),
         .CCWstatusCode(bpmCCWstatusCode),
         .BPM_CW_AXI_STREAM_RX_tdata(BPM_CW_AXI_STREAM_RX_tdata),
         .BPM_CW_AXI_STREAM_RX_tvalid(BPM_CW_AXI_STREAM_RX_tvalid),
         .BPM_CW_AXI_STREAM_RX_tlast(BPM_CW_AXI_STREAM_RX_tlast),
         .BPM_CW_AXI_STREAM_RX_CRC_pass(BPM_CW_AuroraCoreStatus_crc_pass_fail),
         .BPM_CW_AXI_STREAM_RX_CRC_valid(BPM_CW_AuroraCoreStatus_crc_valid),
         .CWstatusStrobe(bpmCWstatusStrobe),
         .CWstatusCode(bpmCWstatusCode),
         .mergedLinkTDATA(localBPMvalues),
         .mergedLinkTVALID(localBPMvaluesVALID),
         .localBPMs_tdata(localBPMs_tdata),
         .localBPMs_tvalid(localBPMs_tvalid),
         .localBPMs_tlast(localBPMs_tlast));

//////////////////////////////////////////////////////////////////////////////
// Forward incoming and local streams to next cell
// Pick up CSR values from fofbReadLinks since we don't have any CSR
wire auCCWcellInhibit, auCWcellInhibit;
wire auCCWcellStreamValid = CELL_CCW_AXI_STREAM_RX_tvalid && !auCCWcellInhibit;
wire auCWcellStreamValid  = CELL_CW_AXI_STREAM_RX_tvalid  && !auCWcellInhibit;
forwardCellLink #(.dbg("false")) forwardCCWcell (
       .auroraUserClk(auroraUserClk),
       .auroraFAstrobe(auroraFAstrobe),
       .cellLinkRxTVALID(auCCWcellStreamValid),
       .cellLinkRxTLAST(CELL_CCW_AXI_STREAM_RX_tlast),
       .cellLinkRxTDATA(CELL_CCW_AXI_STREAM_RX_tdata),
       .cellLinkRxCRCvalid(CELL_CCW_AuroraCoreStatus_crc_valid),
       .cellLinkRxCRCpass(CELL_CCW_AuroraCoreStatus_crc_pass_fail),
       .localRxTVALID(localBPMs_tvalid),
       .localRxTLAST(localBPMs_tlast),
       .localRxTDATA(localBPMs_tdata),
       .cellLinkTxTVALID(CELL_CW_AXI_STREAM_TX_tvalid),
       .cellLinkTxTLAST(CELL_CW_AXI_STREAM_TX_tlast),
       .cellLinkTxTDATA(CELL_CW_AXI_STREAM_TX_tdata));
forwardCellLink #(.dbg("false")) forwardCWcell (
       .auroraUserClk(auroraUserClk),
       .auroraFAstrobe(auroraFAstrobe),
       .cellLinkRxTVALID(auCWcellStreamValid),
       .cellLinkRxTLAST(CELL_CW_AXI_STREAM_RX_tlast),
       .cellLinkRxTDATA(CELL_CW_AXI_STREAM_RX_tdata),
       .cellLinkRxCRCvalid(CELL_CW_AuroraCoreStatus_crc_valid),
       .cellLinkRxCRCpass(CELL_CW_AuroraCoreStatus_crc_pass_fail),
       .localRxTVALID(localBPMs_tvalid),
       .localRxTLAST(localBPMs_tlast),
       .localRxTDATA(localBPMs_tdata),
       .cellLinkTxTVALID(CELL_CCW_AXI_STREAM_TX_tvalid),
       .cellLinkTxTLAST(CELL_CCW_AXI_STREAM_TX_tlast),
       .cellLinkTxTDATA(CELL_CCW_AXI_STREAM_TX_tdata));

//////////////////////////////////////////////////////////////////////////////
// Gather data from outgoing streams and make available to fast orbit feedback
wire        sysTimeoutStrobe;
wire [31:0] fofbReadoutCSR, fofbDSPreadoutS, fofbDSPreadoutY, fofbDSPreadoutX;
wire [GPIO_FOFB_MATRIX_ADDR_WIDTH-1:0] fofbDSPreadoutAddress;
assign GPIO_IN[GPIO_IDX_CELL_COMM_CSR] = fofbReadoutCSR;
fofbReadLinks #(.SYSCLK_RATE(SYSCLK_RATE),
                .FOFB_INDEX_WIDTH(GPIO_FOFB_MATRIX_ADDR_WIDTH),
                .FAstrobeDebug("false"),
                .statusDebug("false"),
                .rawDataDebug("false"),
                .ccwLinkDebug("false"),
                .cwLinkDebug("false"),
                .cellCountDebug("false"),
                .dspReadoutDebug("false"))
  fofbReadLinks (
       .sysClk(sysClk),
       .csrStrobe(GPIO_STROBES[GPIO_IDX_CELL_COMM_CSR]),
       .GPIO_OUT(GPIO_OUT),
       .csr(fofbReadoutCSR),
       .rxBitmap(GPIO_IN[GPIO_IDX_CELL_RX_BITMAP]),
       .fofbEnableBitmap(GPIO_IN[GPIO_IDX_FOFB_ENABLE_BITMAP]),
       .fofbEnabled(fofbEnabled),

       .FAstrobe(sysFAstrobe),
       .auReset(auroraReset),
       .sysStatusStrobe(sysCellStatusStrobe),
       .sysStatusCode(sysCellStatusCode),
       .sysTimeoutStrobe(sysTimeoutStrobe),

       .fofbDSPreadoutAddress(fofbDSPreadoutAddress),
       .fofbDSPreadoutX(fofbDSPreadoutX),
       .fofbDSPreadoutY(fofbDSPreadoutY),
       .fofbDSPreadoutS(fofbDSPreadoutS),

       .uBreadoutStrobe(GPIO_STROBES[GPIO_IDX_BPM_READOUT_X]),
       .uBreadoutX(GPIO_IN[GPIO_IDX_BPM_READOUT_X]),
       .uBreadoutY(GPIO_IN[GPIO_IDX_BPM_READOUT_Y]),
       .uBreadoutS(GPIO_IN[GPIO_IDX_BPM_READOUT_S]),

       .auClk(auroraUserClk),
       .auFAstrobe(auroraFAstrobe),
       .auCCWcellInhibit(auCCWcellInhibit),
       .auCWcellInhibit(auCWcellInhibit),

       .auCellCCWlinkTVALID(CELL_CCW_AXI_STREAM_TX_tvalid),
       .auCellCCWlinkTLAST(CELL_CCW_AXI_STREAM_TX_tlast),
       .auCellCCWlinkTDATA(CELL_CCW_AXI_STREAM_TX_tdata),

       .auCellCWlinkTVALID(CELL_CW_AXI_STREAM_TX_tvalid),
       .auCellCWlinkTLAST(CELL_CW_AXI_STREAM_TX_tlast),
       .auCellCWlinkTDATA(CELL_CW_AXI_STREAM_TX_tdata));

//////////////////////////////////////////////////////////////////////////////
// Keep link reception statistics
linkStatistics #(.dbg("false")) linkStatistics (
         .auroraUserClk(auroraUserClk),
         .bpmCCWstatusStrobe(bpmCCWstatusStrobe),
         .bpmCCWstatusCode  (bpmCCWstatusCode),
         .bpmCWstatusStrobe (bpmCWstatusStrobe),
         .bpmCWstatusCode   (bpmCWstatusCode),
         .sysClk(sysClk),
         .sysStatusStrobe (sysCellStatusStrobe),
         .sysStatusCode   (sysCellStatusCode),
         .sysTimeoutStrobe(sysTimeoutStrobe),
         .sysCsrStrobe(GPIO_STROBES[GPIO_IDX_LINK_STATISTICS_CSR]),
         .GPIO_OUT(GPIO_OUT),
         .sysValue(GPIO_IN[GPIO_IDX_LINK_STATISTICS_CSR]));

//////////////////////////////////////////////////////////////////////////////
// Compute power supply settings
wire        FOFB_SETPOINT_AXIS_TVALID;
wire        FOFB_SETPOINT_AXIS_TLAST;
wire [31:0] FOFB_SETPOINT_AXIS_TDATA;
fofbDSP #(.RESULT_COUNT(GPIO_CHANNEL_COUNT),
          .FOFB_MATRIX_ADDR_WIDTH(GPIO_FOFB_MATRIX_ADDR_WIDTH),
          .MATMUL_DEBUG("false"),
          .FIR_DEBUG("false"),
          .TX_AXIS_DEBUG("false"))
  fofbDSP (
    .clk(sysClk),
    .csrStrobe(GPIO_STROBES[GPIO_IDX_DSP_CSR]),
    .GPIO_OUT(GPIO_OUT),
    .firStatus(GPIO_IN[GPIO_IDX_DSP_CSR]),
    .fofbReadoutCSR(fofbReadoutCSR),
    .fofbEnabled(fofbEnabled),
    .fofbDSPreadoutAddress(fofbDSPreadoutAddress),
    .fofbDSPreadoutX(fofbDSPreadoutX),
    .fofbDSPreadoutY(fofbDSPreadoutY),
    .fofbDSPreadoutS(fofbDSPreadoutS),
    .SETPOINT_TVALID(FOFB_SETPOINT_AXIS_TVALID),
    .SETPOINT_TLAST(FOFB_SETPOINT_AXIS_TLAST),
    .SETPOINT_TDATA(FOFB_SETPOINT_AXIS_TDATA));

//////////////////////////////////////////////////////////////////////////////
// Provide CPU read access to power supply setpoints
psSetpointMonitor #(.SETPOINT_COUNT(GPIO_CHANNEL_COUNT),
                    .DEBUG("false"))
  psSetpointMonitor (
    .clk(sysClk),
    .FOFB_SETPOINT_AXIS_TVALID(FOFB_SETPOINT_AXIS_TVALID),
    .FOFB_SETPOINT_AXIS_TLAST(FOFB_SETPOINT_AXIS_TLAST),
    .FOFB_SETPOINT_AXIS_TDATA(FOFB_SETPOINT_AXIS_TDATA),
    .addressStrobe(GPIO_STROBES[GPIO_IDX_FOFB_PS_SETPOINT]),
    .GPIO_OUT(GPIO_OUT),
    .psSetpoint(GPIO_IN[GPIO_IDX_FOFB_PS_SETPOINT]),
    .status(GPIO_IN[GPIO_IDX_FOFB_PS_SETPOINT_STATUS]));

//////////////////////////////////////////////////////////////////////////////
// Arbitrary Waveform Generator
wire [31:0] AWG_AXIS_TDATA;
wire        AWG_AXIS_TVALID, AWG_AXIS_TLAST;
wire        AWGrequest, AWGenabled;

psAWG #(.SETPOINT_COUNT(GPIO_CHANNEL_COUNT),
        .DATA_WIDTH(32),
        .ADDR_WIDTH($clog2(GPIO_AWG_CAPACITY)),
        .SYSCLK_RATE(SYSCLK_RATE),
        .DEBUG("false"))
  psAWG (.sysClk(sysClk),
         .csrStrobe(GPIO_STROBES[GPIO_IDX_AWG_CSR]),
         .addrStrobe(GPIO_STROBES[GPIO_IDX_AWG_ADDRESS]),
         .dataStrobe(GPIO_STROBES[GPIO_IDX_AWG_DATA]),
         .GPIO_OUT(GPIO_OUT),
         .status(GPIO_IN[GPIO_IDX_AWG_CSR]),
         .evrTrigger(evrTriggerBus[2]),
         .sysFAstrobe(sysFAstrobe),
         .AWGrequest(AWGrequest),
         .AWGenabled(AWGenabled),
         .awgTDATA(AWG_AXIS_TDATA),
         .awgTVALID(AWG_AXIS_TVALID),
         .awgTLAST(AWG_AXIS_TLAST));

//////////////////////////////////////////////////////////////////////////////
// Multiplex fast feedback and arbitrary waveform streams
wire [31:0] PS_SETPOINT_AXIS_TDATA;
wire        PS_SETPOINT_AXIS_TVALID, PS_SETPOINT_AXIS_TLAST;
wire [31:0] PS_READBACK_AXIS_TDATA;
wire  [7:0] PS_READBACK_AXIS_TUSER;
wire        PS_READBACK_AXIS_TVALID;


psMUX #(.DEBUG("false"),
        .AXI_WIDTH(32))
  psMUX (.clk(sysClk),
         .AWGrequest(AWGrequest),
         .AWGenabled(AWGenabled),
         .fofbTDATA(FOFB_SETPOINT_AXIS_TDATA),
         .fofbTVALID(FOFB_SETPOINT_AXIS_TVALID),
         .fofbTLAST(FOFB_SETPOINT_AXIS_TLAST),
         .awgTDATA(AWG_AXIS_TDATA),
         .awgTVALID(AWG_AXIS_TVALID),
         .awgTLAST(AWG_AXIS_TLAST),
         .psTDATA(PS_SETPOINT_AXIS_TDATA),
         .psTVALID(PS_SETPOINT_AXIS_TVALID),
         .psTLAST(PS_SETPOINT_AXIS_TLAST));

//////////////////////////////////////////////////////////////////////////////
// Ethernet in fabric connection to fast orbit feedback power supplies
// Destination MAC address is as specified in RFC 1112 and RFC 7042:
//               01:00:5E followed by low 23 bits of IPv4 multicast address.
//               IPv4 multicast address is that of the current FastPS firmware:
//                                                                   224.0.2.22.
wire [9:0] pcs_pma_shared;
wire [63:0] ethNonce;
assign  ethRefClk125 = pcs_pma_shared[9];
fofbEthernet #(
    .MAX_CORRECTOR_COUNT(GPIO_CHANNEL_COUNT),
    .PCS_PMA_SHARED_LOGIC_IN_CORE("true"),
    .SRC_IP_ADDRESS({8'd192, 8'd168, 8'd30, 8'd251}),
    .SRC_MAC_ADDRESS({8'h2A,8'h4C,8'h42,8'h4E,8'h4C,8'h32}),
    .DST_MAC_ADDRESS({8'h01, 8'h00, 8'h5E, 8'd0, 8'd2, 8'd22}),
    .DST_IP_ADDRESS(              {8'd224, 8'd0, 8'd2, 8'd22}),
    .TX_DEBUG("false"),
    .RX_DEBUG("false"))
  psTx (
    .sysClk(sysClk),
    .sysGpioOut(GPIO_OUT),
    .sysCsrStrobe(GPIO_STROBES[GPIO_IDX_ETHERNET0_CSR]),
    .sysCsr(GPIO_IN[GPIO_IDX_ETHERNET0_CSR]),
    .sysTx_S_AXIS_TDATA(PS_SETPOINT_AXIS_TDATA),
    .sysTx_S_AXIS_TVALID(PS_SETPOINT_AXIS_TVALID),
    .sysTx_S_AXIS_TLAST(PS_SETPOINT_AXIS_TLAST),
    .pcs_pma_shared(pcs_pma_shared),
    .ethNonce(ethNonce),
    .clk200(clk200),
    .ETH_REF_N(GTX_REF_125_N),
    .ETH_REF_P(GTX_REF_125_P),
    .ETH_RX_N(QSFP2_RX_N[2]),
    .ETH_RX_P(QSFP2_RX_P[2]),
    .ETH_TX_N(QSFP2_TX_N[2]),
    .ETH_TX_P(QSFP2_TX_P[2]));

fofbEthernet #(
    .MAX_CORRECTOR_COUNT(GPIO_CHANNEL_COUNT),
    .SRC_IP_ADDRESS({8'd192, 8'd168, 8'd30, 8'd250}),
    .SRC_MAC_ADDRESS({8'h2A,8'h4C,8'h42,8'h4E,8'h4C,8'h33}),
    .DST_IP_ADDRESS({8'd255, 8'd255, 8'd255, 8'd255}),
    .DST_MAC_ADDRESS({8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF}),
    .TX_DEBUG("false"),
    .RX_DEBUG("false"))
  psRx (
    .sysClk(sysClk),
    .sysGpioOut(GPIO_OUT),
    .sysCsrStrobe(GPIO_STROBES[GPIO_IDX_ETHERNET1_CSR]),
    .sysCsr(GPIO_IN[GPIO_IDX_ETHERNET1_CSR]),
    .sysTx_S_AXIS_TDATA(32'h0),
    .sysTx_S_AXIS_TVALID(1'b0),
    .sysTx_S_AXIS_TLAST(1'b0),
    .sysRx_M_AXIS_TDATA(PS_READBACK_AXIS_TDATA),
    .sysRx_M_AXIS_TUSER(PS_READBACK_AXIS_TUSER),
    .sysRx_M_AXIS_TVALID(PS_READBACK_AXIS_TVALID),
    .pcs_pma_shared(pcs_pma_shared),
    .ethNonce(ethNonce),
    .clk200(clk200),
    .ETH_REF_N(GTX_REF_125_N),
    .ETH_REF_P(GTX_REF_125_P),
    .ETH_RX_N(QSFP2_RX_N[3]),
    .ETH_RX_P(QSFP2_RX_P[3]),
    .ETH_TX_N(QSFP2_TX_N[3]),
    .ETH_TX_P(QSFP2_TX_P[3]));

//////////////////////////////////////////////////////////////////////////////
// Fast orbit feedback waveform recorder
fofbRecorder #(.BUFFER_CAPACITY(GPIO_RECORDER_CAPACITY),
               .CHANNEL_COUNT(GPIO_CHANNEL_COUNT),
               .DEBUG("false"))
  fofbRecorder (
    .clk(sysClk),
    .GPIO_OUT(GPIO_OUT),
    .csrStrobe(GPIO_STROBES[GPIO_IDX_WFR_CSR]),
    .pretriggerInitStrobe(GPIO_STROBES[GPIO_IDX_WFR_W_PRETRIGGER]),
    .posttriggerInitStrobe(GPIO_STROBES[GPIO_IDX_WFR_W_POSTTRIGGER]),
    .channelMapStrobe(GPIO_STROBES[GPIO_IDX_WFR_W_CHANNEL_BITMAP]),
    .addressStrobe(GPIO_STROBES[GPIO_IDX_WFR_ADDRESS]),
    .timestamp(sysTimestamp),
    .status(GPIO_IN[GPIO_IDX_WFR_CSR]),
    .triggerAddress(GPIO_IN[GPIO_IDX_WFR_ADDRESS]),
    .txData(GPIO_IN[GPIO_IDX_WFR_R_TX_DATA]),
    .rxData(GPIO_IN[GPIO_IDX_WFR_R_RX_DATA]),
    .acqTimestamp({GPIO_IN[GPIO_IDX_WFR_R_SECONDS],
                   GPIO_IN[GPIO_IDX_WFR_R_TICKS]}),
    .evrTrigger(evrTriggerBus[3]),
    .awgRunning(GPIO_IN[GPIO_IDX_AWG_CSR][29]),
    .tx_S_AXIS_TVALID(PS_SETPOINT_AXIS_TVALID),
    .tx_S_AXIS_TDATA(PS_SETPOINT_AXIS_TDATA),
    .tx_S_AXIS_TLAST(PS_SETPOINT_AXIS_TLAST),
    .rx_S_AXIS_TVALID(PS_READBACK_AXIS_TVALID),
    .rx_S_AXIS_TDATA(PS_READBACK_AXIS_TDATA),
    .rx_S_AXIS_TUSER(PS_READBACK_AXIS_TUSER));

//////////////////////////////////////////////////////////////////////////////
// Errant Electron Beam Interlock
eebi #(.SYSCLK_RATE(SYSCLK_RATE), .dbg("false")) eebi (
            .sysClk(sysClk),
            .sysCsrStrobe(GPIO_STROBES[GPIO_IDX_EEBI_CSR]),
            .sysCsrWriteData(GPIO_OUT),
            .sysCsr(GPIO_IN[GPIO_IDX_EEBI_CSR]),
            .sysTimestamp(sysTimestamp),
            .sysMostRecentFaultTime({GPIO_IN[GPIO_IDX_EEBI_FAULT_TIME_SECONDS],
                                     GPIO_IN[GPIO_IDX_EEBI_FAULT_TIME_TICKS]}),
            .auroraUserClk(auroraUserClk),
            .auroraFAstrobe(auroraFAstrobe),
            .localBPMvalues(localBPMvalues),
            .localBPMvaluesVALID(localBPMvaluesVALID),
            .eebiRelay(INTLK_RELAY_CTL),
            .eebiResetButton_n(INTLK_RESET_BUTTON_N));

//////////////////////////////////////////////////////////////////////////////
// Convert value from integer nm to double precision mm
errorConvert errorConvert (
          .clk(sysClk),
          .writeStrobe(GPIO_STROBES[GPIO_IDX_ERROR_CONVERT_WDATA]),
          .writeData(GPIO_OUT),
          .csrStrobe(GPIO_STROBES[GPIO_IDX_ERROR_CONVERT_CSR]),
          .status(GPIO_IN[GPIO_IDX_ERROR_CONVERT_CSR]),
          .resultHi(GPIO_IN[GPIO_IDX_ERROR_CONVERT_RDATA_HI]),
          .resultLo(GPIO_IN[GPIO_IDX_ERROR_CONVERT_RDATA_LO]));

/////////////////////////////////////////////////////////////////////////////
// Pilot tone reference
wire pilotToneReference;
OBUFDS pilotToneRefBuf(.I(pilotToneReference),
                    .O(PILOT_TONE_REFCLK_P), .OB(PILOT_TONE_REFCLK_N));

pilotToneReference # (
    .DIRECT_OUTPUT_ENABLE(PILOT_TONE_REFERENCE_DIRECT_OUTPUT_ENABLE),
    .DEBUG("false"))
  pilotToneRef(
    .sysClk(sysClk),
    .csrStrobe(GPIO_STROBES[GPIO_IDX_PILOT_TONE_REFERENCE]),
    .GPIO_OUT(GPIO_OUT),
    .csr(GPIO_IN[GPIO_IDX_PILOT_TONE_REFERENCE]),
    .evrClk(evrClk),
    .pilotToneReference(pilotToneReference));

/////////////////////////////////////////////////////////////////////////////
// Pilot tone generator (and errant electron beam interlock)
wire PILOT_TONE_I2C_SCL_o, PILOT_TONE_I2C_SCL_t;
wire PILOT_TONE_I2C_SDA_o, PILOT_TONE_I2C_SDA_t;
pilotToneI2C #(.dbg("false"),
               .SYSCLK_FREQUENCY(SYSCLK_RATE),
               .I2C_RATE(100000))
            pilotToneI2C (.clk(sysClk),
                          .writeData(GPIO_OUT),
                          .writeStrobe(GPIO_STROBES[GPIO_IDX_PILOT_TONE_I2C]),
                          .status(GPIO_IN[GPIO_IDX_PILOT_TONE_I2C]),
                          .SCL_BUF_o(PILOT_TONE_I2C_SCL_o),
                          .SCL_BUF_t(PILOT_TONE_I2C_SCL_t),
                          .SDA_BUF_o(PILOT_TONE_I2C_SDA_o),
                          .SDA_BUF_t(PILOT_TONE_I2C_SDA_t));
IOBUF IOBUF_PILOT_TONE_SCL(.O(PILOT_TONE_I2C_SCL_o),
                           .T(1'b0),
                           .I(PILOT_TONE_I2C_SCL_t),
                           .IO(PILOT_TONE_I2C_SCL));
IOBUF IOBUF_PILOT_TONE_SDA(.O(PILOT_TONE_I2C_SDA_o),
                           .T(PILOT_TONE_I2C_SDA_t),
                           .I(1'b0),
                           .IO(PILOT_TONE_I2C_SDA));
assign GPIO_IN[GPIO_IDX_PILOT_TONE_CSR] = { 16'b0,
                                ~INTLK_RELAY_NO,
                                {16-1{1'b0}} };

/////////////////////////////////////////////////////////////////////////////
// Frequency counters
reg   [2:0] frequencyMonitorSelect;
wire [29:0] measuredFrequency;
always @(posedge sysClk) begin
    if (GPIO_STROBES[GPIO_IDX_FREQUENCY_MONITOR_CSR])
                                        frequencyMonitorSelect <= GPIO_OUT[2:0];
end
assign GPIO_IN[GPIO_IDX_FREQUENCY_MONITOR_CSR] = { 2'b0, measuredFrequency };
wire auRefClk;
freq_multi_count #(
        .NF(5),  // number of frequency counters in a block
        .NG(1),  // number of frequency counter blocks
        .gw(4),  // Gray counter width
        .cw(1),  // macro-cycle counter width
        .rw($clog2(SYSCLK_RATE*4/3)), // reference counter width
        .uw(30)) // unknown counter width
  frequencyCounters(
    .unk_clk({auRefClk, ethRefClk125, auroraUserClk, evrClk, sysClk}),
    .refclk(sysClk),
    .refMarker(evrTriggerBus[1]),  // 1 PPS marker from event system
    .addr(frequencyMonitorSelect),
    .frequency(measuredFrequency));

/////////////////////////////////////////////////////////////////////////////
// Front panel
assign FP_LED0_GRN = evrTriggerBus[0];
assign FP_LED0_RED = 1'b0;
wire FP_LED1_STATE_RED, FP_LED1_STATE_YELLOW, FP_LED1_STATE_GREEN;
assign FP_LED1_STATE_RED = !CELL_CCW_AuroraCoreStatus_channel_up
                        && !CELL_CW_AuroraCoreStatus_channel_up;
assign FP_LED1_STATE_GREEN = CELL_CCW_AuroraCoreStatus_channel_up
                          && CELL_CW_AuroraCoreStatus_channel_up;
assign FP_LED1_STATE_YELLOW = !FP_LED1_STATE_RED && !FP_LED1_STATE_GREEN;
assign FP_LED1_GRN = FP_LED1_STATE_YELLOW || FP_LED1_STATE_GREEN;
assign FP_LED1_RED = FP_LED1_STATE_YELLOW || FP_LED1_STATE_RED;
wire FP_LED2_STATE_RED, FP_LED2_STATE_YELLOW, FP_LED2_STATE_GREEN;
assign FP_LED2_STATE_RED = !BPM_CCW_AuroraCoreStatus_channel_up
                        && !BPM_CW_AuroraCoreStatus_channel_up;
assign FP_LED2_STATE_GREEN = BPM_CCW_AuroraCoreStatus_channel_up
                          && BPM_CW_AuroraCoreStatus_channel_up;
assign FP_LED2_STATE_YELLOW = !FP_LED2_STATE_RED && !FP_LED2_STATE_GREEN;
assign FP_LED2_GRN = FP_LED2_STATE_YELLOW || FP_LED2_STATE_GREEN;
assign FP_LED2_RED = FP_LED2_STATE_YELLOW || FP_LED2_STATE_RED;

/////////////////////////////////////////////////////////////////////////////
// BMB7 Kintex indicator LEDs
// { 1_Blue, 1_Green, 1_Red, 0_Blue, 0_Green, 0_Red }
assign kintexLEDs = ~{ 1'b0,
                       1'b0,
                       1'b0,
                       evrTriggerBus[0],
                       1'b0,
                       1'b0 };

/////////////////////////////////////////////////////////////////////////////
// Miscellaneous
`include "firmwareBuildDate.v"
assign GPIO_IN[GPIO_IDX_FIRMWARE_BUILD_DATE] = FIRMWARE_BUILD_DATE;

/////////////////////////////////////////////////////////////////////////////
// FIFO/UART console I/O
fifoUART #(.CLK_RATE(SYSCLK_RATE),
           .BIT_RATE(115200)) fifoUART (
                   .clk(sysClk),
                   .strobe(GPIO_STROBES[GPIO_IDX_UART_CSR]),
                   .control(GPIO_OUT),
                   .status(GPIO_IN[GPIO_IDX_UART_CSR]),
                   .TxData(Uart_TxD),
                   .RxData(Uart_RxD));

`ifndef SIMULATE
//////////////////////////////////////////////////////////////////////////////
// Block design (MicroBlaze)

wire DUMMY_UART_LOOPBACK;

  system system_i (
        .S6_TO_K7_CLK_1(S6_TO_K7_CLK_1),
        .sysClk(sysClk),
        .clk200(clk200),
        .sysReset_n(sysReset_n),

        .auroraUserClk(auroraUserClk),
        .gt0_qplllock_out(gt0_qplllock_out),
        .gt0_qpllrefclklost_out(gt0_qpllrefclklost_out),
        .pll_not_locked_out(pll_not_locked_out),
        .auroraReset(auroraReset),
        .gtxReset(sysGTXreset),
        .gtxResetOut(gtxResetOut),

        .GT_DIFF_REFCLK_312_3_clk_n(GTX_REF_312_3_N),
        .GT_DIFF_REFCLK_312_3_clk_p(GTX_REF_312_3_P),
        .auroraRefClk(auRefClk),

        .BPM_CCW_AXI_STREAM_RX_tdata(BPM_CCW_AXI_STREAM_RX_tdata),
        .BPM_CCW_AXI_STREAM_RX_tlast(BPM_CCW_AXI_STREAM_RX_tlast),
        .BPM_CCW_AXI_STREAM_RX_tvalid(BPM_CCW_AXI_STREAM_RX_tvalid),
        .BPM_CCW_AuroraCoreStatus_channel_up(BPM_CCW_AuroraCoreStatus_channel_up),
        .BPM_CCW_AuroraCoreStatus_crc_pass_fail(BPM_CCW_AuroraCoreStatus_crc_pass_fail),
        .BPM_CCW_AuroraCoreStatus_crc_valid(BPM_CCW_AuroraCoreStatus_crc_valid),
        .BPM_CCW_AuroraCoreStatus_frame_err(BPM_CCW_AuroraCoreStatus_frame_err),
        .BPM_CCW_AuroraCoreStatus_hard_err(BPM_CCW_AuroraCoreStatus_hard_err),
        .BPM_CCW_AuroraCoreStatus_lane_up(BPM_CCW_AuroraCoreStatus_lane_up),
        .BPM_CCW_AuroraCoreStatus_rx_resetdone_out(BPM_CCW_AuroraCoreStatus_rx_resetdone_out),
        .BPM_CCW_AuroraCoreStatus_soft_err(BPM_CCW_AuroraCoreStatus_soft_err),
        .BPM_CCW_AuroraCoreStatus_tx_lock(BPM_CCW_AuroraCoreStatus_tx_lock),
        .BPM_CCW_AuroraCoreStatus_tx_resetdone_out(BPM_CCW_AuroraCoreStatus_tx_resetdone_out),
        .BPM_CCW_GT_RX_rxn(QSFP1_RX_N[1]),
        .BPM_CCW_GT_RX_rxp(QSFP1_RX_P[1]),
        .BPM_CCW_GT_TX_txn(QSFP1_TX_N[1]),
        .BPM_CCW_GT_TX_txp(QSFP1_TX_P[1]),

        .BPM_CW_AXI_STREAM_RX_tdata(BPM_CW_AXI_STREAM_RX_tdata),
        .BPM_CW_AXI_STREAM_RX_tlast(BPM_CW_AXI_STREAM_RX_tlast),
        .BPM_CW_AXI_STREAM_RX_tvalid(BPM_CW_AXI_STREAM_RX_tvalid),
        .BPM_CW_AuroraCoreStatus_channel_up(BPM_CW_AuroraCoreStatus_channel_up),
        .BPM_CW_AuroraCoreStatus_crc_pass_fail(BPM_CW_AuroraCoreStatus_crc_pass_fail),
        .BPM_CW_AuroraCoreStatus_crc_valid(BPM_CW_AuroraCoreStatus_crc_valid),
        .BPM_CW_AuroraCoreStatus_frame_err(BPM_CW_AuroraCoreStatus_frame_err),
        .BPM_CW_AuroraCoreStatus_hard_err(BPM_CW_AuroraCoreStatus_hard_err),
        .BPM_CW_AuroraCoreStatus_lane_up(BPM_CW_AuroraCoreStatus_lane_up),
        .BPM_CW_AuroraCoreStatus_rx_resetdone_out(BPM_CW_AuroraCoreStatus_rx_resetdone_out),
        .BPM_CW_AuroraCoreStatus_soft_err(BPM_CW_AuroraCoreStatus_soft_err),
        .BPM_CW_AuroraCoreStatus_tx_lock(BPM_CW_AuroraCoreStatus_tx_lock),
        .BPM_CW_AuroraCoreStatus_tx_resetdone_out(BPM_CW_AuroraCoreStatus_tx_resetdone_out),
        .BPM_CW_GT_RX_rxn(QSFP1_RX_N[2]),
        .BPM_CW_GT_RX_rxp(QSFP1_RX_P[2]),
        .BPM_CW_GT_TX_txn(QSFP1_TX_N[2]),
        .BPM_CW_GT_TX_txp(QSFP1_TX_P[2]),

        .CELL_CCW_AXI_STREAM_TX_tdata(CELL_CCW_AXI_STREAM_TX_tdata),
        .CELL_CCW_AXI_STREAM_TX_tlast(CELL_CCW_AXI_STREAM_TX_tlast),
        .CELL_CCW_AXI_STREAM_TX_tvalid(CELL_CCW_AXI_STREAM_TX_tvalid),
        .CELL_CCW_AXI_STREAM_TX_tready(CELL_CCW_AXI_STREAM_TX_tready),
        .CELL_CCW_AXI_STREAM_RX_tdata(CELL_CCW_AXI_STREAM_RX_tdata),
        .CELL_CCW_AXI_STREAM_RX_tlast(CELL_CCW_AXI_STREAM_RX_tlast),
        .CELL_CCW_AXI_STREAM_RX_tvalid(CELL_CCW_AXI_STREAM_RX_tvalid),
        .CELL_CCW_AuroraCoreStatus_channel_up(CELL_CCW_AuroraCoreStatus_channel_up),
        .CELL_CCW_AuroraCoreStatus_crc_pass_fail(CELL_CCW_AuroraCoreStatus_crc_pass_fail),
        .CELL_CCW_AuroraCoreStatus_crc_valid(CELL_CCW_AuroraCoreStatus_crc_valid),
        .CELL_CCW_AuroraCoreStatus_frame_err(CELL_CCW_AuroraCoreStatus_frame_err),
        .CELL_CCW_AuroraCoreStatus_hard_err(CELL_CCW_AuroraCoreStatus_hard_err),
        .CELL_CCW_AuroraCoreStatus_lane_up(CELL_CCW_AuroraCoreStatus_lane_up),
        .CELL_CCW_AuroraCoreStatus_rx_resetdone_out(CELL_CCW_AuroraCoreStatus_rx_resetdone_out),
        .CELL_CCW_AuroraCoreStatus_soft_err(CELL_CCW_AuroraCoreStatus_soft_err),
        .CELL_CCW_AuroraCoreStatus_tx_lock(CELL_CCW_AuroraCoreStatus_tx_lock),
        .CELL_CCW_AuroraCoreStatus_tx_resetdone_out(CELL_CCW_AuroraCoreStatus_tx_resetdone_out),
        .CELL_CCW_GT_RX_rxn(QSFP2_RX_N[0]),
        .CELL_CCW_GT_RX_rxp(QSFP2_RX_P[0]),
        .CELL_CCW_GT_TX_txn(QSFP2_TX_N[0]),
        .CELL_CCW_GT_TX_txp(QSFP2_TX_P[0]),

        .CELL_CW_AXI_STREAM_TX_tdata(CELL_CW_AXI_STREAM_TX_tdata),
        .CELL_CW_AXI_STREAM_TX_tlast(CELL_CW_AXI_STREAM_TX_tlast),
        .CELL_CW_AXI_STREAM_TX_tvalid(CELL_CW_AXI_STREAM_TX_tvalid),
        .CELL_CW_AXI_STREAM_TX_tready(CELL_CW_AXI_STREAM_TX_tready),
        .CELL_CW_AXI_STREAM_RX_tdata(CELL_CW_AXI_STREAM_RX_tdata),
        .CELL_CW_AXI_STREAM_RX_tlast(CELL_CW_AXI_STREAM_RX_tlast),
        .CELL_CW_AXI_STREAM_RX_tvalid(CELL_CW_AXI_STREAM_RX_tvalid),
        .CELL_CW_AuroraCoreStatus_channel_up(CELL_CW_AuroraCoreStatus_channel_up),
        .CELL_CW_AuroraCoreStatus_crc_pass_fail(CELL_CW_AuroraCoreStatus_crc_pass_fail),
        .CELL_CW_AuroraCoreStatus_crc_valid(CELL_CW_AuroraCoreStatus_crc_valid),
        .CELL_CW_AuroraCoreStatus_frame_err(CELL_CW_AuroraCoreStatus_frame_err),
        .CELL_CW_AuroraCoreStatus_hard_err(CELL_CW_AuroraCoreStatus_hard_err),
        .CELL_CW_AuroraCoreStatus_lane_up(CELL_CW_AuroraCoreStatus_lane_up),
        .CELL_CW_AuroraCoreStatus_rx_resetdone_out(CELL_CW_AuroraCoreStatus_rx_resetdone_out),
        .CELL_CW_AuroraCoreStatus_soft_err(CELL_CW_AuroraCoreStatus_soft_err),
        .CELL_CW_AuroraCoreStatus_tx_lock(CELL_CW_AuroraCoreStatus_tx_lock),
        .CELL_CW_AuroraCoreStatus_tx_resetdone_out(CELL_CW_AuroraCoreStatus_tx_resetdone_out),
        .CELL_CW_GT_RX_rxn(QSFP2_RX_N[1]),
        .CELL_CW_GT_RX_rxp(QSFP2_RX_P[1]),
        .CELL_CW_GT_TX_txn(QSFP2_TX_N[1]),
        .CELL_CW_GT_TX_txp(QSFP2_TX_P[1]),

        .evr_mgt_rec_clk(evrClk),
        .evr_mgt_par_data(evr_mgt_par_data & {16{evrRxLocked}}),
        .evr_mgt_chariscomma(evr_mgt_chariscomma),
        .evr_mgt_charisk(evr_mgt_charisk),
        .evr_mgt_reset_done(evr_mgt_reset_done),
        .evrTriggerBus(evrTriggerBus),
        .evrDataBus(evrDataBus),
        .evrTimestamp(evrTimestamp),
        .evr_mgt_drp_daddr(evr_mgt_drp_daddr),
        .evr_mgt_drp_den(evr_mgt_drp_den),
        .evr_mgt_drp_di(evr_mgt_drp_di),
        .evr_mgt_drp_do(evr_mgt_drp_do),
        .evr_mgt_drp_drdy(evr_mgt_drp_drdy),
        .evr_mgt_drp_dwe(evr_mgt_drp_dwe),

        .epicsUDPrxData(epicsUDPrxData),
        .epicsUDPtxData(epicsUDPtxData),

        .BRAM_BPM_SETPOINTS_ADDR(BRAM_BPM_SETPOINTS_ADDR),
        .BRAM_BPM_SETPOINTS_WDATA(BRAM_BPM_SETPOINTS_WDATA),
        .BRAM_BPM_SETPOINTS_WENABLE(BRAM_BPM_SETPOINTS_WENABLE),
        .BRAM_BPM_SETPOINTS_RDATA(BRAM_BPM_SETPOINTS_RDATA),

        // Dummy UART to keep SDK tools happy
        .uart_rtl_rxd(DUMMY_UART_LOOPBACK),
        .uart_rtl_txd(DUMMY_UART_LOOPBACK),

        .GPIO_IN(GPIO_IN_FLATTENED),
        .GPIO_OUT(GPIO_OUT),
        .GPIO_STROBES(GPIO_STROBES));
`endif // `ifndef SIMULATE

endmodule
