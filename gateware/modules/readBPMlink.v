//
// Read values from a BPM link
// Everything is in Aurora receiver AXI clock domain.
//
module readBPMlink #(
    parameter dbg = "false") (
                       input  wire         clk,
(* mark_debug = dbg *) input  wire  [31:0] TDATA,
(* mark_debug = dbg *) input  wire         TVALID,
(* mark_debug = dbg *) input  wire         TLAST,
(* mark_debug = dbg *) input  wire         CRC_VALID,
(* mark_debug = dbg *) input  wire         CRC_PASS,
(* mark_debug = dbg *) input  wire         inhibit,
(* mark_debug = dbg *) output wire         outputStrobe,
(* mark_debug = dbg *) output reg  [111:0] outputData,
(* mark_debug = dbg *) output wire         statusStrobe,
(* mark_debug = dbg *) output reg    [1:0] statusCode);

// Reception statistics
localparam ST_SUCCESS    = 2'd0,
           ST_BAD_HEADER = 2'd1,
           ST_BAD_SIZE   = 2'd2,
           ST_BAD_PACKET = 2'd3;

// Reception state machine
localparam S_AWAIT_HEADER      = 0,
           S_AWAIT_X           = 1,
           S_AWAIT_Y           = 2,
           S_AWAIT_S           = 4,
           S_AWAIT_LAST        = 5;
(* mark_debug = dbg *) reg   [2:0] state = S_AWAIT_HEADER;

reg statusToggle = 0, statusToggle_d = 0;
assign statusStrobe = (statusToggle != statusToggle_d);
reg outputToggle = 0, outputToggle_d = 0;
assign outputStrobe = (outputToggle != outputToggle_d);

always @(posedge clk) begin
    statusToggle_d <= statusToggle;
    outputToggle_d <= outputToggle;
    if (TVALID) begin
        if (TLAST && !state[2]) begin
            statusCode <= ST_BAD_SIZE;
            statusToggle <= !statusToggle;
            state <= S_AWAIT_HEADER;
        end
        else begin
            case (state)
            S_AWAIT_HEADER: begin
                if (TDATA[31:16] == 16'hA5BE) begin
                    outputData[96+:16] <= TDATA[15:0];
                    state <= S_AWAIT_X;
                end
                else begin
                    statusCode <= ST_BAD_HEADER;
                    statusToggle <= !statusToggle;
                    state <= S_AWAIT_LAST;
                end
            end

            S_AWAIT_X: begin
                outputData[64+:32] <= TDATA;
                state <= S_AWAIT_Y;
            end

            S_AWAIT_Y: begin
                outputData[32+:32] <= TDATA;
                state <= S_AWAIT_S;
            end

            S_AWAIT_S: begin
                outputData[0+:32] <= { TDATA[31], 1'b0, TDATA[29:0] };
                if (TLAST) begin
                    if (CRC_VALID && CRC_PASS && !TDATA[31]) begin
                        if (!inhibit) outputToggle <= !outputToggle;
                        statusCode <= ST_SUCCESS;
                    end
                    else begin
                        statusCode <= ST_BAD_PACKET;
                    end
                    state <= S_AWAIT_HEADER;
                end
                else begin
                    statusCode <= ST_BAD_SIZE;
                    state <= S_AWAIT_LAST;
                end
                statusToggle <= !statusToggle;
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

endmodule
