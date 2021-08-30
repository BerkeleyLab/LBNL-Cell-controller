// Log event arrival
module evrLogger #(
    parameter ADDR_WIDTH = 8
    ) (
    input  wire        sysClk,
    input  wire        sysCsrStrobe,
    input  wire [31:0] sysGpioOut,
    output wire [31:0] sysCsr,
    output wire [31:0] sysDataTicks,
    
    input  wire        evrClk,
    input  wire        evrTVALID,
    input  wire  [7:0] evrTDATA);

reg [ADDR_WIDTH-1:0] sysReadAddress = 0, evrWriteAddress = 0;
reg sysRunning = 0, evrRunning_m, evrRunning, evrRunning_d;
reg evrWriteWrapped = 0;
reg [31:0] evrTickCounter = 0;
reg [39:0] dpram[0:(1<<ADDR_WIDTH)-1], dpramQ;
wire [3:0] addrWidth = ADDR_WIDTH;
assign sysCsr = { sysRunning, evrWriteWrapped, {2{1'b0}},
                  addrWidth,
                  dpramQ[39:32],
                  {16-ADDR_WIDTH{1'b0}},
                  evrWriteAddress };
assign sysDataTicks = dpramQ[31:0];
always @(posedge sysClk) begin
    if (sysCsrStrobe) begin
        sysReadAddress <= sysGpioOut[ADDR_WIDTH-1:0];
        sysRunning <= sysGpioOut[31];
    end
    dpramQ <= dpram[sysReadAddress];
end

reg       evrDPRAMwen;
reg [7:0] evrDPRAMevent;
always @(posedge evrClk) begin
    evrRunning_m <= sysRunning;
    evrRunning   <= evrRunning_m;
    evrRunning_d <= evrRunning;
    evrTickCounter <= evrTickCounter + 1;
    evrDPRAMwen <= evrRunning_d && evrTVALID && (evrTDATA != 0);
    evrDPRAMevent <= evrTDATA;
    if (evrRunning && !evrRunning_d) begin
        evrWriteAddress <= 0;
        evrWriteWrapped <= 0;
    end
    if (evrDPRAMwen) begin
        dpram[evrWriteAddress] <= { evrDPRAMevent, evrTickCounter };
        evrWriteAddress <= evrWriteAddress + 1;
        if (evrWriteAddress == {ADDR_WIDTH{1'b1}}) evrWriteWrapped <= 1;
    end
end

endmodule


