//
// Pilot Tone Generator I2C
// Very basic -- No clock stretching (SCL is not monitored)
//            -- No ACK check
//            -- Fixed I/O format for AD9520(s) (address 0x5x) and all others.
//
// CSR WRITE
// Send a START, device address plus WRITE, then one to three bytes,
// least-significant byte first.
// Bits 31 through 25 are the device address, bit 24 indicates a READBACK.
// The number of bytes written depend on the address and operation:
// [31:25] [24]    [23-16]     [15-8]      [7-0]    Description
//   0x5x    0      Value    AddressLo   AddressHi  Write to AD9520
//   0x5x    1       ---     AddressLo   AddressHi  Read from AD9520
//   0x4x    0       ---       Value      Address   Write to ADT7410
//   0x??    0     ValueHi    ValueLo     Address   Write all others
//   0x??    1       ---       ---        Address   Read all others
// If bit 24 was clear, send a STOP.
// If bit 24 was set, send a repeated START, device address plus READ,
// then read one byte for AD9520, two bytes for others, then send a STOP.
//
// CSR READ
//    [31] -- Active
//   [7:0] -- AD9520 read data.  All others, first byte of read data.
//  [15:8] -- Second byte of read data for other than AD9520.

module pilotToneI2C #(parameter dbg              = "false",
                      parameter SYSCLK_FREQUENCY = 100000000,
                      parameter I2C_RATE         = 100000) (
                      input  wire        clk,
                      input  wire [31:0] writeData,
                      input  wire        writeStrobe,
                      output wire [31:0] status,
(* mark_debug = dbg *)input  wire        SCL_BUF_o,
(* mark_debug = dbg *)output reg         SCL_BUF_t = 1'b1,
(* mark_debug = dbg *)input  wire        SDA_BUF_o,
(* mark_debug = dbg *)output wire        SDA_BUF_t);

localparam TICK_RELOAD = ((SYSCLK_FREQUENCY+(I2C_RATE*4)-1)/(I2C_RATE*4))-1;
reg [$clog2(TICK_RELOAD+1)-1:0] tickCounter = TICK_RELOAD;
(* mark_debug = dbg *)reg tick = 0;

