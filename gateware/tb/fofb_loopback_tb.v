`timescale 1ns/1ns
/* Loopback simulation of FOFB network
 */

module fofb_loopback_tb;

//////////////////////////////////////////////////////////////////////////////
// Simulation Controls
reg gen_traffic_out_ccw=1'b1; // 1 = output on CCW stream, 0 = output on CW stream
localparam cell_traffic_autoinc=1'b1;
reg [4:0] cell_traffic_cell_index=0;
reg [4:0] bpm_traffic_cell_index=0;
reg [1:0] bpm_traffic_gen_mode=0; // 0 = alternate, 1 = CCW only, 2 = CW only, 3 = both
reg loopback_close_loop_ccw=1'b1;
reg loopback_close_loop_cw=1'b1;
localparam [8:0] bpm_traffic_fofb_init=0;
localparam [8:0] bpm_traffic_fofb_max=7;

reg [31:0] expectedRxBitmap=((1 << (bpm_traffic_fofb_max+1))-1) << bpm_traffic_fofb_init;

// Tell the traffic generators to go
reg bpm_traffic_trigger=1'b0;
reg cell_traffic_trigger=1'b0;

// Fast Acquisition Strobe
reg FAstrobe=1'b0;

// VCD dump file for gtkwave
reg [64*8-1:0] dumpfile; // 64-chars max
reg do_cell_loopback_test=1'b0;
reg do_bpm_loopback_test=1'b0;
initial begin
  if (! $value$plusargs("df=%s", dumpfile)) begin
    $display("No dumpfile name supplied; Wave data will not be saved.");
  end else begin
    $dumpfile(dumpfile);
    $dumpvars;
  end
  #1;
  if      (dumpfile == "cell_loop_check.vcd") do_cell_loopback_test=1'b1;
  else if (dumpfile == "bpm_loop_check.vcd")  do_bpm_loopback_test =1'b1;
end

// ========= Fill BPM Setpoints =============
// TODO - Initialize with useful values (currently just ensuring no X's in sim)
localparam MAX_BPMS_PER_CELL  = 32;
localparam SETPOINT_ADDR_WIDTH = $clog2(2*MAX_BPMS_PER_CELL);
integer I;
initial begin
  for (I = 0; I < (1<<(1+SETPOINT_ADDR_WIDTH))-1; I = I + 1) readBPMlinks.dpram[I] = 0;
end

// =========== Timeout Signal ===============
localparam TOW = 12;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] timeout=0;
always #10 begin
  if (timeout > 0) timeout <= timeout - 1;
end
wire to = ~(|timeout);

// ============== Stimulus ===================
initial begin
  # 10;
          // Set expected Cell Controller count
          fofbReadLinks.cellCount = 32;
          // Set expected BPM count
          readBPMlinks.sysCsrCellIndex = 0; // TODO - Is this ok?  Should it not be == cell_traffic_cell_index?
          readBPMlinks.sysCsrBPMcount = bpm_traffic_fofb_max - bpm_traffic_fofb_init + 1;
          readBPMlinks.sysCsrSetpointBank = 1'b0;
          // Reset statistics
          FAstrobe = 1'b0;
  # 20    FAstrobe = 1'b1;
  # 10    FAstrobe = 1'b0;
  wait (auFAstrobeDelayed); // Wait for reset to complete
  if (do_cell_loopback_test) begin
          $display("Running Cell Controller Loopback test");
          // Send a packet with CELL_INDEX = 0
          loopback_close_loop_ccw=1'b1;
          loopback_close_loop_cw=1'b1;
          cell_traffic_cell_index=0;
    # 10  cell_traffic_trigger = 1'b1;
    # 10  cell_traffic_trigger = 1'b0;
          // Wait for forwardCellLink to fill
          timeout = TOSET;
    # 10  wait (fofbReadLinks.readoutValid || to);
          if (to) begin $display("FAIL: Timeout waiting for readoutValid"); $stop(0); end
          else begin $display("PASS"); $finish(0); end
  end else if (do_bpm_loopback_test) begin
          $display("Running BPM Loopback test");
          // Need to send a second FAstrobe because readBPMlinks discards
          // the first set of BPM data
          FAstrobe = 1'b0;
  # 20    FAstrobe = 1'b1;
  # 10    FAstrobe = 1'b0;
  wait (auFAstrobeDelayed); // Wait for reset to complete
          // Start the BPM traffic generator with CELL_INDEX = 0
          bpm_traffic_cell_index=0;
  # 10    bpm_traffic_trigger = 1'b1;
  # 10    bpm_traffic_trigger = 1'b0;
          timeout = TOSET;
  # 10 wait (localBPMs_tlast || to);
          if (to) begin $display("FAIL: Timeout waiting for localBPMs_tlast"); $stop(0); end
          // Send another FAstrobe to transfer readBPMlinks.rxBitmap to sysRxBitmap
          FAstrobe = 1'b0;
  # 20    FAstrobe = 1'b1;
  # 10    FAstrobe = 1'b0;
  wait (auFAstrobeDelayed); // Wait for reset to complete
  # 10    if (sysRxBitmap != expectedRxBitmap) begin
            $display("FAIL: RxBitmap 0x%x != 0x%x", sysRxBitmap, expectedRxBitmap);
            $stop(0);
          end else begin
            $display("PASS");
            $finish(0);
          end
  end else begin
          $display("Nothing to do");
          $stop(0);
  end
end

// =============== Clocks ====================
// 125 MHz auroraUserClk
reg auroraUserClk=1'b0;
always #4 auroraUserClk <= ~auroraUserClk;
// 100 MHz sysClk
reg sysClk=1'b0;
always #5 sysClk <= ~sysClk;

// I don't know why forwardCellLink does a 'mux reset stretch' but
// it means I can't trigger the traffic generator until quite a bit
// later to avoid getting blacked out with the stretched reset
reg [5:0] auFAstrobeCnt=0;
// Forward FAstrobe to auroraUserClk domain
reg auroraFAstrobe=1'b0, auroraFAstrobe_m=1'b0;
always @(posedge auroraUserClk) begin
  auroraFAstrobe_m <= FAstrobe;
  auroraFAstrobe <= auroraFAstrobe_m;
  if (auroraFAstrobe) begin
    auFAstrobeCnt <= 0;
  end
  // Weird counter is basically just blowing past the number 6'b100001 which
  // triggers auFAstrobeDelayed for 1 cycle, then ends at 6'b100010 until
  // reset to 0 by auroraFAstrobe
  if (auFAstrobeCnt < 6'h22) auFAstrobeCnt <= auFAstrobeCnt + 1;
end
wire auFAstrobeDelayed = auFAstrobeCnt[0] & auFAstrobeCnt[5];

// Forward FAstrobe to sysClk domain
reg sysFAstrobe=1'b0, sysFAstrobe_m=1'b0;
always @(posedge sysClk) begin
  sysFAstrobe_m <= FAstrobe;
  sysFAstrobe <= sysFAstrobe_m;
end

reg localFOFBcontrol=1'b0; // to readBPMlinks
reg auroraReset=1'b0;
// Setpoints read/write bus control
reg [31:0] bpm_setpoints_wdata=0;
reg [15:0] bpm_setpoints_addr=0;
reg bpm_setpoints_wenable=1'b0;
wire [31:0] bpm_setpoints_rdata;

// These can be exercised for testing
reg BPM_CW_AuroraCoreStatus_crc_pass_fail=1'b1;
reg BPM_CW_AuroraCoreStatus_crc_valid=1'b1;
reg BPM_CCW_AuroraCoreStatus_crc_pass_fail=1'b1;
reg BPM_CCW_AuroraCoreStatus_crc_valid=1'b1;
reg CELL_CCW_AuroraCoreStatus_crc_valid=1'b1;
reg CELL_CCW_AuroraCoreStatus_crc_pass_fail=1'b1;
reg CELL_CW_AuroraCoreStatus_crc_valid=1'b1;
reg CELL_CW_AuroraCoreStatus_crc_pass_fail=1'b1;

// Capturing data for simulation
wire [31:0] sysRxBitmap;

wire [31:0] CELL_CCW_AXI_STREAM_TX_tdata;
wire CELL_CCW_AXI_STREAM_TX_tlast;
wire CELL_CCW_AXI_STREAM_TX_tvalid;
wire [31:0] CELL_CCW_AXI_STREAM_RX_tdata;
wire CELL_CCW_AXI_STREAM_RX_tlast;
wire CELL_CCW_AXI_STREAM_RX_tvalid;
wire [31:0] CELL_CW_AXI_STREAM_TX_tdata;
wire CELL_CW_AXI_STREAM_TX_tlast;
wire CELL_CW_AXI_STREAM_TX_tvalid;
wire [31:0] CELL_CW_AXI_STREAM_RX_tdata;
wire CELL_CW_AXI_STREAM_RX_tlast;
wire CELL_CW_AXI_STREAM_RX_tvalid;
wire [31:0] CELL_CCW_AXI_STREAM_TX_tdata_merged;
wire CELL_CCW_AXI_STREAM_TX_tlast_merged;
wire CELL_CCW_AXI_STREAM_TX_tvalid_merged;
wire [31:0] CELL_CW_AXI_STREAM_TX_tdata_merged;
wire CELL_CW_AXI_STREAM_TX_tlast_merged;
wire CELL_CW_AXI_STREAM_TX_tvalid_merged;

`include "gpioIDX.vh"
parameter SYSCLK_RATE   = 100_000_000;
//////////////////////////////////////////////////////////////////////////////
// Aurora streams
wire [31:0] localBPMs_tdata;
wire        localBPMs_tvalid, localBPMs_tlast;
wire  [2:0] sysCellStatusCode;
wire        sysCellStatusStrobe;

