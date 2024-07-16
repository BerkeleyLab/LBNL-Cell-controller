`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:          BNL
// Engineer:         J. DeLong
//
// Create Date:      09:49:15 03/16/2010
// Design Name:
// Module Name:      timeofDayReceiver
// Project Name:     embedded event receiver
// Target Devices:   FX70T
// Tool versions:    ISE 12.1
// Description:      This subdesign receives time stamp control events to set the
//                   time of day from the GPS locked NTP server. The offset to the
//                   time of day is incremented at the system clock rate.
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments
//  2017-10-10, W. Eric Norum -- Rewrite to make more robust
//
//////////////////////////////////////////////////////////////////////////////////
module timeofDayReceiver (
    input              Clock,
    input              Reset,
    input        [7:0] EventStream,
    output reg   [9:0] tooManyCount = 0,
    output reg   [9:0] tooFewCount = 0,
    output reg   [9:0] outOfSeqCount = 0,
    output wire [63:0] TimeStamp);

localparam SECONDS_WIDTH = 32;
localparam TICKS_WIDTH   = 32;
reg [SECONDS_WIDTH-1:0] tsSeconds = 0, expectSeconds = 0;
reg   [TICKS_WIDTH-1:0] tsTicks = 0;
reg                     tsValid = 0;
assign TimeStamp = {tsSeconds, tsTicks};

localparam EVCODE_SHIFT_ZERO     = 8'h70;
localparam EVCODE_SHIFT_ONE      = 8'h71;
localparam EVCODE_SECONDS_MARKER = 8'h7D;

reg         [SECONDS_WIDTH-1:0] shiftReg;
reg [$clog2(SECONDS_WIDTH)-1:0] bitsLeft = SECONDS_WIDTH - 1;
reg enoughBits = 0, tooManyBits = 0;

always @(posedge Clock) begin
    if (Reset) begin
        tsSeconds <= 0;
        tsTicks <= 0;
        tsValid <= 0;
    end
    else if (EventStream == EVCODE_SECONDS_MARKER) begin
        if (!enoughBits) tooFewCount <= tooFewCount + 1;
        if (tooManyBits) tooManyCount <= tooManyCount + 1;
        if (enoughBits && !tooManyBits) begin
            expectSeconds <= shiftReg + 1;
            if (shiftReg == expectSeconds) begin
                tsSeconds <= shiftReg;
                tsValid <= 1;
            end
            else begin
                outOfSeqCount <= outOfSeqCount + 1;
                if (tsValid) begin
                    tsSeconds <= tsSeconds + 1;
                end
            end
        end
        else if (tsValid) begin
            tsSeconds <= tsSeconds + 1;
        end
        tsTicks <= 0;
        bitsLeft <= SECONDS_WIDTH - 1;
        enoughBits <= 0;
        tooManyBits <= 0;
    end
    else begin
        if ((EventStream == EVCODE_SHIFT_ZERO)
         || (EventStream == EVCODE_SHIFT_ONE)) begin
            // Shift in another bit of upcoming seconds
            bitsLeft <= bitsLeft - 1;
            if (enoughBits) tooManyBits <= 1;
            if (bitsLeft == 0) enoughBits <= 1;
            shiftReg <= {shiftReg[SECONDS_WIDTH-2:0], EventStream[0]};
        end
        if (tsTicks[TICKS_WIDTH-1] == 0) begin
            tsTicks <= tsTicks + 1;
        end
        else begin
            tsValid <= 0;
        end
    end
end

endmodule
