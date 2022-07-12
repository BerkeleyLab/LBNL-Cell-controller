// Gather data from outgoing stream into DPRAM
module fofbReadLink #(
    parameter  FOFB_INDEX_WIDTH = 9,
    parameter  CELL_INDEX_WIDTH = 5,
                            dbg = "false") (
    // Cell link
                       input  wire        auroraClk,
    (*mark_debug=dbg*) input  wire        FAstrobe,
    (*mark_debug=dbg*) input  wire        allBPMpresent,
    (*mark_debug=dbg*) input  wire        TVALID,
    (*mark_debug=dbg*) input  wire        TLAST,
    (*mark_debug=dbg*) input  wire [31:0] TDATA,

    // Link statistics
    (*mark_debug=dbg*) output wire                            statusStrobe,
    (*mark_debug=dbg*) output reg                       [1:0] statusCode,
    (*mark_debug=dbg*) output reg                             statusFOFBenabled,
    (*mark_debug=dbg*) output reg      [CELL_INDEX_WIDTH-1:0] statusCellIndex,

                       output reg [(1<<FOFB_INDEX_WIDTH)-1:0] bpmBitmap,
                       output reg        [CELL_INDEX_WIDTH:0] cellCounter,

    // Readout (system clock domain)
                       input  wire                        sysClk,
    (*mark_debug=dbg*) input  wire [FOFB_INDEX_WIDTH-1:0] readoutAddress,
    (*mark_debug=dbg*) output wire                 [31:0] readoutX,
    (*mark_debug=dbg*) output wire                 [31:0] readoutY,
    (*mark_debug=dbg*) output wire                 [31:0] readoutS);

//
// Dissect header
//
wire                 [15:0] headerMagic       = TDATA[31:16];
wire                        headerFOFBenabled = TDATA[15];
wire [CELL_INDEX_WIDTH-1:0] headerCellIndex   = TDATA[10+:CELL_INDEX_WIDTH];
wire [FOFB_INDEX_WIDTH-1:0] headerFOFBindex   = TDATA[0+:FOFB_INDEX_WIDTH];
reg  [FOFB_INDEX_WIDTH-1:0] fofbIndex;

//
// Reception statistics
//
localparam ST_SUCCESS    = 2'd0,
           ST_BAD_HEADER = 2'd1,
           ST_BAD_SIZE   = 2'd2,
           ST_BAD_PACKET = 2'd3;

//
// Reception state machine
//
localparam S_AWAIT_HEADER      = 3'd0,
           S_AWAIT_X           = 3'd1,
           S_AWAIT_Y           = 3'd2,
           S_AWAIT_S           = 3'd4,
           S_AWAIT_LAST        = 3'd5;
(*mark_debug=dbg*) reg  [2:0] state = S_AWAIT_HEADER;
(*mark_debug=dbg*) reg [31:0] dataX, dataY, dataS;
reg statusToggle = 0, statusToggle_d = 0;
assign statusStrobe = (statusToggle != statusToggle_d);
reg writeToggle = 0, writeToggle_d = 0;
wire writeEnable = (writeToggle != writeToggle_d);
reg [(1<<FOFB_INDEX_WIDTH)-1:0] packetBPMmap;
(*mark_debug=dbg*) reg isNewPacket = 0;
(*mark_debug=dbg*) reg updateBPMmapToggle = 0, updateBPMmapToggle_d = 0;

always @(posedge auroraClk) begin
    statusToggle_d <= statusToggle;
    writeToggle_d <= writeToggle;
    updateBPMmapToggle_d <= updateBPMmapToggle;
    if (FAstrobe) begin
        bpmBitmap <= 0;
        state <= S_AWAIT_HEADER;
        isNewPacket <= 1;
        cellCounter <= 0;
    end
    else begin
        if (updateBPMmapToggle != updateBPMmapToggle_d)
                                         bpmBitmap <= bpmBitmap | packetBPMmap;
        if (TVALID) begin
            if (TLAST && !state[2]) begin
                statusCode <= ST_BAD_SIZE;
                statusToggle <= !statusToggle;
                isNewPacket <= 1;
                state <= S_AWAIT_HEADER;
            end
            else begin
                case (state)
                S_AWAIT_HEADER: begin
                    if (isNewPacket) begin
                        isNewPacket <= 0;
                        packetBPMmap <= 0;
                    end
                    if (headerMagic == 16'hA5BE) begin
                        statusCellIndex <= headerCellIndex;
                        fofbIndex <= headerFOFBindex;
                        statusFOFBenabled <= headerFOFBenabled;
                        state <= S_AWAIT_X;
                    end
                    else begin
                        statusCode <= ST_BAD_HEADER;
                        statusToggle <= !statusToggle;
                        isNewPacket <= 1;
                        state <= S_AWAIT_LAST;
                    end
                end

                S_AWAIT_X: begin
                    dataX <= TDATA;
                    state <= S_AWAIT_Y;
                end

                S_AWAIT_Y: begin
                    dataY <= TDATA;
                    state <= S_AWAIT_S;
                end

                S_AWAIT_S: begin
                    dataS <= TDATA;
                    if (!TDATA[31]) begin
                        packetBPMmap[fofbIndex] <= 1;
                        if (!allBPMpresent) writeToggle <= !writeToggle;
                    end
                    if (TLAST) begin
                        isNewPacket <= 1;
                        if (TDATA[30]) begin
                            statusCode <= ST_BAD_PACKET;
                        end
                        else begin
                            if (!allBPMpresent) 
                                      updateBPMmapToggle <= !updateBPMmapToggle;
                            statusCode <= ST_SUCCESS;
                            cellCounter <= cellCounter + 1;
                        end
                        statusToggle <= !statusToggle;
                    end
                    state <= S_AWAIT_HEADER;
                end

                S_AWAIT_LAST: begin
                    if (TLAST) begin
                        state <= S_AWAIT_HEADER;
                    end
                end
                default: ;
                endcase
            end
        end
    end
end

// Readout DPRAM
reg [95:0] dpram [0:(1<<FOFB_INDEX_WIDTH)-1];
reg [95:0] dpramQ;
assign readoutX = dpramQ[0+:32];
assign readoutY = dpramQ[32+:32];
assign readoutS = dpramQ[64+:32];
always @(posedge auroraClk) begin
    if (writeEnable) dpram[fofbIndex] <= {dataS, dataY, dataX};
end
always @(posedge sysClk) begin
    dpramQ <= dpram[readoutAddress];
end

endmodule
