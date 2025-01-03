module fmpsReadoutStream #(
    parameter INDEX_WIDTH       = 5
) (
    input wire                        sysClk,
    input wire                 [31:0] fmpsCSR,

    input wire [(1<<INDEX_WIDTH)-1:0] fmpsBitmapAll,
    output reg      [INDEX_WIDTH-1:0] fmpsReadoutAddress,
    input wire                 [31:0] fmpsReadout,

    output reg      [INDEX_WIDTH-1:0] fmpsIndex,
    output reg                 [31:0] fmpsData,
    output reg                        fmpsValid
);

// Tap into the CSR
wire fmpsReadoutActive = fmpsCSR[31];
wire fmpsReadoutValid = fmpsCSR[30];
reg fmpsReadoutActive_d = 0, fmpsReadoutValid_d = 0;

wire fmpsPacketPresent = fmpsBitmapAll[fmpsReadoutAddress];

localparam ST_IDLE             = 2'd0,
           ST_READ_NEXT_PACKET = 2'd1,
           ST_READ_SETTLE      = 2'd2,
           ST_READ_PACKET      = 2'd3;
reg [1:0] state;

always @(posedge sysClk) begin
    fmpsReadoutActive_d <= fmpsReadoutActive;
    fmpsReadoutValid_d <= fmpsReadoutValid;
    fmpsValid <= 0;

    case (state)
    ST_IDLE: begin
        // Wait for new data to arrive or acquisition interval to end
        if ((fmpsReadoutValid && !fmpsReadoutValid_d)
         || (!fmpsReadoutActive && fmpsReadoutActive_d)) begin
            fmpsReadoutAddress <= 0;
            state <= ST_READ_SETTLE;
        end
    end

    ST_READ_NEXT_PACKET: begin
        fmpsReadoutAddress <= fmpsReadoutAddress + 1;
        state <= ST_READ_SETTLE;

        if (fmpsReadoutAddress == (1<<INDEX_WIDTH)-1) begin
            fmpsReadoutAddress <= 0;
            state <= ST_IDLE;
        end
    end

    // Cope with 1 clock cycle latency
    ST_READ_SETTLE: begin
        state <= ST_READ_PACKET;
    end

    ST_READ_PACKET: begin
        // we have that packet and it's ready to be checked
        if (fmpsPacketPresent) begin
            // dataIndex field must be the same as the
            // FMPS index for this test
            fmpsIndex <= fmpsReadoutAddress;
            fmpsData <= fmpsReadout;
            fmpsValid <= 1;
        end

        state <= ST_READ_NEXT_PACKET;
    end

    default: ;

    endcase
end

endmodule
