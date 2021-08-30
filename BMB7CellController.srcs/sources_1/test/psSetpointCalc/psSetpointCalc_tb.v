`timescale 1 ns /  1ns

module psSetpointCalc_tb;

parameter SOFT_START_STEPS   = 4;
parameter RESULT_COUNT       = 24;
parameter DIN_WIDTH          = 26;
parameter DBUS_WIDTH         = 32;
parameter GAIN_WIDTH         = 22;
parameter GAIN_INTEGER_WIDTH = 4;  /* gain range [0,16) */
parameter PS_OFFSET_WIDTH    = 28;
parameter RESULT_WIDTH       = 32;

parameter CLIP_WIDTH = PS_OFFSET_WIDTH;
parameter RESULT_COUNT_WIDTH = RESULT_COUNT == 1 ? 1 : $clog2(RESULT_COUNT);

reg clk = 1;
reg gainWriteStrobe = 0;
reg ffbClipWriteStrobe = 0;
reg psOffsetWriteStrobe = 0;
reg psClipWriteStrobe = 0;
reg [RESULT_COUNT_WIDTH-1:0] writeAddress;
reg [DBUS_WIDTH-1:0] GPIO_OUT;
wire [RESULT_COUNT*DIN_WIDTH-1:0] din;
reg dinToggle = 0;
reg ffbEnabled = 0;
wire SETPOINT_TVALID, SETPOINT_TLAST;
wire [RESULT_WIDTH-1:0] SETPOINT_TDATA;

// Device under test
psSetpointCalc #(
    .SOFT_START_STEPS(SOFT_START_STEPS),
    .RESULT_COUNT(RESULT_COUNT),
    .DIN_WIDTH(DIN_WIDTH),
    .DBUS_WIDTH(DBUS_WIDTH))
  psSetpointCalc (
    .clk(clk),
    .ffbEnabled(ffbEnabled),
    .gainWriteStrobe(gainWriteStrobe),
    .ffbClipWriteStrobe(ffbClipWriteStrobe),
    .psOffsetWriteStrobe(psOffsetWriteStrobe),
    .psClipWriteStrobe(psClipWriteStrobe),
    .writeAddress(writeAddress),
    .writeData(GPIO_OUT),
    .dinToggle(dinToggle),
    .din(din),
    .SETPOINT_TVALID(SETPOINT_TVALID),
    .SETPOINT_TLAST(SETPOINT_TLAST),
    .SETPOINT_TDATA(SETPOINT_TDATA));

wire [GAIN_WIDTH-1:0] unityGain = 1 << (GAIN_WIDTH - GAIN_INTEGER_WIDTH);

// Produce test data
reg signed [DIN_WIDTH-1:0] dinBase = 0;
genvar c;
generate
    for(c = 0 ; c < RESULT_COUNT ; c = c + 1) begin
        assign din[c*DIN_WIDTH+:DIN_WIDTH] = dinBase + c;
    end
endgenerate

// Check results
reg [GAIN_WIDTH-1:0] gains [0:RESULT_COUNT-1];
reg [CLIP_WIDTH-1:0] ffbClipLevels [0:RESULT_COUNT-1];
reg signed [PS_OFFSET_WIDTH-1:0] psOffsets [0:RESULT_COUNT-1];
reg [CLIP_WIDTH-1:0] psClipLevels [0:RESULT_COUNT-1];
reg signed [31:0] expect;
integer fail = 0, idx = 0, ig, softNum = 0, ffbLimit, ffbTerm, psLimit;
always @(posedge clk) begin
    if (SETPOINT_TVALID) begin
        ig = $rtoi($itor(gains[idx]) / unityGain);
        ffbTerm = ((dinBase + idx) * ig * softNum) / SOFT_START_STEPS;
        ffbLimit = ffbClipLevels[idx];
        if (ffbTerm > ffbLimit) ffbTerm = ffbLimit;
        if (ffbTerm < -ffbLimit) ffbTerm = -ffbLimit;
        expect = psOffsets[idx] - ffbTerm;
        psLimit = psClipLevels[idx];
        if (expect > psLimit) expect = psLimit;
        if (expect < -psLimit) expect = -psLimit;
        if (expect == SETPOINT_TDATA) begin
            $display("Channel %2d, %d (%X) -- PASS", idx,
                                       $signed(SETPOINT_TDATA), SETPOINT_TDATA);
        end
        else begin
            fail = 1;
            $display("Channel %d, Expect %d (%X), got %d (%X) -- FAIL", idx,
                                       expect, expect,
                                       $signed(SETPOINT_TDATA), SETPOINT_TDATA);
        end
        idx = idx + 1;
        if (SETPOINT_TLAST) idx = 0;
    end
end

//
// Create clock
//
always begin
    #5 clk = ~clk;
end

integer chan;
integer i;

initial
begin
    $dumpfile("psSetpointCalc_tb.lxt");
    $dumpvars(0, psSetpointCalc_tb);

    for (chan = 0 ; chan < RESULT_COUNT ; chan = chan + 1) begin
        case (chan)
        0:                  setGain(chan, unityGain);
        RESULT_COUNT - 2:   setGain(chan, 2*unityGain);
        RESULT_COUNT - 1:   setGain(chan, 4*unityGain);
        default:            setGain(chan, 0);
        endcase
    end

    for (chan = 0 ; chan < RESULT_COUNT ; chan = chan + 1) begin
        setFastFeedbackClipLevel(chan, {1'b0, {CLIP_WIDTH-1{1'b1}}});
        setPsOffst(chan, 1024+chan);
        setSupplyClipLevel(chan, {1'b0, {CLIP_WIDTH-1{1'b1}}});
    end

    #100 ;
    @(posedge clk); ffbEnabled <= 1; @(posedge clk);
    for (i = 0 ; i < 6 ; i = i + 1) newData(64);
    for (i = 0 ; i < 2 ; i = i + 1) newData(128);
    for (i = 0 ; i < 2 ; i = i + 1) newData(-128);
    @(posedge clk); ffbEnabled <= 0; @(posedge clk);
    for (i = 0 ; i < 6 ; i = i + 1) newData(64);
    @(posedge clk); ffbEnabled <= 1; @(posedge clk);
    for (i = 0 ; i < 6 ; i = i + 1) newData(64);
    setSupplyClipLevel(0, 100);
    setSupplyClipLevel(4, 100);
    newData(1280);
    newData(-1280);
    setSupplyClipLevel(22, 100000);
    newData(-1280000);
    newData( 1280000);
    for (chan = 0 ; chan < RESULT_COUNT ; chan = chan + 1) begin
        setPsOffst(chan, 10240000+chan);
    end
    newData(-12800000);
    newData( 12800000);
    for (chan = 0 ; chan < RESULT_COUNT ; chan = chan + 1) begin
        setFastFeedbackClipLevel(chan, (chan + 1) * 100);
        setSupplyClipLevel(chan, {1'b0, {CLIP_WIDTH-1{1'b1}}});
    end
    newData(64);
    newData(-64);
    newData(1280);
    newData(-1280);
 
    $display("%s", fail ? "FAIL" : "PASS");
    #100; $finish;
end

task setGain;
    input [RESULT_COUNT_WIDTH-1:0] channel;
    input         [GAIN_WIDTH-1:0] gain;
    begin
        @(posedge clk) begin
            gainWriteStrobe <= 1;
            GPIO_OUT <= { {DBUS_WIDTH-GAIN_WIDTH{1'b0}}, gain };
            writeAddress <= channel;
        end
        gains[channel] = gain;
        @(posedge clk) begin
            gainWriteStrobe <= 0;
            GPIO_OUT <= {DBUS_WIDTH{1'bx}};
            writeAddress <= {RESULT_COUNT_WIDTH{1'bx}};
        end
    end
endtask

task setPsOffst;
    input [RESULT_COUNT_WIDTH-1:0] channel;
    input         [PS_OFFSET_WIDTH-1:0] psOffset;
    begin
        @(posedge clk) begin
            psOffsetWriteStrobe <= 1;
            GPIO_OUT <= { {DBUS_WIDTH-PS_OFFSET_WIDTH{1'b0}}, psOffset };
            writeAddress <= channel;
        end
        psOffsets[channel] = psOffset;
        @(posedge clk) begin
            psOffsetWriteStrobe <= 0;
            GPIO_OUT <= {DBUS_WIDTH{1'bx}};
            writeAddress <= {RESULT_COUNT_WIDTH{1'bx}};
        end
    end
endtask

task setSupplyClipLevel;
    input [RESULT_COUNT_WIDTH-1:0] channel;
    input         [CLIP_WIDTH-1:0] psClipLevel;
    begin
        @(posedge clk) begin
            psClipWriteStrobe <= 1;
            GPIO_OUT <= { {DBUS_WIDTH-PS_OFFSET_WIDTH{1'b0}}, psClipLevel };
            writeAddress <= channel;
        end
        psClipLevels[channel] = psClipLevel;
        @(posedge clk) begin
            psClipWriteStrobe <= 0;
            GPIO_OUT <= {DBUS_WIDTH{1'bx}};
            writeAddress <= {RESULT_COUNT_WIDTH{1'bx}};
        end
    end
endtask

task setFastFeedbackClipLevel;
    input [RESULT_COUNT_WIDTH-1:0] channel;
    input         [CLIP_WIDTH-1:0] ffbClipLevel;
    begin
        @(posedge clk) begin
            ffbClipWriteStrobe <= 1;
            GPIO_OUT <= { {DBUS_WIDTH-PS_OFFSET_WIDTH{1'b0}}, ffbClipLevel };
            writeAddress <= channel;
        end
        ffbClipLevels[channel] = ffbClipLevel;
        @(posedge clk) begin
            ffbClipWriteStrobe <= 0;
            GPIO_OUT <= {DBUS_WIDTH{1'bx}};
            writeAddress <= {RESULT_COUNT_WIDTH{1'bx}};
        end
    end
endtask

task newData;
    input [DIN_WIDTH-1:0] value;
    begin
        if (ffbEnabled) begin
            if (softNum < SOFT_START_STEPS) softNum = softNum + 1;
        end
        else begin
            if (softNum) softNum = softNum - 1;
        end
        @(posedge clk) begin
            dinBase <= value;
            dinToggle <= !dinToggle;
        end
        while (!(SETPOINT_TVALID && SETPOINT_TLAST)) # 10 ;
        #100 ;
    end
endtask

endmodule


//
// Dummy modules 
// Keep everything in scaled fixed point for now
// Provide a little latency
//
module psSetpointCalcFixToFloat (
    input        aclk,
    input        s_axis_a_tvalid,
    input        s_axis_a_tlast,
    input [31:0] s_axis_a_tdata,
    output reg        m_axis_result_tvalid = 0,
    output reg        m_axis_result_tlast,
    output reg [31:0] m_axis_result_tdata);

reg s_axis_a_tvalid_d = 0, s_axis_a_tlast_d;
reg [31:0] s_axis_a_tdata_d;

always @(posedge aclk) begin
    s_axis_a_tvalid_d <= s_axis_a_tvalid;
    if (s_axis_a_tvalid) begin
        s_axis_a_tlast_d <= s_axis_a_tlast;
        s_axis_a_tdata_d <= $signed(s_axis_a_tdata[27:0]);
    end
    else begin
        s_axis_a_tlast_d <= 1'bx;
        s_axis_a_tdata_d <= {32{1'bx}};
    end
    m_axis_result_tvalid <= s_axis_a_tvalid_d;
    m_axis_result_tlast <= s_axis_a_tlast_d;
    m_axis_result_tdata <= s_axis_a_tdata_d;
end
endmodule

module psSetpointCalcConvertToAmps (
    input        aclk,
    input        s_axis_a_tvalid,
    input        s_axis_a_tlast,
    input [31:0] s_axis_a_tdata,
    input        s_axis_b_tvalid,
    input [31:0] s_axis_b_tdata,
    output reg        m_axis_result_tvalid = 0,
    output reg        m_axis_result_tlast,
    output reg [31:0] m_axis_result_tdata);

reg s_axis_a_tvalid_d = 0, s_axis_a_tlast_d;
reg [31:0] s_axis_a_tdata_d;

always @(posedge aclk) begin
    s_axis_a_tvalid_d <= s_axis_a_tvalid;
    s_axis_a_tlast_d <= s_axis_a_tlast;
    s_axis_a_tdata_d <= s_axis_a_tdata;
    m_axis_result_tvalid <= s_axis_a_tvalid_d;
    m_axis_result_tlast <= s_axis_a_tlast_d;
    m_axis_result_tdata <= s_axis_a_tdata_d;
end
endmodule
