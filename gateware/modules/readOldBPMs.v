// Convert and store multicasted beam position errors.
// Data is high word only of double precision floating value.
//  Write index reg, write hi word reg
// Firmware will add 32 zeros for low word, convert to single
// precision, multiply by 1e6 to convert to nm, convert to
// integer and store.
module readOldBPMs #(
    parameter DEBUG = "false"
    ) (
    input  wire                clk,
    (* mark_debug = DEBUG *)
    input  wire                indexStrobe,
    (* mark_debug = DEBUG *)
    input  wire                dataStrobe,
    (* mark_debug = DEBUG *)
    input  wire         [31:0] gpioOut,
    (* mark_debug = DEBUG *)
    output wire                fifoTVALID,
    (* mark_debug = DEBUG *)
    output wire         [63:0] fifoTDATA,
    (* mark_debug = DEBUG *)
    output wire          [6:0] fifoTUSER,
    (* mark_debug = DEBUG *)
    input  wire                fifoTREADY);

localparam FOFB_INDEX_WIDTH = 9;
localparam TUSER_WIDTH = FOFB_INDEX_WIDTH + 1; // Plane, Index
reg [31:0] indexLatch;
always @(posedge clk) begin
    if (indexStrobe) indexLatch <= gpioOut;
end

// Convert double precision mm to single precision
wire                   floatTVALID;
wire            [31:0] floatTDATA;
wire [TUSER_WIDTH-1:0] floatTUSER;
`ifndef SIMULATE
readOldBPMs_DoubleToFloat doubleToFloat (
    .aclk(clk),
    .s_axis_a_tvalid(dataStrobe),
    .s_axis_a_tdata({gpioOut, indexLatch[31:24], 24'b0}),
    .s_axis_a_tuser(indexLatch[TUSER_WIDTH-1:0]),
    .m_axis_result_tvalid(floatTVALID),
    .m_axis_result_tdata(floatTDATA),
    .m_axis_result_tuser(floatTUSER));
`endif

// Convert single precision mm to single precision nm
wire                   productTVALID;
wire            [31:0] productTDATA;
wire [TUSER_WIDTH-1:0] productTUSER;
`ifndef SIMULATE
readOldBPMs_Multiply multiply (
    .aclk(clk),
    .s_axis_a_tvalid(floatTVALID),
    .s_axis_a_tdata(floatTDATA),
    .s_axis_a_tuser(floatTUSER),
    .s_axis_b_tvalid(1'b1),
    .s_axis_b_tdata(32'h49742400),
    .m_axis_result_tvalid(productTVALID),
    .m_axis_result_tdata(productTDATA),
    .m_axis_result_tuser(productTUSER));
`endif

// Convert single precision nm to integer nm
(* mark_debug = DEBUG *) wire                   nmTVALID;
(* mark_debug = DEBUG *) wire            [31:0] nmTDATA;
(* mark_debug = DEBUG *) wire [TUSER_WIDTH-1:0] nmTUSER;
`ifndef SIMULATE
readOldBPMs_Fix fix (
    .aclk(clk),
    .s_axis_a_tvalid(productTVALID),
    .s_axis_a_tdata(productTDATA),
    .s_axis_a_tuser(productTUSER),
    .m_axis_result_tvalid(nmTVALID),
    .m_axis_result_tdata(nmTDATA),
    .m_axis_result_tuser(nmTUSER));
`endif

// Latch X data
reg [31:0] xLatch;
always @(posedge clk) begin
    if (nmTVALID && (nmTUSER[TUSER_WIDTH-1] == 0)) begin
        xLatch <= nmTDATA;
    end
end

// Buffer values
// A 16-deep FIFO is adequate since that's the
// most that can be in a single cPCI packet.
`ifndef SIMULATE
readOldBPMs_FIFO fifo (
    .s_axis_aresetn(1'b1),
    .s_axis_aclk(clk),
    .s_axis_tvalid(nmTVALID && (nmTUSER[TUSER_WIDTH-1] == 1)),
    .s_axis_tdata({nmTDATA, xLatch}),
    .s_axis_tuser(nmTUSER[6:0]),
    .m_axis_tvalid(fifoTVALID),
    .m_axis_tready(fifoTREADY),
    .m_axis_tdata(fifoTDATA),
    .m_axis_tuser(fifoTUSER));
`endif

endmodule