/* Readings */
reg        start = 0;
reg [15:0] result = 0;
assign status = { start | (state != S_IDLE), 15'b0, result };

/* States */
localparam S_IDLE       = 3'd0,
           S_START      = 3'd1,
           S_WRITE_BYTE = 3'd2,
           S_READ_BYTE  = 3'd3,
           S_STOP       = 3'd4;
reg [2:0] state = S_IDLE;
reg [1:0] pauseCounter = 0;
reg       pause = 0;

reg [31:0] cmd;
wire [6:0] CMD_DEVSEL     = cmd[31:25];
wire [2:0] CMD_DEVSEL_TOP = cmd[31:29];
wire       CMD_READBACK   = cmd[24];
localparam DEVSEL_TOP_ADT7410 = 3'd4;
localparam DEVSEL_TOP_AD9520  = 3'd5;
reg  [1:0] phase = 0;
reg  [3:0] bitsLeft = 0;
reg  [1:0] byteIndex = 0, finalWriteIndex = 0;
reg  [8:0] shiftReg = 9'h1FF; // MSB drives SDA pin
reg        sdaLatch;
assign SDA_BUF_t = shiftReg[8];

always @(posedge clk) begin
    if (writeStrobe && !start && (state == S_IDLE)) begin
        cmd <= writeData;
        start <= 1;
    end
    if (start && (state != S_IDLE)) start <= 0;
    if (!start && (state == S_IDLE)) begin
        tickCounter <= TICK_RELOAD;
        tick <= 0;
    end
    else begin
        if (tickCounter) begin
            tickCounter <= tickCounter - 1;
            tick <= 1'b0;
        end
        else begin
            tickCounter <= TICK_RELOAD;
            tick <= 1'b1;
        end
    end
end

always @(posedge clk) if (tick) begin
    phase <= phase + 1;
    if (phase == 2'd1) sdaLatch <= SDA_BUF_o;

    case (state)
    S_IDLE: begin
            if (CMD_READBACK) begin
                if (CMD_DEVSEL_TOP == DEVSEL_TOP_AD9520) begin
                    finalWriteIndex <= 2; // Device address, addrLo, addrHi
                end
                else begin
                    finalWriteIndex <= 1; // Device address, register #
                end
            end
            else begin
                if (CMD_DEVSEL_TOP == DEVSEL_TOP_ADT7410) begin
                    finalWriteIndex <= 2; // Device address, 8 addr, 8 val
                end
                else begin
                    finalWriteIndex <= 3; // Device address, 16/8 addr, 8/16 value
                end
            end
            byteIndex <= 0;
            if (phase == 2'd3) begin
                if (pauseCounter) begin
                    pauseCounter <= pauseCounter - 1;
                end
                else begin
                    pause <= 0;
                end
                if (start && !pause) begin
                    state <= S_START;
                end
            end
        end

    S_START:
        case (phase)
        2'd0: SCL_BUF_t <= 1'b1;
        2'd1: shiftReg <= 9'h0FF;
        2'd2: SCL_BUF_t <= 1'b0;
        2'd3: begin
                shiftReg <= {CMD_DEVSEL, (byteIndex == 0) ? 1'b0 : 1'b1, 1'b1};
                bitsLeft <= 8;
                byteIndex <= 0;
                state <= S_WRITE_BYTE;
            end
        default: ;
        endcase

    S_WRITE_BYTE:
        case (phase)
        2'd0: SCL_BUF_t <= 1'b1;
        2'd2: SCL_BUF_t <= 1'b0;
        2'd3: begin
                if (bitsLeft) begin
                    shiftReg <= { shiftReg[7:0], 1'b1 };
                     bitsLeft <= bitsLeft - 1;
                end
                else begin
                    bitsLeft <= 8;
                    if (byteIndex == finalWriteIndex) begin
                        if (CMD_READBACK) begin
                            if (byteIndex == 0) begin
                                if (CMD_DEVSEL_TOP == DEVSEL_TOP_AD9520) begin
                                    shiftReg <= 9'h1FF; // NAK
                                end
                                else begin
                                    shiftReg <= 9'h1FE; // ACK
                                end
                                state <= S_READ_BYTE;
                            end
                            else begin
                                finalWriteIndex <= 0;
                                state <= S_START;
                            end
                        end
                        else begin
                            state <= S_STOP;
                        end
                    end
                    else begin
                        case (byteIndex)
                        2'd0: begin
                                shiftReg <= { cmd[7:0], 1'b1 };
                                byteIndex <= 1;
                            end
                        2'd1: begin
                                shiftReg <= { cmd[15:8], 1'b1 };
                                byteIndex <= 2;
                            end
                        2'd2: begin
                                shiftReg <= { cmd[23:16], 1'b1 };
                                byteIndex <= 3;
                            end
                        default: ;
                        endcase
                    end
                end
            end
        default: ;
        endcase

    S_READ_BYTE:
        case (phase)
        2'd0: SCL_BUF_t <= 1'b1;
        2'd2: SCL_BUF_t <= 1'b0;
        2'd3: begin
                if (bitsLeft) begin
                    shiftReg <= { shiftReg[7:0], sdaLatch };
                    bitsLeft <= bitsLeft - 1;
                end
                else begin
                    bitsLeft <= 8;
                    shiftReg <= 9'h1FF;
                    if (byteIndex == 0) begin
                        byteIndex <= 1;
                        result[7:0] <= shiftReg[7:0];
                        if (CMD_DEVSEL_TOP == DEVSEL_TOP_AD9520) begin
                            state <= S_STOP;
                        end
                    end
                    else begin
                        result[15:8] <= shiftReg[7:0];
                        state <= S_STOP;
                    end
                end
            end
        default: ;
        endcase

    S_STOP:
        case (phase)
        2'd0: shiftReg <= 9'h0FF;
        2'd1: SCL_BUF_t <= 1'b1;
        2'd2: shiftReg <= 9'h1FF;
        2'd3: begin
                pauseCounter <= ~0;
                pause <= 1;
                state <= S_IDLE;
            end
        default: ;
        endcase
    endcase
end

endmodule
