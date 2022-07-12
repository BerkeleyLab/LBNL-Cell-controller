//
// Keep track of link statistics
//
module linkStatistics #(
    parameter dbg = "false") (
    input  wire auroraUserClk,

    (* mark_debug = dbg *) input  wire       bpmCCWstatusStrobe,
    (* mark_debug = dbg *) input  wire [1:0] bpmCCWstatusCode,

    (* mark_debug = dbg *) input  wire       bpmCWstatusStrobe,
    (* mark_debug = dbg *) input  wire [1:0] bpmCWstatusCode,

    // All remaining nets are in system clock domain
    input  wire sysClk,
    (* mark_debug = dbg *) input  wire       sysStatusStrobe,
    (* mark_debug = dbg *) input  wire [2:0] sysStatusCode,
    (* mark_debug = dbg *) input  wire        sysTimeoutStrobe,

    (* mark_debug = dbg *) input wire         sysCsrStrobe,
    (* mark_debug = dbg *) input  wire [31:0] GPIO_OUT,
    (* mark_debug = dbg *) output reg  [31:0] sysValue);

// AXI stream multiplexer to merge  update requests and cross clock domains.
// Wider than actually needed, but AXI requires multiples of 8 bits, and
// using AXI is a lot easier than rolling our own.
// 32-deep normal-mode FIFO on all incoming links.
(* mark_debug = dbg *) wire [7:0] mergedTDATA;
(* mark_debug = dbg *) wire       mergedTVALID;
(* mark_debug = dbg *) reg        mergedTREADY = 0;
linkStatisticsMux linkStatisticsMux (
  .ACLK(auroraUserClk),
  .ARESETN(1'b1),
  .S00_AXIS_ACLK(auroraUserClk),
  .S01_AXIS_ACLK(auroraUserClk),
  .S02_AXIS_ACLK(sysClk),
  .S03_AXIS_ACLK(sysClk),
  .S00_AXIS_ARESETN(1'b1),
  .S01_AXIS_ARESETN(1'b1),
  .S02_AXIS_ARESETN(1'b1),
  .S03_AXIS_ARESETN(1'b1),
  .S00_AXIS_TVALID(bpmCCWstatusStrobe),
  .S01_AXIS_TVALID(bpmCWstatusStrobe),
  .S02_AXIS_TVALID(sysStatusStrobe),
  .S03_AXIS_TVALID(sysTimeoutStrobe),
  .S00_AXIS_TDATA({3'b0, 1'b0, 1'b0, 1'b0, bpmCCWstatusCode}),
  .S01_AXIS_TDATA({3'b0, 1'b0, 1'b0, 1'b1, bpmCWstatusCode}),
  .S02_AXIS_TDATA({3'b0, 1'b0, 1'b1, sysStatusCode}),
  .S03_AXIS_TDATA({3'b0, 1'b1, 1'b1, 1'b1, 2'd3}),
  .M00_AXIS_ACLK(sysClk),
  .M00_AXIS_ARESETN(1'b1),
  .M00_AXIS_TVALID(mergedTVALID),
  .M00_AXIS_TREADY(mergedTREADY),
  .M00_AXIS_TDATA(mergedTDATA),
  .S00_ARB_REQ_SUPPRESS(1'b0),
  .S01_ARB_REQ_SUPPRESS(1'b0),
  .S02_ARB_REQ_SUPPRESS(1'b0),
  .S03_ARB_REQ_SUPPRESS(1'b0));


// Statistics histogram dual-port RAM
// 5 monitoring points (BPM CCW/CW, Cell CCW/CW, timeout)
// 4 codes per point
localparam DPRAM_ADDR_WIDTH = 5;
localparam DPRAM_WIDTH = 48;

(* mark_debug = dbg *) wire                        wenA;
(* mark_debug = dbg *) wire      [DPRAM_WIDTH-1:0] dinA, doutA, doutB;
(* mark_debug = dbg *) wire [DPRAM_ADDR_WIDTH-1:0] addrA;
(* mark_debug = dbg *) reg  [DPRAM_ADDR_WIDTH-1:0] addrB, clearCount = 0;
(* mark_debug = dbg *) reg                         wordSel;
(* mark_debug = dbg *) reg clearToggle = 0, clearMatch = 0, clearing = 0;
reg sysTimeoutToggle_d = 0;

assign addrA = clearing ? clearCount : mergedTDATA[DPRAM_ADDR_WIDTH-1:0];
assign dinA = clearing ? {DPRAM_WIDTH{1'b0}} : doutA + 1;
assign wenA = clearing || mergedTREADY;

always @(posedge sysClk) begin
    if (clearing) begin
        if (clearCount == {DPRAM_ADDR_WIDTH{1'b1}}) begin
            clearing <= 0;
        end
        else begin
            clearCount <= clearCount + 1;
        end
    end
    else if ((clearToggle != clearMatch) && !mergedTREADY) begin
        clearMatch <= !clearMatch;
        clearCount <= 0;
        clearing <= 1;
    end
    else if (mergedTVALID && !mergedTREADY) begin
        mergedTREADY <= 1;
    end
    else begin
        mergedTREADY <= 0;
    end
    if (sysCsrStrobe) begin
        if (GPIO_OUT[31]) clearToggle <= !clearToggle;
        addrB <= GPIO_OUT[1+:DPRAM_ADDR_WIDTH];
        wordSel <= GPIO_OUT[0];
    end
    sysValue <= wordSel ? { {64-DPRAM_WIDTH{1'b0}}, doutB[32+:DPRAM_WIDTH-32] }
                        : doutB[0+:32];
end

linkStatisticsDPRAM #(.ADDR_WIDTH(DPRAM_ADDR_WIDTH),
                      .DATA_WIDTH(DPRAM_WIDTH))
  linkStatisticsDPRAM (
       .clk(sysClk),
       .addra(addrA),
       .wea(wenA),
       .dina(dinA),
       .douta(doutA),
       .addrb(addrB),
       .doutb(doutB));

endmodule

// Dual port RAM for link statistics
module linkStatisticsDPRAM #(
        parameter ADDR_WIDTH = 5,
        parameter DATA_WIDTH = 48) (
        input  wire                  clk,
        input  wire [ADDR_WIDTH-1:0] addra,
        input  wire                  wea,
        input  wire [DATA_WIDTH-1:0] dina,
        output wire [DATA_WIDTH-1:0] douta,
        input  wire [ADDR_WIDTH-1:0] addrb,
        output wire [DATA_WIDTH-1:0] doutb);

reg [DATA_WIDTH-1:0] dpram[0:(1<<ADDR_WIDTH)-1];
reg [DATA_WIDTH-1:0] rega, regb;
assign douta = rega;
assign doutb = regb;

always @(posedge clk) begin
    if (wea) dpram[addra] <= dina;
    rega <= dpram[addra];
    regb <= dpram[addrb];
end

endmodule
