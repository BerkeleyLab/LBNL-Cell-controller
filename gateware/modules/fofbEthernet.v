// Ethernet in fabric connection to fast orbit feedback power supplies
//
// Net names starting with 'sys' are in the system clock domain.
// ALmost everything else is in the Ethernet USERCLK2 domain.

module fofbEthernet #(
    parameter          MAX_CORRECTOR_COUNT =  -1,
    parameter PCS_PMA_SHARED_LOGIC_IN_CORE = "false",
    parameter       [47:0] SRC_MAC_ADDRESS = -1,
    parameter       [31:0] SRC_IP_ADDRESS  = -1,
    parameter       [47:0] DST_MAC_ADDRESS = -1,
    parameter       [31:0] DST_IP_ADDRESS  = -1,
    parameter                     AN_DEBUG = "false",
    parameter                     TX_DEBUG = "false",
    parameter                     RX_DEBUG = "false"
    ) (
    input  wire                  sysClk,
    input  wire           [31:0] sysGpioOut,
    input  wire                  sysCsrStrobe,
    output wire           [31:0] sysCsr,

    input  wire [AXIS_WIDTH-1:0] sysTx_S_AXIS_TDATA,
    input  wire                  sysTx_S_AXIS_TVALID,
    input  wire                  sysTx_S_AXIS_TLAST,

    inout  wire            [9:0] pcs_pma_shared,
    inout  wire           [63:0] ethNonce,

    input  wire                  clk200,
    input  wire                  ETH_REF_N, ETH_REF_P,
    input  wire                  ETH_RX_N, ETH_RX_P,
    output wire                  ETH_TX_N, ETH_TX_P,

    output reg  [AXIS_WIDTH-1:0] sysRx_M_AXIS_TDATA,
    output reg             [7:0] sysRx_M_AXIS_TUSER,
    output reg                   sysRx_M_AXIS_TVALID = 0);

localparam [15:0] UDP_PORT = 16'd30721;
localparam MTU_WIDTH = 11; // Enough address bits for 1500 byte frame
localparam AXIS_WIDTH = 32;

//////////////////////////////////////////////////////////////////////////////
// Nets to/from PCS/PMA
(* mark_debug=TX_DEBUG *) wire  [7:0] eth_gmii_txd;
(* mark_debug=TX_DEBUG *) wire        eth_gmii_tx_en;
(* mark_debug=RX_DEBUG *) wire  [7:0] eth_gmii_rxd;
(* mark_debug=RX_DEBUG *) wire        eth_gmii_rx_dv;

wire [15:0] eth_an_adv_config_vector;
wire [15:0] eth_status_vector;
(* mark_debug=AN_DEBUG *) wire eth_an_interrupt;
assign eth_an_adv_config_vector = 16'h0020; // Advertise full duplex

//////////////////////////////////////////////////////////////////////////////
// Control/Status
reg sysEthReset, sysEthAnEnable;
reg sysEthAnStart, ethAnStart_m, sysEthAnRbk_m, sysEthAnRbk;
reg [3:0] sysReadbackCommand;
(* mark_debug=AN_DEBUG *) reg ethAnStart, ethAnEnable_m, ethAnEnable;
always @(posedge sysClk) begin
    sysEthAnRbk_m <= ethAnStart; sysEthAnRbk <= sysEthAnRbk_m;
    if (sysCsrStrobe) begin
        sysEthReset <= sysGpioOut[0];
        sysEthAnEnable <= sysGpioOut[2];
        sysReadbackCommand <= sysGpioOut[7:4];
    end
    if (sysCsrStrobe && sysGpioOut[1]) begin
        sysEthAnStart <= 1;
    end
    else if (sysEthAnRbk) begin
        sysEthAnStart <= 0;
    end
end
wire ethClk;
reg [63:0] ethTxPacketNumber = 0;
always @(posedge ethClk) begin
    ethAnStart_m <= sysEthAnStart; ethAnStart <= ethAnStart_m;
    ethAnEnable_m <= sysEthAnEnable; ethAnEnable <= ethAnEnable_m;
