// Allow CPU to monitor power supply setpoints (for comfort display).

module psSetpointMonitor #(
    parameter SETPOINT_COUNT = -1,
    parameter DATA_WIDTH     = 32,
    parameter DEBUG          = "false"
    ) (
    input                                       clk,
    (*mark_debug=DEBUG*) input                  FOFB_SETPOINT_AXIS_TVALID,
    (*mark_debug=DEBUG*) input                  FOFB_SETPOINT_AXIS_TLAST,
    (*mark_debug=DEBUG*) input [DATA_WIDTH-1:0] FOFB_SETPOINT_AXIS_TDATA,

    input                        addressStrobe,
    input       [DATA_WIDTH-1:0] GPIO_OUT,
    output wire [DATA_WIDTH-1:0] psSetpoint,
    output wire [DATA_WIDTH-1:0] status);

localparam ADDRESS_WIDTH = $clog2(SETPOINT_COUNT);
localparam FILL_NUMBER_WIDTH = 4;

reg [ADDRESS_WIDTH-1:0] inputAddress=0, outputAddress=0, highwaterAddress=0;
reg [DATA_WIDTH-1:0] dpram [0:(1 << ADDRESS_WIDTH) - 1], dpramQ;
reg [FILL_NUMBER_WIDTH-1:0] fillNumber = 0;

assign psSetpoint = dpramQ;
assign status = { {8-FILL_NUMBER_WIDTH{1'b0}}, fillNumber, 
                  {DATA_WIDTH-ADDRESS_WIDTH-8{1'b0}}, highwaterAddress };

always @(posedge clk) begin
    if (FOFB_SETPOINT_AXIS_TVALID) begin
        dpram[inputAddress] <= FOFB_SETPOINT_AXIS_TDATA;
    end
    if (FOFB_SETPOINT_AXIS_TVALID) begin
        if (FOFB_SETPOINT_AXIS_TLAST) begin
            highwaterAddress <= inputAddress;
            inputAddress <= 0;
            fillNumber <= fillNumber + 1;
        end
        else begin
            inputAddress <= inputAddress + 1;
        end
    end

    dpramQ <= dpram[outputAddress];
    if (addressStrobe) begin
        outputAddress <= GPIO_OUT[ADDRESS_WIDTH-1:0];
    end
end

endmodule
