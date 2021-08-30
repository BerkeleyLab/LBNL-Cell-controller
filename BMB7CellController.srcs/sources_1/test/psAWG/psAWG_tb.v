`timescale 1 ns /  1ns

module psAWG_tb;

parameter DATA_WIDTH       = 32;
parameter ADDR_WIDTH       = 13;
parameter PATTERN_LENGTH   = 5;
parameter SETPOINT_COUNT   = 24;
parameter PATTERN_INTERVAL = 2000;
parameter SYSCLK_RATE      = 100000000;

localparam CSR_AWG_ENABLE     = (1 << 31);
localparam CSR_AWG_MULTI_PASS = (1 << 25);
localparam CSR_AWG_ARM        = (1 << 24);

localparam STATUS_AWG_ENABLED    = (1 << 30);
localparam STATUS_AWG_RUNNING    = (1 << 28);

reg sysClk = 1;
reg csrStrobe = 0;
reg addrStrobe = 0;
reg dataStrobe = 0;
reg [DATA_WIDTH-1:0] GPIO_OUT;
wire [DATA_WIDTH-1:0] status, triggerSeconds, triggerTicks;

reg evrClk = 0;
reg evrTrigger = 0;
reg [DATA_WIDTH-1:0] evrSeconds = 0, evrTicks = 0;

wire                  awgTVALID, awgTLAST;
wire [DATA_WIDTH-1:0] awgTDATA;

wire AWGrequest;
reg AWGrequest_d = 0, AWGenabled = 0;

// Device under test
psAWG #(
    .SETPOINT_COUNT(SETPOINT_COUNT),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .SYSCLK_RATE(SYSCLK_RATE))
  psAWG (
    .sysClk(sysClk),
    .csrStrobe(csrStrobe),
    .addrStrobe(addrStrobe),
    .dataStrobe(dataStrobe),
    .GPIO_OUT(GPIO_OUT),
    .status(status),
    .evrClk(evrClk),
    .evrTrigger(evrTrigger),
    .evrTimestamp({evrSeconds, evrTicks}),
    .triggerTimestamp({triggerSeconds, triggerTicks}),
    .AWGrequest(AWGrequest),
    .AWGenabled(AWGenabled),
    .awgTDATA(awgTDATA),
    .awgTVALID(awgTVALID),
    .awgTLAST(awgTLAST));

//
// Create clocks
//
always begin
    #5 sysClk = ~sysClk;
end
always begin
    #4 evrClk = ~evrClk;
end

//
// Simulate EVR
//
always @(posedge evrClk) begin
    if (evrTicks == 9999) begin
        evrTicks <= 0;
        evrSeconds <= evrSeconds + 1;
    end
    else begin
        evrTicks <= evrTicks + 1;
    end
end

//
// Simulate AXI multiplexer
//
always @(posedge sysClk) begin
    AWGrequest_d <= AWGrequest;
    AWGenabled   <= AWGrequest_d;
end

//
// Check results
//
reg inPacket = 0;
reg  [DATA_WIDTH-1:0] packetValue;
integer fail = 0;
always @(posedge sysClk) begin
    if (awgTVALID) begin
        packetValue <= awgTDATA;
        if (inPacket && (awgTDATA != packetValue)) begin
            $display("AWG TDATA changed from %x to %x -- FATAL FAIL", packetValue, awgTDATA);
            $finish ;
        end
        if (awgTLAST) begin
            inPacket <= 0;
            $display("AWG TDATA at %8d (%1d:%1d): %8x %10d -- PASS", $time, 
                              triggerSeconds, triggerTicks, awgTDATA, awgTDATA);
        end
        else begin
            inPacket <= 1;
        end
    end
end

integer i;
initial
begin
    $dumpfile("psAWG_tb.lxt");
    $dumpvars(0, psAWG_tb);

    #100 ;

    // Set up pattern
    for (i = 0 ; i < PATTERN_LENGTH ; i = i + 1) begin
        writeData(i, i + 500);
    end
    while ((status & STATUS_AWG_ENABLED)) begin
        $display("AWG unexpected enable -- FAIL");
        fail = 1;
    end

    // Enable AWG mode
    writeCSR(CSR_AWG_ENABLE | (PATTERN_INTERVAL - 2));
    i = 0;
    while (!(status & STATUS_AWG_ENABLED)) begin
        # 10 ;
        i = i + 1;
        if (i == 5) begin
            $display("AWG didn't enable -- FATAL FAIL");
            $finish ;
        end
    end

    $display("===== Single pass");
    writeCSR(CSR_AWG_ENABLE | CSR_AWG_ARM | (PATTERN_INTERVAL - 2));
    #5000 ;
    trigger();
    i = 0;
    while ((status & CSR_AWG_ARM) || (status & STATUS_AWG_RUNNING)) begin
        if (i == ((PATTERN_LENGTH + 2) * PATTERN_INTERVAL)) begin
            $display("AWG didn't complete -- FATAL FAIL");
            $finish ;
        end
        # 10 ;
        i = i + 1;
    end

    $display("===== Single pass rearm");
    writeCSR(CSR_AWG_ENABLE | CSR_AWG_ARM | (PATTERN_INTERVAL - 2));
    #5000 ;
    trigger();
    i = 0;
    while ((status & CSR_AWG_ARM) || (status & STATUS_AWG_RUNNING)) begin
        if (i == ((PATTERN_LENGTH + 2) * PATTERN_INTERVAL)) begin
            $display("AWG didn't complete -- FATAL FAIL");
            $finish ;
        end
        # 10 ;
        i = i + 1;
    end
    writeCSR(PATTERN_INTERVAL - 2);
    #100 ;

    $display("===== Multi pass");
    writeCSR(CSR_AWG_ENABLE | CSR_AWG_MULTI_PASS | CSR_AWG_ARM | (PATTERN_INTERVAL - 2));
    #5000 ;
    trigger();
    i = i * 3 + (i / 10);
    while (i != 0) begin
        # 10 ;
        i = i - 1;
    end
    writeCSR(PATTERN_INTERVAL - 2);
    while ((status & STATUS_AWG_ENABLED)) begin
        # 10 ;
        i = i + 1;
        if (i == (PATTERN_LENGTH + 10)) begin
            $display("AWG didn't stop -- FATAL FAIL");
            $finish ;
        end
    end


    #100 ;
    $display("%s", fail ? "FAIL" : "PASS");
    $finish;
end

task writeCSR;
    input [DATA_WIDTH-1:0] value;
    begin
        @(posedge sysClk) begin
            GPIO_OUT <= value;
            csrStrobe <= 1;
        end
        @(posedge sysClk) begin
            GPIO_OUT <= {DATA_WIDTH{1'bx}};
            csrStrobe <= 0;
        end
    end
endtask

task writeData;
    input [ADDR_WIDTH-1:0] address;
    input [DATA_WIDTH-1:0] value;
    begin
        @(posedge sysClk) begin
            GPIO_OUT <= address;
            addrStrobe <= 1;
        end
        @(posedge sysClk) begin
            GPIO_OUT <= value;
            addrStrobe <= 0;
            dataStrobe <= 1;
        end
        @(posedge sysClk) begin
            GPIO_OUT <= {DATA_WIDTH{1'bx}};
            dataStrobe <= 0;
        end
    end
endtask

task trigger;
    begin
        @(posedge evrClk) begin
            evrTrigger <= 1;
        end
        @(posedge evrClk) begin
            evrTrigger <= 0;
        end
    end
endtask

endmodule