wire [111:0] localBPMvalues;      // Aurora user clock domain
wire         localBPMvaluesVALID; // Aurora user clock domain

wire fofbEnabled;

// BPM CCW link
wire        BPM_CCW_AXI_STREAM_RX_tlast, BPM_CCW_AXI_STREAM_RX_tvalid;
wire [31:0] BPM_CCW_AXI_STREAM_RX_tdata;

// BPM CW link
wire        BPM_CW_AXI_STREAM_RX_tlast, BPM_CW_AXI_STREAM_RX_tvalid;
wire [31:0] BPM_CW_AXI_STREAM_RX_tdata;

readBPMlinks #(.faStrobeDebug("false"),
               .bpmSetpointDebug("false"),
               .ccwInDebug("false"),
               .cwInDebug("false"),
               .mergedDebug("false"),
               .outDebug("false"),
               .stateDebug("false"))
  readBPMlinks (
         .sysClk(sysClk),
         .sysCsrStrobe(1'b0), // input
         .GPIO_OUT(32'h0), // input [31:0]
         .sysCsr(), // output [31:0]
         .sysAdditionalStatus(), // output [31:0]
         .sysRxBitmap(sysRxBitmap), // output [31:0]
         .sysLocalFOFBenabled(localFOFBcontrol),  // input
         .sysSetpointWriteData(bpm_setpoints_wdata), // input [31:0]
         .sysSetpointAddress(bpm_setpoints_addr), // input [15:0]
         .sysSetpointWriteEnable(bpm_setpoints_wenable), // input
         .sysSetpointReadData(bpm_setpoints_rdata), // output [31:0]
         .auroraUserClk(auroraUserClk), // input
         .auroraFAstrobe(auroraFAstrobe), // input
          // BPM CCW AXI Stream
         .BPM_CCW_AXI_STREAM_RX_tdata(BPM_CCW_AXI_STREAM_RX_tdata), // input
         .BPM_CCW_AXI_STREAM_RX_tvalid(BPM_CCW_AXI_STREAM_RX_tvalid), // input
         .BPM_CCW_AXI_STREAM_RX_tlast(BPM_CCW_AXI_STREAM_RX_tlast), // input
         .BPM_CCW_AXI_STREAM_RX_CRC_pass(BPM_CCW_AuroraCoreStatus_crc_pass_fail), // input
         .BPM_CCW_AXI_STREAM_RX_CRC_valid(BPM_CCW_AuroraCoreStatus_crc_valid),  // input
         .CCWstatusStrobe(),  // output
         .CCWstatusCode(),  // output [1:0]

          // BPM CW AXI Stream
         .BPM_CW_AXI_STREAM_RX_tdata(BPM_CW_AXI_STREAM_RX_tdata), // input
         .BPM_CW_AXI_STREAM_RX_tvalid(BPM_CW_AXI_STREAM_RX_tvalid), // input
         .BPM_CW_AXI_STREAM_RX_tlast(BPM_CW_AXI_STREAM_RX_tlast), // input
         .BPM_CW_AXI_STREAM_RX_CRC_pass(BPM_CW_AuroraCoreStatus_crc_pass_fail), // input
         .BPM_CW_AXI_STREAM_RX_CRC_valid(BPM_CW_AuroraCoreStatus_crc_valid),  // input
         .CWstatusStrobe(), // output
         .CWstatusCode(), // output

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
       .auroraUserClk(auroraUserClk), // input
       .auroraFAstrobe(auroraFAstrobe), // input

       .cellLinkRxTVALID(auCCWcellStreamValid), // input
       .cellLinkRxTLAST(CELL_CCW_AXI_STREAM_RX_tlast),  // input
       .cellLinkRxTDATA(CELL_CCW_AXI_STREAM_RX_tdata),  // input

       .cellLinkRxCRCvalid(CELL_CCW_AuroraCoreStatus_crc_valid), // input
       .cellLinkRxCRCpass(CELL_CCW_AuroraCoreStatus_crc_pass_fail), // input

       .localRxTVALID(localBPMs_tvalid), // input
       .localRxTLAST(localBPMs_tlast), // input
       .localRxTDATA(localBPMs_tdata), // input

       .cellLinkTxTVALID(CELL_CW_AXI_STREAM_TX_tvalid), // output
       .cellLinkTxTLAST(CELL_CW_AXI_STREAM_TX_tlast), // output
       .cellLinkTxTDATA(CELL_CW_AXI_STREAM_TX_tdata)  // output
);

forwardCellLink #(.dbg("false")) forwardCWcell (
       .auroraUserClk(auroraUserClk), // input
       .auroraFAstrobe(auroraFAstrobe), // input

       .cellLinkRxTVALID(auCWcellStreamValid),  // input
       .cellLinkRxTLAST(CELL_CW_AXI_STREAM_RX_tlast), // input
       .cellLinkRxTDATA(CELL_CW_AXI_STREAM_RX_tdata), // input

       .cellLinkRxCRCvalid(CELL_CW_AuroraCoreStatus_crc_valid), // input
       .cellLinkRxCRCpass(CELL_CW_AuroraCoreStatus_crc_pass_fail), // input

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
       .sysClk(sysClk), // input
       .csrStrobe(1'b0), // input
       .GPIO_OUT(32'h0), // input [31:0]
       .csr(), // output [31:0]
       .rxBitmap(), // output [MAX_CELLS-1:0]
       .fofbEnableBitmap(), // output [MAX_CELLS-1:0]
       .fofbEnabled(fofbEnabled), // output

       .FAstrobe(sysFAstrobe),  // output
       .sysStatusStrobe(), // output
       .sysStatusCode(), // output [2:0]
       .sysTimeoutStrobe(), // output

       .fofbDSPreadoutAddress(fofbDSPreadoutAddress), // input [FOFB_INDEX_WIDTH-1:0] 
       .fofbDSPreadoutX(fofbDSPreadoutX), // output [31:0]
       .fofbDSPreadoutY(fofbDSPreadoutY), // output [31:0]
       .fofbDSPreadoutS(fofbDSPreadoutS), // output [31:0]

       .uBreadoutStrobe(1'b0), // input
       .uBreadoutX(), // output [31:0]
       .uBreadoutY(), // output [31:0]
       .uBreadoutS(), // output [31:0]

       .auClk(auroraUserClk), // input
       .auFAstrobe(auroraFAstrobe), // input
       .auReset(auroraReset), // input
       .auCCWcellInhibit(auCCWcellInhibit), // output
       .auCWcellInhibit(auCWcellInhibit), // output

       .auCellCCWlinkTVALID(CELL_CCW_AXI_STREAM_TX_tvalid_merged), // input
       .auCellCCWlinkTLAST(CELL_CCW_AXI_STREAM_TX_tlast_merged), // input
       .auCellCCWlinkTDATA(CELL_CCW_AXI_STREAM_TX_tdata_merged), // input

       .auCellCWlinkTVALID(CELL_CW_AXI_STREAM_TX_tvalid_merged), // input
       .auCellCWlinkTLAST(CELL_CW_AXI_STREAM_TX_tlast_merged), // input
       .auCellCWlinkTDATA(CELL_CW_AXI_STREAM_TX_tdata_merged)); // input


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
    .clk(sysClk), // input
    .csrStrobe(1'b0), // input
    .GPIO_OUT(32'h0), // input [31:0]
    .firStatus(), // output [31:0]
    .fofbEnabled(fofbEnabled), // input
    .fofbReadoutCSR(32'h0), // input [31:0]
    .fofbDSPreadoutAddress(fofbDSPreadoutAddress),  // output [FOFB_MATRIX_ADDR_WIDTH-1:0]
    .fofbDSPreadoutX(fofbDSPreadoutX),  // input [31:0]
    .fofbDSPreadoutY(fofbDSPreadoutY),  // input [31:0]
    .fofbDSPreadoutS(fofbDSPreadoutS),  // input [31:0]
    // FOFB Results AXI Stream
    .SETPOINT_TVALID(FOFB_SETPOINT_AXIS_TVALID), // output
    .SETPOINT_TLAST(FOFB_SETPOINT_AXIS_TLAST), // output
    .SETPOINT_TDATA(FOFB_SETPOINT_AXIS_TDATA)); // output [31:0]

//////////////////////////////////////////////////////////////////////////////
// Loopback

axi_stream_loopback axi_stream_loopback_i (
  .close_loop_ccw(loopback_close_loop_ccw),
  .close_loop_cw(loopback_close_loop_cw),
  // CELL CCW AXI Stream TX (input)
  .CELL_CCW_AXI_STREAM_TX_tdata(CELL_CCW_AXI_STREAM_TX_tdata_merged), // input [31:0]
  .CELL_CCW_AXI_STREAM_TX_tlast(CELL_CCW_AXI_STREAM_TX_tlast_merged), // input
  .CELL_CCW_AXI_STREAM_TX_tvalid(CELL_CCW_AXI_STREAM_TX_tvalid_merged), // input
  // CELL CCW AXI Stream RX (output)
  .CELL_CCW_AXI_STREAM_RX_tdata(CELL_CCW_AXI_STREAM_RX_tdata), // output [31:0]
  .CELL_CCW_AXI_STREAM_RX_tlast(CELL_CCW_AXI_STREAM_RX_tlast), // output
  .CELL_CCW_AXI_STREAM_RX_tvalid(CELL_CCW_AXI_STREAM_RX_tvalid), // output
  // CELL CW AXI Stream TX (input)
  .CELL_CW_AXI_STREAM_TX_tdata(CELL_CW_AXI_STREAM_TX_tdata_merged), // input [31:0]
  .CELL_CW_AXI_STREAM_TX_tlast(CELL_CW_AXI_STREAM_TX_tlast_merged), // input
  .CELL_CW_AXI_STREAM_TX_tvalid(CELL_CW_AXI_STREAM_TX_tvalid_merged), // input
  // CELL CW AXI Stream RX (output)
  .CELL_CW_AXI_STREAM_RX_tdata(CELL_CW_AXI_STREAM_RX_tdata), // output [31:0]
  .CELL_CW_AXI_STREAM_RX_tlast(CELL_CW_AXI_STREAM_RX_tlast), // output
  .CELL_CW_AXI_STREAM_RX_tvalid(CELL_CW_AXI_STREAM_RX_tvalid) // output
);

cell_traffic_generator #( 
  .CELL_INDEX_AUTOINCREMENT(cell_traffic_autoinc)
) cell_traffic_generator_i (
  .clk(auroraUserClk), // input
  .start(cell_traffic_trigger), // input
  .out_ccw(gen_traffic_out_ccw), // input
  .cell_index(cell_traffic_cell_index), // input [4:0]
  // CELL CCW AXI Stream TX (input)
  .CELL_CCW_AXI_STREAM_TX_tdata_in(CELL_CCW_AXI_STREAM_TX_tdata), // input [31:0]
  .CELL_CCW_AXI_STREAM_TX_tlast_in(CELL_CCW_AXI_STREAM_TX_tlast), // input
  .CELL_CCW_AXI_STREAM_TX_tvalid_in(CELL_CCW_AXI_STREAM_TX_tvalid), // input
  // CELL CCW AXI Stream TX (output)
  .CELL_CCW_AXI_STREAM_TX_tdata_out(CELL_CCW_AXI_STREAM_TX_tdata_merged), // output [31:0]
  .CELL_CCW_AXI_STREAM_TX_tlast_out(CELL_CCW_AXI_STREAM_TX_tlast_merged), // output
  .CELL_CCW_AXI_STREAM_TX_tvalid_out(CELL_CCW_AXI_STREAM_TX_tvalid_merged), // output
  // CELL CW AXI Stream TX (input)
  .CELL_CW_AXI_STREAM_TX_tdata_in(CELL_CW_AXI_STREAM_TX_tdata), // input [31:0]
  .CELL_CW_AXI_STREAM_TX_tlast_in(CELL_CW_AXI_STREAM_TX_tlast), // input
  .CELL_CW_AXI_STREAM_TX_tvalid_in(CELL_CW_AXI_STREAM_TX_tvalid), // input
  // CELL CW AXI Stream TX (output)
  .CELL_CW_AXI_STREAM_TX_tdata_out(CELL_CW_AXI_STREAM_TX_tdata_merged), // output [31:0]
  .CELL_CW_AXI_STREAM_TX_tlast_out(CELL_CW_AXI_STREAM_TX_tlast_merged), // output
  .CELL_CW_AXI_STREAM_TX_tvalid_out(CELL_CW_AXI_STREAM_TX_tvalid_merged) // output
);

bpm_traffic_generator #(
  .FOFB_INDEX_INIT(bpm_traffic_fofb_init),
  .FOFB_INDEX_MAX(bpm_traffic_fofb_max)
  ) bpm_traffic_generator_i (
  .clk(auroraUserClk), // input
  .start(bpm_traffic_trigger), // input
  .mode(bpm_traffic_gen_mode), // input [1:0]
  .cell_index(bpm_traffic_cell_index), // input [4:0]
  // BPM CCW AXI Stream
  .BPM_CCW_AXI_STREAM_RX_tdata(BPM_CCW_AXI_STREAM_RX_tdata), // output [31:0]
  .BPM_CCW_AXI_STREAM_RX_tlast(BPM_CCW_AXI_STREAM_RX_tlast), // output
  .BPM_CCW_AXI_STREAM_RX_tvalid(BPM_CCW_AXI_STREAM_RX_tvalid), // output
  // BPM CW AXI Stream
  .BPM_CW_AXI_STREAM_RX_tdata(BPM_CW_AXI_STREAM_RX_tdata), // output [31:0]
  .BPM_CW_AXI_STREAM_RX_tlast(BPM_CW_AXI_STREAM_RX_tlast), // output
  .BPM_CW_AXI_STREAM_RX_tvalid(BPM_CW_AXI_STREAM_RX_tvalid) // output
);

endmodule
