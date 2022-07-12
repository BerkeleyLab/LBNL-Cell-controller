//
// Copyright (c) 2106 W. Eric Norum, Lawrence Berkeley National Laboratory
//

// Convert 8b9b stream to AXI stream
//
// START bit followed by 8 data bits (least-significant bit first)
// START=0 indicates valid bits follow
// START=1 indicates that value is not part of frame
//

module rx8b9b #(
    parameter DEBUG = "false"
    ) (
    input  wire      clk,      // Bit rate clock
    input  wire      clk4x,    // Four times faster version of clk
    (* mark_debug = DEBUG *) input  wire      reset,

    (* mark_debug = DEBUG *) input  wire      din,

    (* mark_debug = DEBUG *) output reg       M_AXIS_TVALID = 0,
    (* mark_debug = DEBUG *) output reg       M_AXIS_TLAST = 0,
    (* mark_debug = DEBUG *) output reg [7:0] M_AXIS_TDATA = 0);

// Reception state machine
localparam ST_IDLE   = 2'd0,
           ST_START  = 2'd1,
           ST_ACTIVE = 2'd2,
           ST_DONE   = 2'd3;
(* mark_debug = DEBUG *) reg [1:0] state = ST_IDLE;
(* mark_debug = DEBUG *) reg [7:0] shiftReg;
(* mark_debug = DEBUG *) reg [2:0] nLeft;
(* mark_debug = DEBUG *) wire rxRaw;

// Deserialized value from ISERDESE2
// Bit 3 is earliest to arrive, bit 0 is latest -- i.e. left shift reg
wire [3:0] serdesQ;
reg  [3:0] serdesData, serdesData_d;

// Detect any zero bits in the latched SERDES value
wire startDetect;
assign startDetect = !(&serdesData);

// Find the falling edge in the latched SERDES value
wire [1:0] firstZeroPosition;
assign firstZeroPosition = (serdesData[3] == 0) ? 2'd3 :
                           (serdesData[2] == 0) ? 2'd2 :
                           (serdesData[1] == 0) ? 2'd1 :
                                                  2'd0;
reg [1:0] firstZeroPositionReg;

// Sample the bit 1/4 to 1/2 a bit time after the START falling edge
wire dataBit;
assign dataBit = (firstZeroPositionReg == 2'd3) ? serdesData_d[2]   :
                 (firstZeroPositionReg == 2'd2) ? serdesData_d[1]   :
                 (firstZeroPositionReg == 2'd1) ? serdesData_d[0]   :
                                                  serdesData[3];

// Give SERDES a while to sample data line after reset
reg [1:0] didReset = ~0;

always @(posedge clk) begin
    serdesData   <= serdesQ;
    serdesData_d <= serdesData;
    if (reset || (didReset != 0)) begin
        state <= ST_IDLE;
        M_AXIS_TVALID <= 0;
        if (reset) begin
            didReset <= ~0;
        end
        else if (!startDetect) begin
            didReset <= didReset - 1;
        end
    end
    else begin
        case (state)
        ST_IDLE: begin
            M_AXIS_TVALID <= 0;
            nLeft <= 7;
            firstZeroPositionReg <= firstZeroPosition;
            if (startDetect) begin
                state <= ST_START;
            end
        end
        ST_START: begin
            state <= ST_ACTIVE;
        end
        ST_ACTIVE: begin
            M_AXIS_TVALID <= 0;
            nLeft <= nLeft - 1;
            shiftReg <= {dataBit, shiftReg[7:1]};
            if (nLeft == 0) begin
                state <= ST_DONE;
            end
        end
        ST_DONE: begin
            nLeft <= 7;
            M_AXIS_TVALID <= 1;
            M_AXIS_TDATA <= shiftReg;
            if (dataBit) begin
                M_AXIS_TLAST <= 1;
                state <= ST_IDLE;
            end
            else begin
                M_AXIS_TLAST <= 0;
                state <= ST_ACTIVE;
            end
        end
        default: ;
        endcase
    end
end

// The ISERDESE2 that provides the 4 bit values
ISERDESE2 #(
        .DATA_RATE("SDR"),
        .DATA_WIDTH(4),
        .INTERFACE_TYPE("NETWORKING"),
        .IOBDELAY("NONE"),
        .NUM_CE(1))
  ISERDESE2 (
        .CLK(clk4x),
        .CLKDIV(clk),
        .D(din),
        .O(rxRaw),
        .Q4(serdesQ[3]),
        .Q3(serdesQ[2]),
        .Q2(serdesQ[1]),
        .Q1(serdesQ[0]),
        .RST(reset),
        .CLKDIVP(1'b0),
        .CE1(1'b1),
        .OCLK(1'b0),
        .OCLKB(1'b0),
        .BITSLIP(1'b0),
        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0),
        .OFB(1'b0),
        .DYNCLKSEL(1'b0),
        .DYNCLKDIVSEL(1'b0),
        .DDLY(1'b0));

endmodule
