// Power supply arbitrary waveform generator
// Nets with names beginning with evr are in EVR clock domain.
// All other nets are in system clock domain.

module psAWG #(
    parameter SETPOINT_COUNT = -1,
    parameter DATA_WIDTH     = -1,
    parameter ADDR_WIDTH     = -1,
    parameter SYSCLK_RATE    = -1,
    parameter DEBUG          = "false"
    ) (
    input                        sysClk,
    input                        csrStrobe,
    input                        addrStrobe,
    input                        dataStrobe,
    input       [DATA_WIDTH-1:0] GPIO_OUT,
    output wire [DATA_WIDTH-1:0] status,

    input                        evrTrigger,
    input                        sysFAstrobe,

    output reg                   AWGrequest = 0,
    input                        AWGenabled,

    (*mark_debug=DEBUG*) output wire [DATA_WIDTH-1:0] awgTDATA,
    (*mark_debug=DEBUG*) output reg                   awgTVALID = 0,
    (*mark_debug=DEBUG*) output wire                  awgTLAST);

// Up to 1 ms per point
localparam SAMPLE_INTERVAL_COUNTER_WIDTH = $clog2(SYSCLK_RATE/1000) + 1;
reg [SAMPLE_INTERVAL_COUNTER_WIDTH-1:0] intervalCounterReload;
reg [SAMPLE_INTERVAL_COUNTER_WIDTH-1:0] intervalCounter;
wire intervalCounterDone = intervalCounter[SAMPLE_INTERVAL_COUNTER_WIDTH-1];

reg useFAmarker = 0;
(*mark_debug=DEBUG*)
wire sampleTrigger = useFAmarker ? sysFAstrobe : intervalCounterDone;

(*ASYNC_REG="true"*) reg sysEvrTrigger_m;
(*mark_debug=DEBUG*) reg sysEvrTrigger;
                     reg sysEvrTrigger_d;

(*mark_debug=DEBUG*) reg [ADDR_WIDTH-1:0] writeAddress, readAddress;
reg [DATA_WIDTH-1:0] dpram [0:(1<<ADDR_WIDTH)-1], dpramQ;
assign awgTDATA = dpramQ;

localparam SETPOINT_COUNTER_WIDTH = $clog2(SETPOINT_COUNT);
reg [SETPOINT_COUNTER_WIDTH:0] setpointCounter;
assign setpointCounterDone = setpointCounter[SETPOINT_COUNTER_WIDTH];
assign awgTLAST = setpointCounterDone;

(*mark_debug=DEBUG*) reg trigger = 0;
(*mark_debug=DEBUG*) reg addressMatch = 0;
localparam ST_IDLE   = 2'd0,
           ST_ARMED  = 2'd1,
           ST_ACTIVE = 2'd2;
(*mark_debug=DEBUG*) reg [1:0] state = ST_IDLE;

localparam MODE_DISABLED   = 2'd0;
localparam MODE_RETRIGGER  = 2'd1;
localparam MODE_CONTINUOUS = 2'd2;
(*mark_debug=DEBUG*) reg [1:0] mode     = MODE_DISABLED;

assign status = { AWGrequest, AWGenabled, state,
                  1'b0, useFAmarker, mode,
                  {24-SAMPLE_INTERVAL_COUNTER_WIDTH{1'b0}},
                  intervalCounterReload };

always @(posedge sysClk) begin
    sysEvrTrigger_m <= evrTrigger;
    sysEvrTrigger   <= sysEvrTrigger_m;
    sysEvrTrigger_d <= sysEvrTrigger;
    trigger <= ((csrStrobe && GPIO_OUT[27])
             || (sysEvrTrigger && !sysEvrTrigger_d)
             || (mode == MODE_CONTINUOUS));
    addressMatch <= (readAddress == writeAddress);

    // DPRAM
    if (addrStrobe) writeAddress <= GPIO_OUT[ADDR_WIDTH-1:0];
    if (dataStrobe) dpram[writeAddress] <= GPIO_OUT;
    dpramQ <= dpram[readAddress];

    // Control
    if (csrStrobe) begin
        // psMux ensures that AWGenabled transitions occur between packets
        AWGrequest  <= GPIO_OUT[31];
        useFAmarker <= GPIO_OUT[26];
        mode        <= GPIO_OUT[25:24];
        intervalCounterReload <= GPIO_OUT[SAMPLE_INTERVAL_COUNTER_WIDTH-1:0];
    end

    // AWG state machine
    if (AWGenabled) begin
        case (state)
        ST_IDLE: begin
            awgTVALID <= 0;
            if (mode != MODE_DISABLED) begin
                state <= ST_ARMED;
            end
        end
        ST_ARMED: begin
            readAddress <= 0;
            intervalCounter <= ~0;
            if (mode == MODE_DISABLED) begin
                state <= ST_IDLE;
            end
            else if (trigger) begin
                state <= ST_ACTIVE;
            end
        end
        ST_ACTIVE: begin
            if (sampleTrigger) begin
                intervalCounter <= intervalCounterReload;
                setpointCounter <= SETPOINT_COUNT - 2;
                if (mode == MODE_DISABLED) begin
                    state <= ST_IDLE;
                end
                else begin
                    awgTVALID <= 1;
                end
            end
            else begin
                intervalCounter <= intervalCounter - 1;
                if (setpointCounterDone) begin
                    awgTVALID <= 0;
                    if (awgTVALID) begin
                        if (addressMatch) begin
                            readAddress <= 0;
                            case (mode)
                            MODE_DISABLED:  state <= ST_IDLE;
                            MODE_RETRIGGER: state <= ST_ARMED;
                            default: ;
                            endcase
                        end
                        else begin
                            readAddress <= readAddress + 1;
                        end
                    end
                end
                else begin
                    setpointCounter <= setpointCounter - 1;
                end
            end
        end
        default: ;
        endcase
    end
    else begin
        state <= ST_IDLE;
        awgTVALID <= 0;
        readAddress <= 0;
    end
end

endmodule
