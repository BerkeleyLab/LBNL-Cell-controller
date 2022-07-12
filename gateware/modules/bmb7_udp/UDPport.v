//
// Copyright (c) 2106 W. Eric Norum, Lawrence Berkeley National Laboratory
//

module UDPport #(
    parameter ADDR_WIDTH = 11, // Allow for non-jumbo packet (byte addressing)
    parameter RX_DBG     = "false",
    parameter TX_DBG     = "false",
    parameter RX8_DBG    = "false",
    parameter TX8_DBG    = "false"
    ) (
    input  wire        sysClk,
    input  wire        sysReset,
    input  wire        bitClk,
    input  wire        bitClk4x,

    input  wire        serialRxData,
    output wire        serialTxData,

    input  wire        sysRxEnable,
    input  wire        sysRxReady,
    output wire        sysRxValid,
    output wire        sysRxLast,
    output wire  [1:0] sysByteIndex,
    output wire [31:0] sysRxData,

    input  wire        sysTxStrobe,
    input  wire [31:0] sysTxData,
    input  wire        sysTxStart,
    output reg         sysTxBusy = 0);

//////////////////////////////////////////////////////////////////////////
// System clock domain packet transmission

reg [ADDR_WIDTH-1:0] sysTxLastIdx = 0;
reg [ADDR_WIDTH-3:0] sysTxAddr = 0;
reg sysTxToggle = 0, sysTxRbkToggle_m, sysTxRbkToggle;

reg [31:0] txBuf [0:(1<<(ADDR_WIDTH-2))-1];
reg [31:0] txBufQ;

always @(posedge sysClk) begin
    sysTxRbkToggle_m <= txRbkToggle;
    sysTxRbkToggle   <= sysTxRbkToggle_m;
    if (sysTxBusy) begin
        if (sysTxToggle == sysTxRbkToggle) begin
            sysTxBusy <= 0;
            sysTxAddr <= 0;
        end
    end
    else begin
        if (sysTxStrobe) begin
            txBuf[sysTxAddr] <= sysTxData;
            sysTxAddr <= sysTxAddr + 1;
        end
        if (sysTxStart) begin
            sysTxLastIdx <= sysTxData[16+:ADDR_WIDTH];
            sysTxBusy <= 1;
            sysTxToggle <= !sysTxToggle;
        end
    end
end

//////////////////////////////////////////////////////////////////////////
// bitClk domain packet transmission
// Made easier since we 'know' that we have several clock cycles
//to set up new TDATA/TLAST values after TREADY is asserted.

                          reg txToggle_m = 0;
(* mark_debug = TX_DBG *) reg txToggle = 0, txMatch = 0, txRbkToggle = 0;
(* mark_debug = TX_DBG *) reg txStart = 0, txActive = 0;
(* mark_debug = TX_DBG *) reg [ADDR_WIDTH-1:0] txAddr = 0;

// Read from dual-port RAM (little-endian)
wire [ADDR_WIDTH-3:0] txReadAddr;
assign txReadAddr = txAddr[ADDR_WIDTH-1:2];
always @(posedge bitClk) begin
    txBufQ <= txBuf[txReadAddr];
end

(* mark_debug = TX_DBG *) reg       txTLAST;
(* mark_debug = TX_DBG *) reg [7:0] txTDATA;
(* mark_debug = TX_DBG *) wire      txTREADY;

always @(posedge bitClk) begin
    txTDATA <= txBufQ[txAddr[1:0]*8+:8];
    txTLAST <= (txAddr == sysTxLastIdx);

    txToggle_m <= sysTxToggle;
    txToggle   <= txToggle_m;

    if (txActive) begin
        txStart <= 0;
        if (txTREADY) begin
            if (txTLAST) begin
                txActive <= 0;
                txRbkToggle <= txToggle;
            end
            else begin
                txAddr <= txAddr + 1;
            end
        end
    end
    else begin
        txAddr <= 0;
        if (txToggle != txMatch) begin
            txMatch <= !txMatch;
            txActive <= 1;
            txStart <= 1;
        end
    end