end
assign sysCsr = { eth_status_vector,
                  eth_an_interrupt, 7'b0,
                  sysReadbackCommand,
                  1'b0, sysEthAnEnable, sysEthAnStart, sysEthReset };

//////////////////////////////////////////////////////////////////////////////
// Instantiate a PCS/PMA block of the appropriate type
generate
if (PCS_PMA_SHARED_LOGIC_IN_CORE == "true") begin
  // Setpoint (transmit) link
  assign ethNonce = ethTxPacketNumber;
  wire gtrefclk_out;
  wire gtrefclk_bufg_out;
  wire userclk_out;
  wire userclk2_out;
  wire rxuserclk_out;
  wire rxuserclk2_out;
  wire pma_reset_out;
  wire mmcm_locked_out;
  wire gt0_qplloutclk_out;
  wire gt0_qplloutrefclklost_out;
  assign eth_gmii_rxd = 8'h00;
  assign eth_gmii_rx_dv = 1'b0;
`ifndef SIMULATE
  fofbPCS_PMA_with_shared_logic PCS_PMA (
  .gtrefclk_p(ETH_REF_P),          // input wire gtrefclk_p
  .gtrefclk_n(ETH_REF_N),          // input wire gtrefclk_n
  .gtrefclk_out(gtrefclk_out),     // output wire gtrefclk_out
  .gtrefclk_bufg_out(gtrefclk_bufg_out), // output wire gtrefclk_bufg_out
  .txn(ETH_TX_N),                  // output wire txn
  .txp(ETH_TX_P),                  // output wire txp
  .rxn(ETH_RX_N),                  // input wire rxn
  .rxp(ETH_RX_P),                  // input wire rxp
  .independent_clock_bufg(clk200), // input wire independent_clock_bufg
  .userclk_out(userclk_out),       // output wire userclk_out
  .userclk2_out(userclk2_out),     // output wire userclk2_out
  .rxuserclk_out(rxuserclk_out),   // output wire rxuserclk_out
  .rxuserclk2_out(rxuserclk2_out), // output wire rxuserclk2_out
  .resetdone(),                    // output wire resetdone
  .pma_reset_out(pma_reset_out),   // output wire pma_reset_out
  .mmcm_locked_out(mmcm_locked_out), // output wire mmcm_locked_out
  .gmii_txd(eth_gmii_txd),         // input wire [7 : 0] gmii_txd
  .gmii_tx_en(eth_gmii_tx_en),     // input wire gmii_tx_en
  .gmii_tx_er(1'b0),               // input wire gmii_tx_er
  .gmii_rxd(),                     // output wire [7 : 0] gmii_rxd
  .gmii_rx_dv(),                   // output wire gmii_rx_dv
  .gmii_rx_er(),                   // output wire gmii_rx_er
  .gmii_isolate(),                 // output wire gmii_isolate
  .configuration_vector({ethAnEnable, 4'b0}), // input wire [4:0] configuration_vector
  .an_interrupt(eth_an_interrupt), // output wire an_interrupt
  .an_adv_config_vector(eth_an_adv_config_vector), // input wire [15:0] an_adv_config_vector
  .an_restart_config(ethAnStart),  // input wire an_restart_config
  .status_vector(eth_status_vector), // output wire [15 : 0] status_vector
  .reset(sysEthReset),             // input wire reset
  .signal_detect(1'b1),            // input wire signal_detect
  .gt0_qplloutclk_out(gt0_qplloutclk_out), // output wire gt0_qplloutclk_out
  .gt0_qplloutrefclk_out(gt0_qplloutrefclk_out) // output wire gt0_qplloutrefclk_out
  );
`endif
  assign ethClk = userclk2_out;
  assign pcs_pma_shared = { gtrefclk_out,
                            gtrefclk_bufg_out,
                            userclk_out,
                            userclk2_out,
                            rxuserclk_out,
                            rxuserclk2_out,
                            pma_reset_out,
                            mmcm_locked_out,
                            gt0_qplloutclk_out,
                            gt0_qplloutrefclk_out };
end
else begin
  // Readback (transmit) link
  wire gtrefclk_out;
  wire gtrefclk_bufg_out;
  wire gtrefclk             = pcs_pma_shared[9];
  wire gtrefclk_bufg        = pcs_pma_shared[8];
  wire userclk              = pcs_pma_shared[7];
  wire userclk2             = pcs_pma_shared[6];
  wire rxuserclk            = pcs_pma_shared[5];
  wire rxuserclk2           = pcs_pma_shared[4];
  wire pma_reset            = pcs_pma_shared[3];
  wire mmcm_locked          = pcs_pma_shared[2];
  wire gt0_qplloutclk_in    = pcs_pma_shared[1];
  wire gt0_qplloutrefclk_in = pcs_pma_shared[0];
  assign ethClk = userclk2;
`ifndef SIMULATE
  fofbPCS_PMA_without_shared_logic PCS_PMA (
  .gtrefclk_bufg(gtrefclk_bufg),   // input wire gtrefclk_bufg
  .gtrefclk(gtrefclk),             // input wire gtrefclk
  .txn(ETH_TX_N),                  // output wire txn
  .txp(ETH_TX_P),                  // output wire txp
  .rxn(ETH_RX_N),                  // input wire rxn
  .rxp(ETH_RX_P),                  // input wire rxp
  .independent_clock_bufg(clk200), // input wire independent_clock_bufg
  .txoutclk(),                     // output wire txoutclk
  .rxoutclk(),                     // output wire rxoutclk
  .resetdone(),                    // output wire resetdone
  .cplllock(c),                    // output wire cplllock
  .mmcm_reset(),                   // output wire mmcm_reset
  .userclk(userclk),               // input wire userclk
  .userclk2(userclk2),             // input wire userclk2
  .pma_reset(pma_reset),           // input wire pma_reset
  .mmcm_locked(mmcm_locked),       // input wire mmcm_locked
  .rxuserclk(rxuserclk),           // input wire rxuserclk
  .rxuserclk2(rxuserclk2),         // input wire rxuserclk2
  .gmii_txd(8'h00),                // input wire [7 : 0] gmii_txd
  .gmii_tx_en(1'b0),               // input wire gmii_tx_en
  .gmii_tx_er(1'b0),               // input wire gmii_tx_er
  .gmii_rxd(eth_gmii_rxd),         // output wire [7 : 0] gmii_rxd
  .gmii_rx_dv(eth_gmii_rx_dv),     // output wire gmii_rx_dv
  .gmii_rx_er(),                   // output wire gmii_rx_er
  .gmii_isolate(),                 // output wire gmii_isolate
  .configuration_vector({ethAnEnable, 4'b0}), // input wire [4:0] configuration_vector
  .an_interrupt(eth_an_interrupt), // output wire an_interrupt
  .an_adv_config_vector(eth_an_adv_config_vector), // input wire [15 : 0] an_adv_config_vector
  .an_restart_config(ethAnStart),  // input wire an_restart_config
  .status_vector(eth_status_vector), // output wire [15 : 0] status_vector
  .reset(sysEthReset),             // input wire reset
  .signal_detect(1'b1),            // input wire signal_detect
  .gt0_qplloutclk_in(gt0_qplloutclk_in), // input wire gt0_qplloutclk_in
  .gt0_qplloutrefclk_in(gt0_qplloutrefclk_in) // input wire gt0_qplloutrefclk_in
  );
`endif
end
endgenerate

//////////////////////////////////////////////////////////////////////////////
// Packet payload dual-port RAM
parameter ADDR_WIDTH = $clog2(MAX_CORRECTOR_COUNT);
reg [ADDR_WIDTH-1:0] sysWaddr, lastSupplyIndex;
reg sysTossPacket = 0;
reg sysTxToggle = 0;
reg sysTxMatch_m = 0, sysTxMatch = 0;
reg [AXIS_WIDTH-1:0] dpram [0:(1<<ADDR_WIDTH)-1];
wire [ADDR_WIDTH-1:0] ethRaddr;
reg  [AXIS_WIDTH-1:0] ethRAM;
always @(posedge sysClk) begin
    if (sysTx_S_AXIS_TVALID && !sysTossPacket) begin
        dpram[sysWaddr] <= sysTx_S_AXIS_TDATA;
    end
end
always @(posedge ethClk) begin
    ethRAM <= dpram[ethRaddr];
end

//////////////////////////////////////////////////////////////////////////////
// Stash incoming data and enable transmission as appropriate
always @(posedge sysClk) begin
    sysTxMatch_m <= ethTxMatch;
    sysTxMatch   <= sysTxMatch_m;
    if (sysTx_S_AXIS_TVALID) begin
        if (sysTossPacket) begin
            if (sysTx_S_AXIS_TLAST) begin
                sysTossPacket <= 0;
            end
        end
        else if (sysTxToggle == sysTxMatch) begin
            if (sysTx_S_AXIS_TLAST) begin
                lastSupplyIndex <= sysWaddr;
                sysWaddr <= 0;
                sysTxToggle <= !sysTxToggle;
            end
            else begin
                sysWaddr <= sysWaddr + 1;
            end
        end
        else begin
            sysTossPacket <= 1;
        end
    end
end

//////////////////////////////////////////////////////////////////////////////
// Instantiate the boilerplate/machine-generated firmware

// Links between boilerplate and first 'client'
wire [MTU_WIDTH-1:0] length_1;
(* mark_debug=TX_DEBUG *) wire [7:0] data_tx_1;
(* mark_debug=TX_DEBUG *) wire req_1, ack_1, strobe_tx_1, warn_1;
(* mark_debug=RX_DEBUG *) wire [7:0] data_rx_1;
(* mark_debug=RX_DEBUG *) wire ready_1, strobe_rx_1, crc_rx_1;

aggregate #(.ip(SRC_IP_ADDRESS),
            .mac(SRC_MAC_ADDRESS),
            .jumbo_dw(MTU_WIDTH),
            .DEFAULT_DESTINATION_IP_ADDRESS(DST_IP_ADDRESS),
            .DEFAULT_DESTINATION_MAC_ADDRESS(DST_MAC_ADDRESS),
            .DEFAULT_DESTINATION_UDP_PORT(UDP_PORT))
    a(.clk(ethClk),
      .eth_in(eth_gmii_rxd),
      .eth_in_s(eth_gmii_rx_dv),
      .eth_out(eth_gmii_txd),
      .eth_out_s(eth_gmii_tx_en),
      .address_set(9'h0),
      .data_rx_1(data_rx_1),
      .ready_1(ready_1),
      .strobe_rx_1(strobe_rx_1),
      .crc_rx_1(crc_rx_1),
      .req_1(req_1),
      .length_1(length_1),
      .ack_1(ack_1),
      .strobe_tx_1(strobe_tx_1),
      .warn_1(warn_1),
      .data_tx_1(data_tx_1),
      .leds());

//////////////////////////////////////////////////////////////////////////////
// Instantiate the first 'client'
// Correcter setpoint data transmission
// Packet format -- multibyte values are sent MSB first.
//   First two bytes are identifier.
//   Next two bytes are readback command code (0/Setpoint 1/I, 2/V).
//   Next eight bytes are nonce -- for now we use packet sequence number.
//   Remainder of packet is N 6-byte values, one per supply:
//      Two byte supply number.
//      Four byte setpoint (IEEE-754 single precision floating point) Amperes.
//      On readback the setpoint has been replaced with the readback value.
localparam MUXSELECT_WIDTH = 5;

function [7:0] pkValue;
    input[MUXSELECT_WIDTH+1:0] idx;
    begin
      pkValue = (idx==17) ? 8'h76             : // MAGIC
                (idx==16) ? 8'h31             :
                (idx==15) ? 8'h00             : // COMMAND
                (idx==14) ? {4'h0, sysReadbackCommand} :
                (idx==13) ? ethNonce[63:56]   : // NONCE
                (idx==12) ? ethNonce[55:48]   :
                (idx==11) ? ethNonce[47:40]   :
                (idx==10) ? ethNonce[39:32]   :
                (idx== 9) ? ethNonce[31:24]   :
                (idx== 8) ? ethNonce[23:16]   :
                (idx== 7) ? ethNonce[15:8]    :
                (idx== 6) ? ethNonce[7:0]     :
                (idx== 5) ? 8'h00             : // SUPPLY #
                (idx== 4) ? ethTxSupplyNumber :
                (idx== 3) ? ethRAM[31:24]     : // AMPERES
                (idx== 2) ? ethRAM[23:16]     :
                (idx== 1) ? ethRAM[15:8]      :
                            ethRAM[7:0];
    end
endfunction

//
// Packet Transmission
//
(* mark_debug=TX_DEBUG *) reg [MUXSELECT_WIDTH+1:0] ethTxMuxSelect;
reg [7:0] ethTxSupplyNumber = 0;
assign ethRaddr = ethTxSupplyNumber[ADDR_WIDTH-1:0];
assign data_tx_1 = pkValue(ethTxMuxSelect);

reg ethTxToggle_m = 0;
(* mark_debug = TX_DEBUG *) reg ethTxToggle = 0;
(* mark_debug = TX_DEBUG *) reg ethTxMatch = 0;
(* mark_debug = TX_DEBUG *) reg ethTxBusy = 0;
reg ethTxReq = 0;
assign req_1 = ethTxReq;
reg [MTU_WIDTH-1:0] ethTxLength = 0;
assign length_1 = ethTxLength;

always @(posedge ethClk) begin
    ethTxToggle_m <= sysTxToggle;
    ethTxToggle   <= ethTxToggle_m;
    if (ethTxBusy) begin
        if (ack_1) begin
            ethTxReq <= 0;
        end
        if (strobe_tx_1) begin
            if (!warn_1) begin
                ethTxBusy <= 0;
                ethTxMatch <= !ethTxMatch;
            end
            else if (ethTxMuxSelect == 0) begin
                ethTxSupplyNumber <= ethTxSupplyNumber + 1;
                ethTxMuxSelect <= 5;
            end
            else begin
                ethTxMuxSelect <= ethTxMuxSelect - 1;
            end
        end
    end
    else begin
        ethTxMuxSelect <= 17;
        ethTxSupplyNumber <= 0;
        if (ethTxToggle != ethTxMatch) begin
            ethTxPacketNumber <= ethTxPacketNumber + 1;
            ethTxLength <= 18 + (lastSupplyIndex * 6);
            ethTxReq <= 1;
            ethTxBusy <= 1;
        end
    end
end

//
// Packet Reception
//
(* mark_debug=RX_DEBUG *) reg [MUXSELECT_WIDTH+1:0] ethRxMuxSelect;
wire[7:0] check_rx_1 = pkValue(ethRxMuxSelect);

(* mark_debug = RX_DEBUG *) reg ethRxBusy = 0;
(* mark_debug = RX_DEBUG *) reg ethRxBad = 0;
(* mark_debug = RX_DEBUG *) reg ethRxToggle = 0;
reg  [AXIS_WIDTH-1:0] ethRx_M_AXIS_TDATA;
reg             [7:0] ethRx_M_AXIS_TUSER;
reg strobe_rx_1_d;

always @(posedge ethClk) begin
    strobe_rx_1_d <= strobe_rx_1;
    if (ready_1) begin
        ethRxMuxSelect <= 17;
        ethRxBad <= 0;
    end
    else if (strobe_rx_1) begin
        if (ethRxMuxSelect == 0) begin
            ethRxMuxSelect <= 5;
        end
        else begin
            ethRxMuxSelect <= ethRxMuxSelect - 1;
        end
        case (ethRxMuxSelect)
        default: begin
            if (data_rx_1 != check_rx_1) begin
                ethRxBad <= 1;
            end
        end
        4: begin
            ethRx_M_AXIS_TUSER <= data_rx_1;
        end
        3: begin
            ethRx_M_AXIS_TDATA[31:24] <= data_rx_1;
        end
        2: begin
            ethRx_M_AXIS_TDATA[23:16] <= data_rx_1;
        end
        1: begin
            ethRx_M_AXIS_TDATA[15:8] <= data_rx_1;
        end
        0: begin
            sysRx_M_AXIS_TUSER <= ethRx_M_AXIS_TUSER;
            sysRx_M_AXIS_TDATA <= {ethRx_M_AXIS_TDATA[31:8], data_rx_1};
            ethRxToggle <= !ethRxToggle;
        end
        endcase
    end
end

(*ASYNC_REG="TRUE"*) reg sysRxToggle_m = 0;
reg sysRxToggle = 0, sysRxToggle_d = 0;
always @(posedge sysClk) begin
    sysRxToggle_m <= ethRxToggle;
    sysRxToggle   <= sysRxToggle_m;
    sysRxToggle_d <= sysRxToggle;
    sysRx_M_AXIS_TVALID <= (sysRxToggle != sysRxToggle_d);
end

endmodule
