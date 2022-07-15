// Serialize FIR outputs then apply gain, clipping, offset, supply clipping,
// type conversion and scaling to produce AXI stream of floaing-point power
// supply setpoints (in Amperes).
// Assumes that din values remain stable for at least RESULT_COUNT+2 cycles
// after dinToggle changes state.
// No back pressure allowed on outgoing setpoints.

module psSetpointCalc #(
    parameter SOFT_START_STEPS = 1024,
    parameter RESULT_COUNT     = 24,
    parameter DIN_WIDTH        = 26,
    parameter DBUS_WIDTH       = 32,
    parameter FLOAT_WIDTH      = 32,
    parameter RESULT_COUNT_WIDTH = RESULT_COUNT == 1 ? 1 : $clog2(RESULT_COUNT)
    ) (
    input clk,
    input fofbEnabled,

    input                          gainWriteStrobe,
    input                          ffbClipWriteStrobe,
    input                          psOffsetWriteStrobe,
    input                          psClipWriteStrobe,
    input [RESULT_COUNT_WIDTH-1:0] writeAddress,
    input         [DBUS_WIDTH-1:0] writeData,

    input                              dinToggle,
    input [RESULT_COUNT*DIN_WIDTH-1:0] din,

    output wire                   SETPOINT_TVALID,
    output wire                   SETPOINT_TLAST,
    output wire [FLOAT_WIDTH-1:0] SETPOINT_TDATA);

localparam GAIN_WIDTH = 22;
localparam GAIN_INTEGER_WIDTH = 4;   // Gain range [0, 16)
localparam FOFB_TERM_WIDTH = DIN_WIDTH + GAIN_INTEGER_WIDTH;
// Output most negative value: -2^(CLIPPED_SETPOINT_WIDTH-10-1) mA
localparam SETPOINT_WIDTH = 28;
localparam UNCLIPPED_SETPOINT_WIDTH = SETPOINT_WIDTH + 1;

// Startup
// Soft gain adjustment
// Gain multiplication
// FFB clipping
// Offset addition
// Offset clipping
localparam ACTIVE_MSB = 6;
reg [ACTIVE_MSB:0] active = 0;

// Coefficient read addresses
reg [RESULT_COUNT_WIDTH-1:0] gainChannelIndex, dinMuxChannelIndex,
                             ffbClipChannelIndex, psOffsetChannelIndex,
                             psClipChannelIndex;
/////////////////////////////////////////////////////////////////////////////
// State machine control
reg dinMatch = 0;
reg [RESULT_COUNT_WIDTH-1:0] channelsLeft;
always @(posedge clk) begin
    if (active[0]) begin
        channelsLeft <= channelsLeft - 1;
        gainChannelIndex <= gainChannelIndex + 1;
        if (channelsLeft == 0) begin
            active[0] <= 0;
        end
    end
    else if (dinMatch != dinToggle) begin
        gainChannelIndex <= 0;
        dinMatch <= !dinMatch;
        channelsLeft<= RESULT_COUNT - 1;
        active[0] <= 1;
    end
    active[ACTIVE_MSB:1] <= active[ACTIVE_MSB-1:0];
    dinMuxChannelIndex   <= gainChannelIndex;
    ffbClipChannelIndex  <= dinMuxChannelIndex;
    psOffsetChannelIndex <= ffbClipChannelIndex;
    psClipChannelIndex   <= psOffsetChannelIndex;
end

