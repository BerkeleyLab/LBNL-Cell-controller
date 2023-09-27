module cctrl_verilator_top #(
  parameter SYSCLK_RATE = 100_000_000
  )(
  input         clkIn125, // 125 MHz
  input         evrClk,   // ???
  input         sysClk,   // 100 Mhz
  input         auroraUserClk, // 125 MHz?

  // Stream packet MUX input
  input         stream_mux_strobe,
  input   [1:0] stream_mux_sel,
  input  [31:0] stream_in_header,
  input  [31:0] stream_in_datax,
  input  [31:0] stream_in_datay,
  input  [31:0] stream_in_datas,

  // Stream packet MUX input
  output        stream_mux_valid,
  output  [1:0] stream_mux_src,
  output [31:0] stream_out_header,
  output [31:0] stream_out_datax,
  output [31:0] stream_out_datay,
  output [31:0] stream_out_datas,

  // Expose this interface to Verilator for simulated cpu
  input  [31:0] GPIO_OUT,
  input  [63:0] GPIO_STROBES,
  //output [2047:0] GPIO_IN_FLATTENED,  // TODO I'm guessing Verilator won't like a 2048-bit number
  output [31:0] GPIO_IN0,
  output [31:0] GPIO_IN1,
  output [31:0] GPIO_IN2,
  output [31:0] GPIO_IN3,
  output [31:0] GPIO_IN4,
  output [31:0] GPIO_IN5,
  output [31:0] GPIO_IN6,
  output [31:0] GPIO_IN7,
  output [31:0] GPIO_IN8,
  output [31:0] GPIO_IN9,
  output [31:0] GPIO_IN10,
  output [31:0] GPIO_IN11,
  output [31:0] GPIO_IN12,
  output [31:0] GPIO_IN13,
  output [31:0] GPIO_IN14,
  output [31:0] GPIO_IN15,
  output [31:0] GPIO_IN16,
  output [31:0] GPIO_IN17,
  output [31:0] GPIO_IN18,
  output [31:0] GPIO_IN19,
  output [31:0] GPIO_IN20,
  output [31:0] GPIO_IN21,
  output [31:0] GPIO_IN22,
  output [31:0] GPIO_IN23,
  output [31:0] GPIO_IN24,
  output [31:0] GPIO_IN25,
  output [31:0] GPIO_IN26,
  output [31:0] GPIO_IN27,
  output [31:0] GPIO_IN28,
  output [31:0] GPIO_IN29,
  output [31:0] GPIO_IN30,
  output [31:0] GPIO_IN31,
  output [31:0] GPIO_IN32,
  output [31:0] GPIO_IN33,
  output [31:0] GPIO_IN34,
  output [31:0] GPIO_IN35,
  output [31:0] GPIO_IN36,
  output [31:0] GPIO_IN37,
  output [31:0] GPIO_IN38,
  output [31:0] GPIO_IN39,
  output [31:0] GPIO_IN40,
  output [31:0] GPIO_IN41,
  output [31:0] GPIO_IN42,
  output [31:0] GPIO_IN43,
  output [31:0] GPIO_IN44,
  output [31:0] GPIO_IN45,
  output [31:0] GPIO_IN46,
  output [31:0] GPIO_IN47,
  output [31:0] GPIO_IN48,
  output [31:0] GPIO_IN49,
  output [31:0] GPIO_IN50,
  output [31:0] GPIO_IN51,
  output [31:0] GPIO_IN52,
  output [31:0] GPIO_IN53,
  output [31:0] GPIO_IN54,
  output [31:0] GPIO_IN55,
  output [31:0] GPIO_IN56,
  output [31:0] GPIO_IN57,
  output [31:0] GPIO_IN58,
  output [31:0] GPIO_IN59,
  output [31:0] GPIO_IN60,
  output [31:0] GPIO_IN61,
  output [31:0] GPIO_IN62,
  output [31:0] GPIO_IN63,

  // Expose this interface to Verilator for simulated cpu
  // Add bridge layer to allow direct memory writes/reads to/from here.
  input  [31:0] BRAM_BPM_SETPOINTS_WDATA,
  input  [15:0] BRAM_BPM_SETPOINTS_ADDR,
  input         BRAM_BPM_SETPOINTS_WENABLE,
  output [31:0] BRAM_BPM_SETPOINTS_RDATA

);

