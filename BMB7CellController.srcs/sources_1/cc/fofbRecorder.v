// Fast orbit feedback waveform recorder

module fofbRecorder #(
    parameter BUFFER_CAPACITY = 32768,
    parameter CHANNEL_COUNT   = 24,
    parameter DEBUG           = "false"
    ) (
    input                       clk,
    input                [31:0] GPIO_OUT,
    input                       csrStrobe,
    input                       pretriggerInitStrobe,
    input                       posttriggerInitStrobe,
    input                       channelMapStrobe,
    input                       addressStrobe,
    input                [63:0] timestamp,
    output wire          [31:0] status,
    output wire          [31:0] triggerAddress,
    output reg [AXIS_WIDTH-1:0] txData,
    output reg [AXIS_WIDTH-1:0] rxData,
    output reg           [63:0] acqTimestamp,

    input                       evrTrigger,
    input                       awgRunning,

    (*mark_debug=DEBUG*) input                       tx_S_AXIS_TVALID,
    (*mark_debug=DEBUG*) input      [AXIS_WIDTH-1:0] tx_S_AXIS_TDATA,
    (*mark_debug=DEBUG*) input                       tx_S_AXIS_TLAST,
    (*mark_debug=DEBUG*) input                       rx_S_AXIS_TVALID,
    (*mark_debug=DEBUG*) input      [AXIS_WIDTH-1:0] rx_S_AXIS_TDATA,
    (*mark_debug=DEBUG*) input                 [7:0] rx_S_AXIS_TUSER
    );

localparam AXIS_WIDTH = 32;
localparam CHAN_COUNT_WIDTH = $clog2(CHANNEL_COUNT+1);
localparam ADDRESS_WIDTH = $clog2(BUFFER_CAPACITY);
localparam WATCHDOG_WIDTH = 14;

// Recorder counters
reg [ADDRESS_WIDTH:0] pretriggerRemainingInit, posttriggerRemainingInit;
reg [ADDRESS_WIDTH:0] pretriggerRemaining, posttriggerRemaining;
wire pretriggerDone = pretriggerRemaining[ADDRESS_WIDTH];
wire posttriggerDone = posttriggerRemaining[ADDRESS_WIDTH];
reg [CHAN_COUNT_WIDTH-1:0] channelCount;
(*mark_debug=DEBUG*) 
reg [CHAN_COUNT_WIDTH:0] rxRemaining;
wire rxDone = rxRemaining[CHAN_COUNT_WIDTH];

// Bitmap of channels to record
reg [CHANNEL_COUNT-1:0] activeChannels;

// Offsets from base
reg  [CHAN_COUNT_WIDTH-1:0] txChannel = 0;
wire [CHAN_COUNT_WIDTH-1:0] rxChannel = rx_S_AXIS_TUSER[CHAN_COUNT_WIDTH-1:0];

// DPRAM addresses
reg  [ADDRESS_WIDTH-1:0] baseAddress = 0, triggerLocation, readoutAddress;
reg [CHAN_COUNT_WIDTH-1:0] rxOffset, txOffset;
(*mark_debug=DEBUG*)wire [ADDRESS_WIDTH-1:0] rxAddress = baseAddress + rxOffset;
(*mark_debug=DEBUG*)wire [ADDRESS_WIDTH-1:0] txAddress = baseAddress + txOffset;

// Recorder state machine
localparam ST_IDLE   = 2'd0,
           ST_FILL   = 2'd1,
           ST_ARMED  = 2'd2,
           ST_FINISH = 2'd3;
(*mark_debug=DEBUG*) reg [1:0] state;
(*mark_debug=DEBUG*) reg full = 0;
(*ASYNC_REG="TRUE"*) reg sysEvrTrigger_m;
reg sysEvrTrigger, sysEvrTrigger_d;
reg triggered;

// Statistics
reg tx_S_AXIS_TVALID_d = 0, rx_S_AXIS_TVALID_d = 0;
reg watchdogRunning = 0;
reg [WATCHDOG_WIDTH-1:0] watchdog = 0, psLoopLatency = ~0;
wire watchdogOverflow = watchdog[WATCHDOG_WIDTH-1];