end

// Convert AXI stream to bit stream
tx8b9b #(.DEBUG(TX8_DBG))
  tx8b9b (.clk(bitClk),
          .start(txStart),
          .S_AXIS_TLAST(txTLAST),
          .S_AXIS_TDATA(txTDATA),
          .S_AXIS_TREADY(txTREADY),
          .dout(serialTxData));

//////////////////////////////////////////////////////////////////////////
// System clock domain packet reception

//////////////////////////////////////////////////////////////////////////
// bitClk domain packet reception

// AXI stream from 8b/9b deserializer
(* mark_debug = RX_DBG *) wire [7:0] rxTDATA;
(* mark_debug = RX_DBG *) wire       rxTVALID, rxTLAST;

// Reception state machine
reg reset_m, rxEnable_m;
(* mark_debug = RX_DBG *) reg        reset, rxEnable;
(* mark_debug = RX_DBG *) reg  [1:0] byteIndex = 0;
(* mark_debug = RX_DBG *) reg [23:0] byteBuf;

// Ensure that we start up in the idle gap between packets
(* mark_debug = RX_DBG *) reg        wasDisabled = 0;
                          reg  [3:0] gapTimer = 0;

// AXI stream to FIFO
(* mark_debug = RX_DBG *) wire [31:0] rxWordData;
(* mark_debug = RX_DBG *) wire        rxWordReady, rxWordValid, rxWordLast;

assign rxWordData = {rxTDATA, byteBuf};
assign rxWordValid = !wasDisabled && rxTVALID && (rxTLAST || (byteIndex == 3));
assign rxWordLast = rxTLAST;

// Reset everything if the FIFO fills up
(* mark_debug = RX_DBG *) wire disabled;
assign disabled = reset || !rxEnable || (rxWordValid && !rxWordReady);

always @(posedge bitClk) begin
    reset_m <= sysReset;
    reset   <= reset_m;
    rxEnable_m <= sysRxEnable;
    rxEnable   <= rxEnable_m;
    if (disabled) begin
        byteIndex <= 0;
        gapTimer <= ~0;
        wasDisabled <= 1;
    end
    else if (wasDisabled) begin
        if (rxTVALID) begin
            gapTimer <= ~0;
        end
        else if (gapTimer != 0) begin
            gapTimer <= gapTimer - 1;
        end
        else begin
            wasDisabled <= 0;
        end
    end
    else if (rxTVALID) begin
        if (rxTLAST) begin
            byteIndex <= 0;
        end
        else begin
            byteIndex <= byteIndex + 1;
        end
        byteBuf <= { rxTDATA, byteBuf[8+:16] };
    end
end

// Convert bit stream to AXI stream
rx8b9b #(.DEBUG(RX8_DBG))
  rx8b9b (.clk(bitClk),
          .clk4x(bitClk4x),
          .reset(reset),
          .din(serialRxData),
          .M_AXIS_TVALID(rxTVALID),
          .M_AXIS_TLAST(rxTLAST),
          .M_AXIS_TDATA(rxTDATA));

// Provide packet buffering and clock domain crossing
udpFIFO udpFIFO (
        .m_aclk(sysClk),
        .s_aclk(bitClk),
        .s_aresetn(!wasDisabled),
        .s_axis_tvalid(rxWordValid),
        .s_axis_tready(rxWordReady),
        .s_axis_tdata(rxWordData),
        .s_axis_tuser(byteIndex),
        .s_axis_tlast(rxWordLast),
        .m_axis_tvalid(sysRxValid),
        .m_axis_tready(sysRxReady),
        .m_axis_tdata(sysRxData),
        .m_axis_tuser(sysByteIndex),
        .m_axis_tlast(sysRxLast));

endmodule