// Cell CCW Stream OUT
wire [31:0] CELL_CCW_AXI_STREAM_TX_tdata;
wire        CELL_CCW_AXI_STREAM_TX_tlast;
wire        CELL_CCW_AXI_STREAM_TX_tvalid;

// Cell CCW Stream IN
wire  [31:0] CELL_CCW_AXI_STREAM_RX_tdata;
wire         CELL_CCW_AXI_STREAM_RX_tlast;
wire         CELL_CCW_AXI_STREAM_RX_tvalid;

// Cell CW Stream OUT
wire [31:0] CELL_CW_AXI_STREAM_TX_tdata;
wire        CELL_CW_AXI_STREAM_TX_tlast;
wire        CELL_CW_AXI_STREAM_TX_tvalid;

// Cell CW Stream IN
wire  [31:0] CELL_CW_AXI_STREAM_RX_tdata;
wire         CELL_CW_AXI_STREAM_RX_tlast;
wire         CELL_CW_AXI_STREAM_RX_tvalid;

// BPM CCW Stream IN
wire         BPM_CCW_AXI_STREAM_RX_tlast;
wire         BPM_CCW_AXI_STREAM_RX_tvalid;
wire  [31:0] BPM_CCW_AXI_STREAM_RX_tdata;

// BPM CW Stream IN
wire         BPM_CW_AXI_STREAM_RX_tlast;
wire         BPM_CW_AXI_STREAM_RX_tvalid;
wire  [31:0] BPM_CW_AXI_STREAM_RX_tdata;

cell_stream_mux cell_stream_mux_i (
  .clk(auroraUserClk), // input
  .stream_mux_strobe(stream_mux_strobe), // input
  .stream_mux_sel(stream_mux_sel), // input [1:0]
  .stream_in_header(stream_in_header), // input [31:0]
  .stream_in_datax(stream_in_datax), // input [31:0]
  .stream_in_datay(stream_in_datay), // input [31:0]
  .stream_in_datas(stream_in_datas), // input [31:0]
  .stream_mux_valid(stream_mux_valid), // output
  .stream_mux_src(stream_mux_src), // output [1:0]
  .stream_out_header(stream_out_header), // output [31:0]
  .stream_out_datax(stream_out_datax), // output [31:0]
  .stream_out_datay(stream_out_datay), // output [31:0]
  .stream_out_datas(stream_out_datas), // output [31:0]
  .CELL_CCW_AXI_STREAM_TX_tdata(CELL_CCW_AXI_STREAM_TX_tdata), // input [31:0]
  .CELL_CCW_AXI_STREAM_TX_tlast(CELL_CCW_AXI_STREAM_TX_tlast), // input
  .CELL_CCW_AXI_STREAM_TX_tvalid(CELL_CCW_AXI_STREAM_TX_tvalid), // input
  .CELL_CCW_AXI_STREAM_RX_tdata(CELL_CCW_AXI_STREAM_RX_tdata), // output [31:0]
  .CELL_CCW_AXI_STREAM_RX_tlast(CELL_CCW_AXI_STREAM_RX_tlast), // output
  .CELL_CCW_AXI_STREAM_RX_tvalid(CELL_CCW_AXI_STREAM_RX_tvalid), // output
  .CELL_CW_AXI_STREAM_TX_tdata(CELL_CW_AXI_STREAM_TX_tdata), // input [31:0]
  .CELL_CW_AXI_STREAM_TX_tlast(CELL_CW_AXI_STREAM_TX_tlast), // input
  .CELL_CW_AXI_STREAM_TX_tvalid(CELL_CW_AXI_STREAM_TX_tvalid), // input
  .CELL_CW_AXI_STREAM_RX_tdata(CELL_CW_AXI_STREAM_RX_tdata), // output [31:0]
  .CELL_CW_AXI_STREAM_RX_tlast(CELL_CW_AXI_STREAM_RX_tlast), // output
  .CELL_CW_AXI_STREAM_RX_tvalid(CELL_CW_AXI_STREAM_RX_tvalid), // output
  .BPM_CCW_AXI_STREAM_RX_tlast(BPM_CCW_AXI_STREAM_RX_tlast), // output
  .BPM_CCW_AXI_STREAM_RX_tvalid(BPM_CCW_AXI_STREAM_RX_tvalid), // output
  .BPM_CCW_AXI_STREAM_RX_tdata(BPM_CCW_AXI_STREAM_RX_tdata), // output [31:0]
  .BPM_CW_AXI_STREAM_RX_tlast(BPM_CW_AXI_STREAM_RX_tlast), // output
  .BPM_CW_AXI_STREAM_RX_tvalid(BPM_CW_AXI_STREAM_RX_tvalid), // output
  .BPM_CW_AXI_STREAM_RX_tdata(BPM_CW_AXI_STREAM_RX_tdata) // output [31:0]
);

