//
// Copyright (c) 2106 W. Eric Norum, Lawrence Berkeley National Laboratory
//

// Convert AXI Stream FIFO output (or equivalent) to 8b9b stream
//
// There is no AXI stream TVALID line.  TDATA and TLAST must
// be valid whenever the TREADY line is asserted.
// In the place of TVALID there is a 'start' line which is monitored
// only when the transmitter is in the ST_IDLE state.
//
// Wire format:
//   A zero bit (START) followed by 8 data bits (least-significant bit first)
//   followed by either another zero bit and 8 data bits or a one bit marking
//   the end of the frame.
//   The one bit marking the end of a frame is followed by at least two
//   more one bits to give the receiver time to resume looking for the
//   first start bit of the next frame.
//

module tx8b9b #(
    parameter DEBUG = "false"
    ) (
    input  wire       clk,      // Bit rate AXI stream clock
 
    input  wire       start,
    input  wire       S_AXIS_TLAST,
    input  wire [7:0] S_AXIS_TDATA,

    output reg        S_AXIS_TREADY,
    output reg        dout = 1);

// Tranmission state machine
localparam ST_IDLE   = 2'd0,
           ST_START  = 2'd1,
           ST_ACTIVE = 2'd2,
           ST_DONE   = 2'd3;
reg [1:0] state = ST_IDLE;
reg [7:0] shiftReg;
reg [2:0] nLeft;
reg       last;

always @(posedge clk) begin
    case (state)
    ST_IDLE: begin
        if (start) begin
            state <= ST_START;
        end
    end
    ST_START: begin
        S_AXIS_TREADY <= 1;
        last <= S_AXIS_TLAST;
        shiftReg <= S_AXIS_TDATA;
        nLeft <= 7;
        dout <= 0;
        state <= ST_ACTIVE;
    end
    ST_ACTIVE: begin
        S_AXIS_TREADY <= 0;
        nLeft <= nLeft - 1;
        shiftReg <= {1'bx, shiftReg[7:1]};
        dout <= shiftReg[0];
        if (nLeft == 0) begin
            if (last) begin
                state <= ST_DONE;
            end
            else begin
                state <= ST_START;
            end
        end
    end
    ST_DONE: begin
        dout <= 1;
        last <= 0;
        if (!last) begin
            state <= ST_IDLE;
        end
    end
    default: ;
    endcase
end

endmodule
