// Generate pilot tone reference

module pilotToneReference #(
    parameter DIRECT_OUTPUT_ENABLE = "false",
    parameter DEBUG                = "false"
    ) (
    input              sysClk,
    input              csrStrobe,
    input       [31:0] GPIO_OUT,
    output wire [31:0] csr,

    input       evrClk,
    output wire pilotToneReference);

localparam COUNTER_WIDTH = 10;

(*mark_debug = DEBUG *) reg [COUNTER_WIDTH-1:0] hiDivide = ~0, loDivide = ~0;
(*mark_debug = DEBUG *) reg [COUNTER_WIDTH-1:0] hiReload, loReload, evrCounter;
reg direct = 0;
wire haveDirect = (DIRECT_OUTPUT_ENABLE != "false");

assign csr = {haveDirect, {31 - 2 * COUNTER_WIDTH{1'b0}}, hiDivide, loDivide};

always @(posedge sysClk) begin
    if (csrStrobe) begin
        loDivide <= GPIO_OUT[0+:COUNTER_WIDTH];
        hiDivide <= GPIO_OUT[COUNTER_WIDTH+:COUNTER_WIDTH];
    end
    hiReload <= hiDivide - 1;
    loReload <= loDivide - 1;
    direct <= (hiDivide == 0) || (loDivide == 0) ? 1 : 0;
end

wire [COUNTER_WIDTH-1:0] evrHiReload, evrLoReload;
wire evrDirect;

forwardData #(.DATA_WIDTH(2*COUNTER_WIDTH+1))
  forwardReloads (
    .inClk(sysClk),
    .inData({hiReload, loReload, direct}),
    .outClk(evrClk),
    .outData({evrHiReload, evrLoReload, evrDirect}));

reg pilotToneToggle = 0;
// (* IOB = (DIRECT_OUTPUT_ENABLE == "false") ? "true" : "false" *)
(* IOB = "true" *)
reg pilotToneToggle_b = 0;
assign pilotToneReference = ((DIRECT_OUTPUT_ENABLE == "false")  || !direct) ?
                                                     pilotToneToggle_b : evrClk;

always @(posedge evrClk) begin
    pilotToneToggle_b <= pilotToneToggle;
    if (evrCounter == 0) begin
        pilotToneToggle <= !pilotToneToggle;
        if (pilotToneToggle) begin
            evrCounter <= evrLoReload;
        end
        else begin
            evrCounter <= evrHiReload;
        end

    end
    else begin
        evrCounter <= evrCounter - 1;
    end
end

endmodule