//////////////////////////////////////////////////////////////////////////////
// The clock domains
// Net names starting with 'evr' are in the event receiver clock domain.
// Net names starting with 'aurora' are in the Aurora user clock domain.

//wire evrClk;    // Recovered Rx clock from EVR MGT block
//wire auroraUserClk; // ?? MHz (generated by Aurora block in 'system' BD)

//wire clkIn125;  // Input clock (125 MHz) from U20
//wire sysClk;    // 100 MHz sysclk

//////////////////////////////////////////////////////////////////////////////
// General-purpose I/O block
`include "gpioIDX.vh"
//wire [(GPIO_IDX_COUNT*32)-1:0] GPIO_IN_FLATTENED;
wire [31:0] GPIO_IN[0:GPIO_IDX_COUNT-1];

assign GPIO_IN0 = GPIO_IN[0];
assign GPIO_IN1 = GPIO_IN[1];
assign GPIO_IN2 = GPIO_IN[2];
assign GPIO_IN3 = GPIO_IN[3];
assign GPIO_IN4 = GPIO_IN[4];
assign GPIO_IN5 = GPIO_IN[5];
assign GPIO_IN6 = GPIO_IN[6];
assign GPIO_IN7 = GPIO_IN[7];
assign GPIO_IN8 = GPIO_IN[8];
assign GPIO_IN9 = GPIO_IN[9];
assign GPIO_IN10 = GPIO_IN[10];
assign GPIO_IN11 = GPIO_IN[11];
assign GPIO_IN12 = GPIO_IN[12];
assign GPIO_IN13 = GPIO_IN[13];
assign GPIO_IN14 = GPIO_IN[14];
assign GPIO_IN15 = GPIO_IN[15];
assign GPIO_IN16 = GPIO_IN[16];
assign GPIO_IN17 = GPIO_IN[17];
assign GPIO_IN18 = GPIO_IN[18];
assign GPIO_IN19 = GPIO_IN[19];
assign GPIO_IN20 = GPIO_IN[10];
assign GPIO_IN21 = GPIO_IN[21];
assign GPIO_IN22 = GPIO_IN[22];
assign GPIO_IN23 = GPIO_IN[23];
assign GPIO_IN24 = GPIO_IN[24];
assign GPIO_IN25 = GPIO_IN[25];
assign GPIO_IN26 = GPIO_IN[26];
assign GPIO_IN27 = GPIO_IN[27];
assign GPIO_IN28 = GPIO_IN[28];
assign GPIO_IN29 = GPIO_IN[29];
assign GPIO_IN30 = GPIO_IN[30];
assign GPIO_IN31 = GPIO_IN[31];
assign GPIO_IN32 = GPIO_IN[32];
assign GPIO_IN33 = GPIO_IN[33];
assign GPIO_IN34 = GPIO_IN[34];
assign GPIO_IN35 = GPIO_IN[35];
assign GPIO_IN36 = GPIO_IN[36];
assign GPIO_IN37 = GPIO_IN[37];
assign GPIO_IN38 = GPIO_IN[38];
assign GPIO_IN39 = GPIO_IN[39];
assign GPIO_IN40 = GPIO_IN[40];
assign GPIO_IN41 = GPIO_IN[41];
assign GPIO_IN42 = GPIO_IN[42];
assign GPIO_IN43 = GPIO_IN[43];
assign GPIO_IN44 = GPIO_IN[44];
assign GPIO_IN45 = GPIO_IN[45];
assign GPIO_IN46 = GPIO_IN[46];
assign GPIO_IN47 = GPIO_IN[47];
assign GPIO_IN48 = GPIO_IN[48];
assign GPIO_IN49 = GPIO_IN[49];
assign GPIO_IN50 = GPIO_IN[50];
assign GPIO_IN51 = GPIO_IN[51];
assign GPIO_IN52 = GPIO_IN[52];
assign GPIO_IN53 = GPIO_IN[53];
assign GPIO_IN54 = GPIO_IN[54];
assign GPIO_IN55 = GPIO_IN[55];
assign GPIO_IN56 = GPIO_IN[56];
assign GPIO_IN57 = GPIO_IN[57];
assign GPIO_IN58 = GPIO_IN[58];
assign GPIO_IN59 = GPIO_IN[59];
assign GPIO_IN60 = GPIO_IN[60];
assign GPIO_IN61 = GPIO_IN[61];
assign GPIO_IN62 = GPIO_IN[62];
assign GPIO_IN63 = GPIO_IN[63];

/*
genvar i;
generate
for (i = 0 ; i < GPIO_IDX_COUNT ; i = i + 1) begin : gpio_flatten
  assign GPIO_IN_FLATTENED[ (i*32)+31 : (i*32)+0 ] = GPIO_IN[i];
end
endgenerate
*/

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
// ====== FAKE DATA ======
assign evrTimestamp = {secondsSinceBoot, microsecondsSinceBoot};
reg evrFAmarker=1'b0;
reg [3:0] evrTriggerBus = 0;
// ==== END FAKE DATA ====

forwardData #(.DATA_WIDTH(64))
  forwardData(.inClk(evrClk),
              .inData(evrTimestamp),
              .outClk(sysClk),
              .outData(sysTimestamp));

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
// ====== FAKE DATA ======
reg sysFAenable=1'b0;
assign pll_not_locked_out = 1'b0;
assign gt0_qplllock_out = 1'b0;
assign gt0_qpllrefclklost_out = 1'b0;
assign gtxResetOut = 1'b0;
// ==== END FAKE DATA ====
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

//////////////////////////////////////////////////////////////////////////////
// Aurora streams

// BPM CCW link
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
// ====== FAKE DATA ======
assign BPM_CCW_AuroraCoreStatus_channel_up = 1;
assign BPM_CCW_AuroraCoreStatus_crc_pass_fail = 1;
assign BPM_CCW_AuroraCoreStatus_crc_valid = 1;
assign BPM_CCW_AuroraCoreStatus_frame_err = 0;
assign BPM_CCW_AuroraCoreStatus_hard_err = 0;
assign BPM_CCW_AuroraCoreStatus_lane_up = 0;
assign BPM_CCW_AuroraCoreStatus_rx_resetdone_out = 1;
assign BPM_CCW_AuroraCoreStatus_soft_err = 0;
assign BPM_CCW_AuroraCoreStatus_tx_lock = 1;
assign BPM_CCW_AuroraCoreStatus_tx_resetdone_out = 1;
assign BPM_CW_AuroraCoreStatus_channel_up = 1;
assign BPM_CW_AuroraCoreStatus_crc_pass_fail = 1;
assign BPM_CW_AuroraCoreStatus_crc_valid = 1;
assign BPM_CW_AuroraCoreStatus_frame_err = 0;
assign BPM_CW_AuroraCoreStatus_hard_err = 0;
assign BPM_CW_AuroraCoreStatus_lane_up = 1;
assign BPM_CW_AuroraCoreStatus_rx_resetdone_out = 1;
assign BPM_CW_AuroraCoreStatus_soft_err = 0;
assign BPM_CW_AuroraCoreStatus_tx_lock = 1;
assign BPM_CW_AuroraCoreStatus_tx_resetdone_out = 1;
assign CELL_CCW_AuroraCoreStatus_channel_up = 1;
assign CELL_CCW_AuroraCoreStatus_crc_pass_fail = 1;
assign CELL_CCW_AuroraCoreStatus_crc_valid = 1;
assign CELL_CCW_AuroraCoreStatus_frame_err = 0;
assign CELL_CCW_AuroraCoreStatus_hard_err = 0;
assign CELL_CCW_AuroraCoreStatus_lane_up = 0;
assign CELL_CCW_AuroraCoreStatus_rx_resetdone_out = 1;
assign CELL_CCW_AuroraCoreStatus_soft_err = 0;
assign CELL_CCW_AuroraCoreStatus_tx_lock = 1;
assign CELL_CCW_AuroraCoreStatus_tx_resetdone_out = 1;
assign CELL_CW_AuroraCoreStatus_channel_up = 1;
assign CELL_CW_AuroraCoreStatus_crc_pass_fail = 1;
assign CELL_CW_AuroraCoreStatus_crc_valid = 1;
assign CELL_CW_AuroraCoreStatus_frame_err = 0;
assign CELL_CW_AuroraCoreStatus_hard_err = 0;
assign CELL_CW_AuroraCoreStatus_lane_up = 1;
assign CELL_CW_AuroraCoreStatus_rx_resetdone_out = 1;
assign CELL_CW_AuroraCoreStatus_soft_err = 0;
assign CELL_CW_AuroraCoreStatus_tx_lock = 1;
assign CELL_CW_AuroraCoreStatus_tx_resetdone_out = 1;
// ==== END FAKE DATA ====

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
         .sysCsrStrobe(GPIO_STROBES[GPIO_IDX_BPMLINKS_CSR]), // input
         .GPIO_OUT(GPIO_OUT), // input [31:0]
         .sysCsr(GPIO_IN[GPIO_IDX_BPMLINKS_CSR]), // output [31:0]
         .sysAdditionalStatus(GPIO_IN[GPIO_IDX_BPMLINKS_EXTRA_STATUS]), // output [31:0]
         .sysRxBitmap(GPIO_IN[GPIO_IDX_BPM_RX_BITMAP]), // output [31:0]
         .sysLocalFOFBenabled(localFOFBcontrol), // input
         .sysSetpointWriteData(BRAM_BPM_SETPOINTS_WDATA), // input [31:0]
         .sysSetpointAddress(BRAM_BPM_SETPOINTS_ADDR), // input [15:0]
         .sysSetpointWriteEnable(BRAM_BPM_SETPOINTS_WENABLE), // input
         .sysSetpointReadData(BRAM_BPM_SETPOINTS_RDATA), // output [31:0]
         .auroraUserClk(auroraUserClk),
         .auroraFAstrobe(auroraFAstrobe), // input
          // BPM CCW AXI Stream
         .BPM_CCW_AXI_STREAM_RX_tdata(BPM_CCW_AXI_STREAM_RX_tdata), // input
         .BPM_CCW_AXI_STREAM_RX_tvalid(BPM_CCW_AXI_STREAM_RX_tvalid), // input
         .BPM_CCW_AXI_STREAM_RX_tlast(BPM_CCW_AXI_STREAM_RX_tlast), // input
         .BPM_CCW_AXI_STREAM_RX_CRC_pass(BPM_CCW_AuroraCoreStatus_crc_pass_fail), // input
         .BPM_CCW_AXI_STREAM_RX_CRC_valid(BPM_CCW_AuroraCoreStatus_crc_valid),  // input
         .CCWstatusStrobe(bpmCCWstatusStrobe),  // output
         .CCWstatusCode(bpmCCWstatusCode),  // output

          // BPM CW AXI Stream
         .BPM_CW_AXI_STREAM_RX_tdata(BPM_CW_AXI_STREAM_RX_tdata), // input
         .BPM_CW_AXI_STREAM_RX_tvalid(BPM_CW_AXI_STREAM_RX_tvalid), // input
         .BPM_CW_AXI_STREAM_RX_tlast(BPM_CW_AXI_STREAM_RX_tlast), // input
         .BPM_CW_AXI_STREAM_RX_CRC_pass(BPM_CW_AuroraCoreStatus_crc_pass_fail), // input
         .BPM_CW_AXI_STREAM_RX_CRC_valid(BPM_CW_AuroraCoreStatus_crc_valid),  // input
         .CWstatusStrobe(bpmCWstatusStrobe), // output
         .CWstatusCode(bpmCWstatusCode), // output

         // Merged BPM data
         .mergedLinkTDATA(localBPMvalues), // output [111:0]
         .mergedLinkTVALID(localBPMvaluesVALID), // output

         // Merged (local) BPM AXI Stream
         .localBPMs_tdata(localBPMs_tdata), // output
         .localBPMs_tvalid(localBPMs_tvalid), // output
         .localBPMs_tlast(localBPMs_tlast)); // output

//////////////////////////////////////////////////////////////////////////////
// Forward incoming and local streams to next cell
// Pick up CSR values from fofbReadLinks since we don't have any CSR
wire auCCWcellInhibit, auCWcellInhibit;
wire auCCWcellStreamValid = CELL_CCW_AXI_STREAM_RX_tvalid && !auCCWcellInhibit;
wire auCWcellStreamValid  = CELL_CW_AXI_STREAM_RX_tvalid  && !auCWcellInhibit;
forwardCellLink #(.dbg("false")) forwardCCWcell (
       .auroraUserClk(auroraUserClk),
       .auroraFAstrobe(auroraFAstrobe),

       .cellLinkRxTVALID(auCCWcellStreamValid), // input
       .cellLinkRxTLAST(CELL_CCW_AXI_STREAM_RX_tlast),  // input
       .cellLinkRxTDATA(CELL_CCW_AXI_STREAM_RX_tdata),  // input

       .cellLinkRxCRCvalid(CELL_CCW_AuroraCoreStatus_crc_valid),
       .cellLinkRxCRCpass(CELL_CCW_AuroraCoreStatus_crc_pass_fail),

       .localRxTVALID(localBPMs_tvalid), // input
       .localRxTLAST(localBPMs_tlast), // input
       .localRxTDATA(localBPMs_tdata), // input

       .cellLinkTxTVALID(CELL_CW_AXI_STREAM_TX_tvalid), // output
       .cellLinkTxTLAST(CELL_CW_AXI_STREAM_TX_tlast), // output
       .cellLinkTxTDATA(CELL_CW_AXI_STREAM_TX_tdata)  // output
);

forwardCellLink #(.dbg("false")) forwardCWcell (
       .auroraUserClk(auroraUserClk),
       .auroraFAstrobe(auroraFAstrobe),

       .cellLinkRxTVALID(auCWcellStreamValid),  // input
       .cellLinkRxTLAST(CELL_CW_AXI_STREAM_RX_tlast), // input
       .cellLinkRxTDATA(CELL_CW_AXI_STREAM_RX_tdata), // input

       .cellLinkRxCRCvalid(CELL_CW_AuroraCoreStatus_crc_valid),
       .cellLinkRxCRCpass(CELL_CW_AuroraCoreStatus_crc_pass_fail),

       .localRxTVALID(localBPMs_tvalid),  // input
       .localRxTLAST(localBPMs_tlast),  // input
       .localRxTDATA(localBPMs_tdata),  // input

       .cellLinkTxTVALID(CELL_CCW_AXI_STREAM_TX_tvalid), // output
       .cellLinkTxTLAST(CELL_CCW_AXI_STREAM_TX_tlast), // output
       .cellLinkTxTDATA(CELL_CCW_AXI_STREAM_TX_tdata) // output
);

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
       .sysStatusStrobe(sysCellStatusStrobe), // output
       .sysStatusCode(sysCellStatusCode), // output [2:0]
       .sysTimeoutStrobe(sysTimeoutStrobe), // output

       .fofbDSPreadoutAddress(fofbDSPreadoutAddress), // input
       .fofbDSPreadoutX(fofbDSPreadoutX), // output
       .fofbDSPreadoutY(fofbDSPreadoutY), // output
       .fofbDSPreadoutS(fofbDSPreadoutS), // output

       .uBreadoutStrobe(GPIO_STROBES[GPIO_IDX_BPM_READOUT_X]),
       .uBreadoutX(GPIO_IN[GPIO_IDX_BPM_READOUT_X]),
       .uBreadoutY(GPIO_IN[GPIO_IDX_BPM_READOUT_Y]),
       .uBreadoutS(GPIO_IN[GPIO_IDX_BPM_READOUT_S]),

       .auClk(auroraUserClk),
       .auFAstrobe(auroraFAstrobe),
       .auReset(auroraReset),
       .auCCWcellInhibit(auCCWcellInhibit),
       .auCWcellInhibit(auCWcellInhibit),

       .auCellCCWlinkTVALID(CELL_CCW_AXI_STREAM_TX_tvalid), // input
       .auCellCCWlinkTLAST(CELL_CCW_AXI_STREAM_TX_tlast), // input
       .auCellCCWlinkTDATA(CELL_CCW_AXI_STREAM_TX_tdata), // input

       .auCellCWlinkTVALID(CELL_CW_AXI_STREAM_TX_tvalid), // input
       .auCellCWlinkTLAST(CELL_CW_AXI_STREAM_TX_tlast), // input
       .auCellCWlinkTDATA(CELL_CW_AXI_STREAM_TX_tdata)); // input

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
    .fofbEnabled(fofbEnabled),
    .fofbReadoutCSR(fofbReadoutCSR),
    .fofbDSPreadoutAddress(fofbDSPreadoutAddress),  // output
    .fofbDSPreadoutX(fofbDSPreadoutX),  // input
    .fofbDSPreadoutY(fofbDSPreadoutY),  // input
    .fofbDSPreadoutS(fofbDSPreadoutS),  // input
    // FOFB Results AXI Stream
    .SETPOINT_TVALID(FOFB_SETPOINT_AXIS_TVALID),  // output
    .SETPOINT_TLAST(FOFB_SETPOINT_AXIS_TLAST),  // output
    .SETPOINT_TDATA(FOFB_SETPOINT_AXIS_TDATA)); // output [31:0]

//////////////////////////////////////////////////////////////////////////////
// Provide CPU read access to power supply setpoints
psSetpointMonitor #(.SETPOINT_COUNT(GPIO_CHANNEL_COUNT),
                    .DEBUG("false"))
  psSetpointMonitor (
    .clk(sysClk),
    .FOFB_SETPOINT_AXIS_TVALID(FOFB_SETPOINT_AXIS_TVALID),  // input
    .FOFB_SETPOINT_AXIS_TLAST(FOFB_SETPOINT_AXIS_TLAST),  // input
    .FOFB_SETPOINT_AXIS_TDATA(FOFB_SETPOINT_AXIS_TDATA),  // input [31:0]
    .addressStrobe(GPIO_STROBES[GPIO_IDX_FOFB_PS_SETPOINT]),  // input
    .GPIO_OUT(GPIO_OUT),  // input
    .psSetpoint(GPIO_IN[GPIO_IDX_FOFB_PS_SETPOINT]), // output [31:0]
    .status(GPIO_IN[GPIO_IDX_FOFB_PS_SETPOINT_STATUS])); // output [31:0]

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
         .awgTDATA(AWG_AXIS_TDATA), // output
         .awgTVALID(AWG_AXIS_TVALID), // output
         .awgTLAST(AWG_AXIS_TLAST));  // output

//////////////////////////////////////////////////////////////////////////////
// Multiplex fast feedback and arbitrary waveform streams
wire [31:0] PS_SETPOINT_AXIS_TDATA;
wire        PS_SETPOINT_AXIS_TVALID;
wire        PS_SETPOINT_AXIS_TLAST;

// Unused in Verilator model (supposed to come from power supplies)
wire [31:0] PS_READBACK_AXIS_TDATA=0;
wire  [7:0] PS_READBACK_AXIS_TUSER=0;
wire        PS_READBACK_AXIS_TVALID=0;

psMUX #(.DEBUG("false"),
        .AXI_WIDTH(32))
  psMUX (.clk(sysClk),
         .AWGrequest(AWGrequest),
         .AWGenabled(AWGenabled),
         // FOFB Results AXI Stream
         .fofbTDATA(FOFB_SETPOINT_AXIS_TDATA),  // input [31:0]
         .fofbTVALID(FOFB_SETPOINT_AXIS_TVALID),  // input
         .fofbTLAST(FOFB_SETPOINT_AXIS_TLAST),  // input
         // AWG AXI Stream
         .awgTDATA(AWG_AXIS_TDATA), // input [31:0]
         .awgTVALID(AWG_AXIS_TVALID), // input
         .awgTLAST(AWG_AXIS_TLAST), // input
         // Power Supply Setpoint AXI Stream
         .psTDATA(PS_SETPOINT_AXIS_TDATA),  // output [31:0]
         .psTVALID(PS_SETPOINT_AXIS_TVALID),  // output
         .psTLAST(PS_SETPOINT_AXIS_TLAST)); // output

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
    .tx_S_AXIS_TVALID(PS_SETPOINT_AXIS_TVALID), // input
    .tx_S_AXIS_TDATA(PS_SETPOINT_AXIS_TDATA), // input [31:0]
    .tx_S_AXIS_TLAST(PS_SETPOINT_AXIS_TLAST), // input
    .rx_S_AXIS_TVALID(PS_READBACK_AXIS_TVALID), // input
    .rx_S_AXIS_TDATA(PS_READBACK_AXIS_TDATA), // input [31:0]
    .rx_S_AXIS_TUSER(PS_READBACK_AXIS_TUSER));  // input

/////////////////////////////////////////////////////////////////////////////
// Miscellaneous
assign GPIO_IN[GPIO_IDX_FIRMWARE_BUILD_DATE] = 0; // Deprecating firmware build date
`include "gitHash.vh"
assign GPIO_IN[GPIO_IDX_GITHASH] = GIT_REV_32BIT; // Deprecating firmware build date

endmodule
