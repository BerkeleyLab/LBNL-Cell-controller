//
// Forward packets from incoming cell stream and
// local data stream to outgoing cell stream.
//
module forwardCellLink #(
    parameter dbg = "false" ) (
                       input  wire        auroraUserClk,
(* mark_debug = dbg *) input  wire        auroraFAstrobe,

(* mark_debug = dbg *) input  wire        cellLinkRxTVALID,
(* mark_debug = dbg *) input  wire        cellLinkRxTLAST,
(* mark_debug = dbg *) input  wire [31:0] cellLinkRxTDATA,
(* mark_debug = dbg *) input  wire        cellLinkRxCRCvalid,
(* mark_debug = dbg *) input  wire        cellLinkRxCRCpass,

(* mark_debug = dbg *) input  wire        localRxTVALID,
(* mark_debug = dbg *) input  wire        localRxTLAST,
(* mark_debug = dbg *) input  wire [31:0] localRxTDATA,

(* mark_debug = dbg *) output reg         cellLinkTxTVALID,
(* mark_debug = dbg *) output reg         cellLinkTxTLAST,
(* mark_debug = dbg *) output reg  [31:0] cellLinkTxTDATA);

localparam MAX_CELLS = 32;
// Should be a localparam, but Vivado doesn't handle $clog2 there.
parameter CELL_INDEX_WIDTH = $clog2(MAX_CELLS);

// Reset everything at beginning of FA interval
reg [3:0] muxResetStretch;
(* mark_debug = dbg *) reg muxReset = 1;

// Don't babble on
(* mark_debug = dbg *) reg [6:0] watchdog;
(* mark_debug = dbg *) reg       timeout;

// Merge incoming and local streams
(* mark_debug = dbg *) wire        mergedRxTVALID;
(* mark_debug = dbg *) wire        mergedRxTLAST;
(* mark_debug = dbg *) wire [31:0] mergedRxTDATA;

// Dissect header
wire                 [15:0] mergedHeaderMagic = mergedRxTDATA[31:16];
wire [CELL_INDEX_WIDTH-1:0] mergedCellIndex=mergedRxTDATA[10+:CELL_INDEX_WIDTH];

// Keep track of the cells we've transmitted
(* mark_debug = dbg *) reg [MAX_CELLS-1:0] txBitmap;
(* mark_debug = dbg *) reg                 inPacket = 0, transmitting = 0;

// A one in the most significant bit of the final word
// indicates an invalid BPM to cell controller packet.
// A one in the next-to-most significant bit of the final word
// indicates an invalid cellcontroller to cell controller packet.
(* mark_debug = dbg *) wire [31:0] cellLinkRxForwardData = {
            cellLinkRxTDATA[31],
            cellLinkRxTLAST && (!cellLinkRxCRCvalid || !cellLinkRxCRCpass) ?
                                                     1'b1 : cellLinkRxTDATA[30],
            cellLinkRxTDATA[29:0] };

always @(posedge auroraUserClk) begin
    if (auroraFAstrobe) begin
        cellLinkTxTVALID <= 0;
        txBitmap <= 0;
        inPacket <= 0;
        transmitting <= 0;
        muxReset <= 1;
        muxResetStretch <= ~0;
    end
    else if (muxReset) begin
        muxResetStretch <= muxResetStretch - 1;
        if (muxResetStretch == 0) muxReset <= 0;
    end
    else if (inPacket) begin
        cellLinkTxTDATA <= mergedRxTDATA;
        if (transmitting) begin
            watchdog <= watchdog - 1;
            if (watchdog == 0) timeout <= 1;
            if (mergedRxTVALID || timeout) begin
                cellLinkTxTVALID <= 1;
                if (mergedRxTLAST || timeout) begin
                    cellLinkTxTLAST <= 1;
                    transmitting <= 0;
                end
            end
            else begin
                cellLinkTxTVALID <= 0;
            end
        end
        else begin
            cellLinkTxTVALID <= 0;
        end
        if (mergedRxTVALID && mergedRxTLAST) begin
            inPacket <= 0;
        end
    end
    else if (mergedRxTVALID && !mergedRxTLAST) begin
        inPacket <= 1;
        watchdog <= ~0;
        timeout <= 0;
        if ((mergedHeaderMagic != 16'hA5BE) || txBitmap[mergedCellIndex]) begin
            cellLinkTxTVALID <= 0;
            transmitting <= 0;
        end
        else begin
            txBitmap[mergedCellIndex] <= 1;
            cellLinkTxTVALID <= 1;
            cellLinkTxTLAST <= 0;
            cellLinkTxTDATA <= mergedRxTDATA;
            transmitting <= 1;
        end
    end
    else begin
        cellLinkTxTVALID <= 0;
    end
end

// Merge incoming and local streams
// 256-deep packet-mode FIFO on incoming cell stream and on local stream
forwardCellLinkMux forwardCellLinkMux (.ACLK(auroraUserClk),
                                       .ARESETN(~muxReset),
                                       .S00_AXIS_ACLK(auroraUserClk),
                                       .S01_AXIS_ACLK(auroraUserClk),
                                       .S00_AXIS_ARESETN(~muxReset),
                                       .S01_AXIS_ARESETN(~muxReset),
                                       .S00_AXIS_TVALID(cellLinkRxTVALID),
                                       .S00_AXIS_TDATA(cellLinkRxForwardData),
                                       .S00_AXIS_TLAST(cellLinkRxTLAST),
                                       .S01_AXIS_TVALID(localRxTVALID),
                                       .S01_AXIS_TDATA(localRxTDATA),
                                       .S01_AXIS_TLAST(localRxTLAST),
                                       .M00_AXIS_ACLK(auroraUserClk),
                                       .M00_AXIS_ARESETN(~muxReset),
                                       .M00_AXIS_TVALID(mergedRxTVALID),
                                       .M00_AXIS_TREADY(1'b1),
                                       .M00_AXIS_TDATA(mergedRxTDATA),
                                       .M00_AXIS_TLAST(mergedRxTLAST),
                                       .S00_ARB_REQ_SUPPRESS(1'b0),
                                       .S01_ARB_REQ_SUPPRESS(1'b0));

endmodule