assign status = { full, 1'b0, state,
                  {32-4-WATCHDOG_WIDTH-8{1'b0}},
                  psLoopLatency,
                  {8-CHAN_COUNT_WIDTH{1'b0}},
                  channelCount };
assign triggerAddress = {{32-ADDRESS_WIDTH{1'b0}}, triggerLocation};

// DPRAM
reg [AXIS_WIDTH-1:0] txBuf [0:BUFFER_CAPACITY-1];
reg [AXIS_WIDTH-1:0] rxBuf [0:BUFFER_CAPACITY-1];
always @(posedge clk) begin
    txData <= txBuf[readoutAddress];
    rxData <= rxBuf[readoutAddress];
    if (addressStrobe) begin
        readoutAddress <= GPIO_OUT[ADDRESS_WIDTH-1:0];
    end
    if (state != ST_IDLE) begin
        if (tx_S_AXIS_TVALID && activeChannels[txChannel]) begin
            txBuf[txAddress] <= tx_S_AXIS_TDATA;
        end
        if (rx_S_AXIS_TVALID && activeChannels[rxChannel]) begin
            rxBuf[rxAddress] <= rx_S_AXIS_TDATA;
        end
    end
end

// Recorder control
always @(posedge clk) begin
    sysEvrTrigger_m <= evrTrigger;
    sysEvrTrigger   <= sysEvrTrigger_m;
    sysEvrTrigger_d <= sysEvrTrigger;
    if (channelMapStrobe) begin
        activeChannels <= GPIO_OUT[CHANNEL_COUNT-1:0];
    end
    if (pretriggerInitStrobe) begin
        pretriggerRemainingInit <= GPIO_OUT[ADDRESS_WIDTH:0];
    end
    if (posttriggerInitStrobe) begin
        posttriggerRemainingInit <= GPIO_OUT[ADDRESS_WIDTH:0];
    end
    if (state == ST_IDLE) begin
        triggered <= 0;
        rxOffset <= 0;
        txOffset <= 0;
        txChannel <= 0;
        pretriggerRemaining <= pretriggerRemainingInit;
        posttriggerRemaining <= posttriggerRemainingInit;
        if (csrStrobe) begin
            channelCount <= GPIO_OUT[CHAN_COUNT_WIDTH-1:0];
            rxRemaining <= {1'b0, GPIO_OUT[CHAN_COUNT_WIDTH-1:0]} - 2;
            if (GPIO_OUT[29]) begin
                full <= 0;
            end
            if (GPIO_OUT[30] && GPIO_OUT[31]) begin
                state <= ST_FILL;
            end
        end
    end
    else if (csrStrobe && GPIO_OUT[30] && !GPIO_OUT[31]) begin
        state <= ST_IDLE;
    end
    else begin
        if (state == ST_ARMED) begin
            if ((sysEvrTrigger && !sysEvrTrigger_d)
             || (awgRunning)
             || (csrStrobe && GPIO_OUT[28])) begin
                triggered <= 1;
            end
        end
        if (tx_S_AXIS_TVALID) begin
            if (tx_S_AXIS_TLAST) begin
                txChannel <= 0;
            end
            else begin
                txChannel <= txChannel + 1;
            end
            if (activeChannels[txChannel]) begin
                txOffset <= txOffset + 1;
            end
        end
        if (rx_S_AXIS_TVALID && activeChannels[rxChannel]) begin
            rxOffset <= rxOffset + 1;
            if (rxDone) begin
                rxOffset <= 0;
                txOffset <= 0;
                rxRemaining <= {1'b0, channelCount} - 2;
                baseAddress <= baseAddress + channelCount;
                case (state)
                ST_FILL: begin
                    pretriggerRemaining <= pretriggerRemaining - 1;
                    if (pretriggerDone) begin
                        state <= ST_ARMED;
                    end
                end
                ST_ARMED: begin
                    triggerLocation <= baseAddress;
                    acqTimestamp <= timestamp;
                    if (triggered) begin
                        posttriggerRemaining <= posttriggerRemaining - 1;
                        if (posttriggerDone) begin
                            full <= 1;
                            state <= ST_IDLE;
                        end
                        else begin
                            state <= ST_FINISH;
                        end
                    end
                end
                ST_FINISH: begin
                    posttriggerRemaining <= posttriggerRemaining - 1;
                    if (posttriggerDone) begin
                        full <= 1;
                        state <= ST_IDLE;
                    end
                end
                default: ;
                endcase
            end
            else begin
                rxRemaining <= rxRemaining - 1;
            end
        end
    end

    // Measure power supply loop latency
    tx_S_AXIS_TVALID_d <= tx_S_AXIS_TVALID;
    rx_S_AXIS_TVALID_d <= rx_S_AXIS_TVALID;
    if (tx_S_AXIS_TVALID && !tx_S_AXIS_TVALID_d) begin
        if (watchdogRunning) begin
            psLoopLatency <= ~0;
        end
        watchdogRunning <= 1;
        watchdog <= 0;
    end
    else if (watchdogRunning) begin
        watchdog <= watchdog + 1;
        if ((rx_S_AXIS_TVALID && !rx_S_AXIS_TVALID_d) || watchdogOverflow) begin
            psLoopLatency <= watchdog;
            watchdogRunning <= 0;
        end
    end
end

endmodule