/////////////////////////////////////////////////////////////////////////////
// Soft start/stop
localparam SOFT_START_FACTOR_WIDTH = 16;
localparam UNITY_SOFT_START_FACTOR = {1'b1, {SOFT_START_FACTOR_WIDTH-1{1'b0}}};
localparam SOFT_START_INCREMENT = UNITY_SOFT_START_FACTOR / SOFT_START_STEPS;
reg [SOFT_START_FACTOR_WIDTH-1:0] softStartFactor = 0;
wire [SOFT_START_FACTOR_WIDTH:0] signedSoftStartFactor = {1'b0,softStartFactor};
always @(posedge clk) begin
    if (active[0] && !active[1]) begin
        if (fofbEnabled) begin
            if (softStartFactor >
                   (UNITY_SOFT_START_FACTOR - SOFT_START_INCREMENT)) begin
                softStartFactor <= UNITY_SOFT_START_FACTOR;
            end
            else begin
                softStartFactor <= softStartFactor + SOFT_START_INCREMENT;
            end
        end
        else begin
            if (softStartFactor < SOFT_START_INCREMENT) begin
                softStartFactor <= 0;
            end
            else begin
                softStartFactor <= softStartFactor - SOFT_START_INCREMENT;
            end
        end
    end
end

/////////////////////////////////////////////////////////////////////////////
// Serialize FIR outputs and apply gains
reg [GAIN_WIDTH-1:0] gains [0:RESULT_COUNT-1], gainQ;
always @(posedge clk) begin
    if (gainWriteStrobe) begin
        gains[writeAddress] <= writeData[GAIN_WIDTH-1:0];
    end
end

// DSP multipliers are signed so pad unsigned gain with MSB=0.
wire signed [GAIN_WIDTH:0] signedGainQ = { 1'b0, gainQ };
reg signed [(GAIN_WIDTH+SOFT_START_FACTOR_WIDTH+2)-1:0] adjustedGainProduct;
wire [GAIN_WIDTH-1:0] adjustedGain =
                     adjustedGainProduct[SOFT_START_FACTOR_WIDTH-1+:GAIN_WIDTH];
wire signed [GAIN_WIDTH:0] signedAdjustedGain = {1'b0, adjustedGain};

reg signed [DIN_WIDTH-1:0] dinMux;
localparam DIN_SCALED_WIDTH = DIN_WIDTH + GAIN_WIDTH + 1;
reg signed [DIN_SCALED_WIDTH-1:0] dinScaled;

always @(posedge clk) begin
    gainQ <= gains[gainChannelIndex];
    adjustedGainProduct <= signedGainQ * signedSoftStartFactor;
    // Apply negative gain since the dinMux term is based on
    // feedback minus setpoint rather than the conventional
    // arrangement where the controller input (error signal)
    // is setpoint minus feedback.
    dinMux <= din[dinMuxChannelIndex*DIN_WIDTH+:DIN_WIDTH];
    dinScaled <= dinMux * -signedAdjustedGain;
end
wire signed [FOFB_TERM_WIDTH-1:0] ffbTerm =
                      dinScaled[GAIN_WIDTH-GAIN_INTEGER_WIDTH+:FOFB_TERM_WIDTH];

/////////////////////////////////////////////////////////////////////////////
// Clip fast feedback term
reg signed [SETPOINT_WIDTH-1:0] ffbTermClipped;
reg signed [SETPOINT_WIDTH-1:0] ffbClipLevels [0:RESULT_COUNT-1], ffbClipLevelQ;
always @(posedge clk) begin
    ffbClipLevelQ <= ffbClipLevels[ffbClipChannelIndex];
    if (ffbClipWriteStrobe) begin
        ffbClipLevels[writeAddress] <= writeData[SETPOINT_WIDTH-1:0];
    end
    if (ffbTerm > ffbClipLevelQ) begin
        ffbTermClipped <= ffbClipLevelQ;
    end
    else if (ffbTerm < -ffbClipLevelQ) begin
        ffbTermClipped <= -ffbClipLevelQ;
    end
    else begin
        ffbTermClipped <= ffbTerm;
    end
end

/////////////////////////////////////////////////////////////////////////////
// Merge fast and slow orbit feedback terms
reg signed [SETPOINT_WIDTH-1:0] psOffsets [0:RESULT_COUNT-1], psOffsetQ;
reg signed [UNCLIPPED_SETPOINT_WIDTH-1:0] unclippedSetpoint;
always @(posedge clk) begin
    psOffsetQ <= psOffsets[psOffsetChannelIndex];
    if (psOffsetWriteStrobe) begin
        psOffsets[writeAddress] <= writeData[SETPOINT_WIDTH-1:0];
    end
    unclippedSetpoint <= psOffsetQ + ffbTermClipped;
end

/////////////////////////////////////////////////////////////////////////////
// Clip to supply limits
reg signed [SETPOINT_WIDTH-1:0] psClipLevels [0:RESULT_COUNT-1], psClipLevelQ;
reg signed [SETPOINT_WIDTH-1:0] psClippedSetpoint;
always @(posedge clk) begin
    psClipLevelQ <= psClipLevels[psClipChannelIndex];
    if (psClipWriteStrobe) begin
        psClipLevels[writeAddress] <= writeData[SETPOINT_WIDTH-1:0];
    end
    if (unclippedSetpoint > psClipLevelQ) begin
        psClippedSetpoint <= psClipLevelQ;
    end
    else if (unclippedSetpoint < -psClipLevelQ) begin
        psClippedSetpoint <= -psClipLevelQ;
    end
    else begin
        psClippedSetpoint <= unclippedSetpoint[SETPOINT_WIDTH-1:0];
    end
end

/////////////////////////////////////////////////////////////////////////////
// Convert to floating point
localparam AXI_PAD_WIDTH = 8 - (SETPOINT_WIDTH % 8);
wire intClippedTVALID = active[ACTIVE_MSB];
wire intClippedTLAST = active[ACTIVE_MSB] && !active[ACTIVE_MSB-1];
wire floatClippedTVALID, floatClippedTLAST;
wire [FLOAT_WIDTH-1:0] floatClippedTDATA;
`ifndef SIMULATE
psSetpointCalcFixToFloat psSetpointCalcFixToFloat (
    .aclk(clk),
    .s_axis_a_tvalid(intClippedTVALID),
    .s_axis_a_tlast(intClippedTLAST),
    .s_axis_a_tdata({{AXI_PAD_WIDTH{1'bx}}, psClippedSetpoint}),
    .m_axis_result_tvalid(floatClippedTVALID),
    .m_axis_result_tlast(floatClippedTLAST),
    .m_axis_result_tdata(floatClippedTDATA));
`endif

/////////////////////////////////////////////////////////////////////////////
// Convert mA*2^-10 to A
`ifndef SIMULATE
psSetpointCalcConvertToAmps psSetpointCalcConvertToAmps (
    .aclk(clk),
    .s_axis_a_tvalid(floatClippedTVALID),
    .s_axis_a_tlast(floatClippedTLAST),
    .s_axis_a_tdata(floatClippedTDATA),
    .s_axis_b_tvalid(1'b1),
    .s_axis_b_tdata(32'h3583126f),   // 1.0 / (1000 * 1024)
    .m_axis_result_tvalid(SETPOINT_TVALID),
    .m_axis_result_tlast(SETPOINT_TLAST),
    .m_axis_result_tdata(SETPOINT_TDATA));
`endif

endmodule
