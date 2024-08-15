/*
 * Register-access wrapper around multi-input frequency counter
 */
module frequencyCounters #(
    parameter NF       = 2,
    parameter CLK_RATE = 100000000,
    parameter DEBUG    = "false"
    ) (
    input         clk,
    input         csrStrobe,
    input  [31:0] GPIO_OUT,
    output [31:0] status,

    input [NF-1:0] unknownClocks,
    input          ppsMarker_a);

localparam TICKS_RELOAD = CLK_RATE - 2;
localparam TICKS_WIDTH = $clog2(TICKS_RELOAD+1) + 1;
reg [TICKS_WIDTH-1:0] ticks = TICKS_RELOAD;
wire ppsStrobeInternal = ticks[TICKS_WIDTH-1];

localparam WATCHDOG_RELOAD = ((CLK_RATE / 10) * 11) - 2;
localparam WATCHDOG_WIDTH = $clog2(WATCHDOG_RELOAD+1) + 1;
(*MARK_DEBUG=DEBUG*) reg [WATCHDOG_WIDTH-1:0] watchdog = ~0;
wire watchdogTimeout = watchdog[WATCHDOG_WIDTH-1];
assign useInternalPPSmarker = watchdogTimeout;

(*ASYNC_REG="true"*) reg ppsMarker_m;
(*MARK_DEBUG=DEBUG*) reg ppsMarker_d0, ppsMarker_d1, ppsStrobeExternal;

(*MARK_DEBUG=DEBUG*) reg usedInternalPPSmarker = 0;
(*MARK_DEBUG=DEBUG*) reg ppsStrobe = 0;

localparam SELECT_WIDTH = (NF==1) ? 1 : $clog2(NF);
reg [SELECT_WIDTH-1:0] frequencyMonitorSelect;

/* Common code to select readout and acquisition marker */
always @(posedge clk) begin
   /* Keep track of time */
    if (ppsStrobeInternal) begin
        ticks <= TICKS_RELOAD;
    end
    else begin
        ticks <= ticks - 1;
    end

    /* Sample asynchronous external acquisition marker */
    ppsMarker_m  <= ppsMarker_a;
    ppsMarker_d0 <= ppsMarker_m;
    ppsMarker_d1 <= ppsMarker_d0;
    ppsStrobeExternal <= ppsMarker_d0 && !ppsMarker_d1;

    /* Maintain watchdog */
    if (ppsStrobeExternal) begin
        watchdog <= WATCHDOG_RELOAD;
    end
    else if (!watchdogTimeout) begin
        watchdog <= watchdog - 1;
    end

    /* Generate acquisition marker strobe */
    ppsStrobe <= useInternalPPSmarker ? ppsStrobeInternal : ppsStrobeExternal;
    if (ppsStrobe) begin
        usedInternalPPSmarker <= useInternalPPSmarker;
    end

    /* Emit selected value */
    if (csrStrobe) begin
        frequencyMonitorSelect <= GPIO_OUT[SELECT_WIDTH-1:0];
    end
end

wire [29:0] measuredFrequency;

assign status = { usedInternalPPSmarker, 1'b0, measuredFrequency };

freq_multi_count #(
        .NF(NF),  // number of frequency counters in a block
        .NG(1),  // number of frequency counter blocks
        .gw(4),  // Gray counter width
        .cw(1),  // macro-cycle counter width
        .rw($clog2(CLK_RATE*4/3)), // reference counter width
        .uw(30)) // unknown counter width
  freq_multi_count_i (
    .unk_clk(unknownClocks),
    .refclk(clk),
    .refMarker(ppsStrobe),
    .source_state(),
    .addr(frequencyMonitorSelect),
    .frequency(measuredFrequency));

endmodule
