module cctrl_aurora_8b10b_marble_top #(
  parameter          AURORA_TYPE               = "8b10b",
  parameter          EVR_ILA_CHIPSCOPE_DBG     = "FALSE",
  parameter          BPM_TEST_AURORA_ILA_CHIPSCOPE_DBG = "FALSE"
  ) (
  input              DDR_REF_CLK_P, // 125 MHz
  input              DDR_REF_CLK_N, // 125 MHz (complement)
  output             VCXO_EN,
  output             PHY_RSTN,

  input  wire        FPGA_TxD,
  output wire        FPGA_RxD,

  // FPGA flash
  output wire        BOOT_CS_B,
  output wire        BOOT_MOSI,
  input              BOOT_MISO,

  // SPI between FPGA and microcontroller
  input              FPGA_SCLK,
  input              FPGA_CSB,
  input              FPGA_MOSI,
  output             FPGA_MISO,

  input wire         MGT_CLK_0_N, MGT_CLK_0_P,
  input wire         MGT_CLK_1_N, MGT_CLK_1_P,
  input wire         MGT_CLK_2_N, MGT_CLK_2_P,

  input              RGMII_RX_CLK,
  input              RGMII_RX_CTRL,
  input        [3:0] RGMII_RXD,
  output wire        RGMII_TX_CLK,
  output wire        RGMII_TX_CTRL,
  output wire  [3:0] RGMII_TXD,

/*
  Transceiver Assignments (Kintex-7):
  -----------------------------------
    This is copied directly from
      https://controls.als.lbl.gov/alscg/beampositionmonitor/BPM_CC/Documents/HardwareNotes.html

    RX N/P  TX N/P  Tile  MGT           Fiber Pair  QSFP (BMB7) QSFP (Marble)  Desc.
    --------------------------------------------------------------------------------
    C3/C4   B1/B2   X0Y6  MGT2 Bank 116 1:12        1-0         1-1             EVR
    B5/B6   A3/A4   X0Y7  MGT3 Bank 116 2:11        1-1         1-3             BPM CCW
    E3/E4   D1/D2   X0Y5  MGT1 Bank 116 3:10        1-2         1-0             BPM CW
    G3/G4   F1/F2   X0Y4  MGT0 Bank 116 4:9         1-3         1-2             (Unused)
    L3/L4   K1/K2   X0Y2  MGT2 Bank 115 1:12        2-0         2-1             Cell CCW
    J3/J4   H1/H2   X0Y3  MGT3 Bank 115 2:11        2-1         2-3             Cell CW
    N3/N4   M1/M2   X0Y1  MGT1 Bank 115 3:10        2-2         2-0             FOFB power supply chain head (Tx)
    R3/R4   P1/P2   X0Y0  MGT0 Bank 115 4:9         2-3         2-2             FOFB power supply chain tail (Rx)
*/

  input  wire  [3:0] QSFP1_RX_N, QSFP1_RX_P, // [0]->EVR;     [1]->BPM_CCW_GT_RX_rxn;   [2]->BPM_CW_GT_RX_rxn;    [3]->BPM_TEST_RX
  output wire  [3:0] QSFP1_TX_N, QSFP1_TX_P, // [0]->EVR;     [1]->BPM_CCW;             [2]->BPM_CW;              [3]->BPM_TEST_TX
  input  wire  [3:0] QSFP2_RX_N, QSFP2_RX_P, // [0]->CELL_CCW_GT_RX_rxn; [1]->CELL_CW_GT_RX_rxn; [2]->fofb(psTx); [3]->fofb(psRx)
  output wire  [3:0] QSFP2_TX_N, QSFP2_TX_P, // [0]->CELL_CCW_GT_TX_txn; [1]->CELL_CW_GT_TX_txn; [2]->fofb(psTx); [3]->fofb(psRx)

  inout TWI_SDA,
  inout TWI_SCL,

  input PMOD1_0,
  output PMOD1_1,
  input PMOD1_2,
  output PMOD1_3,

  output PMOD2_0,
  output PMOD2_1,
  output PMOD2_2,
  output PMOD2_3,
  output PMOD2_4,
  output PMOD2_5,
  output PMOD2_6,
  output PMOD2_7,

  output wire        MARBLE_LD16,
  output wire        MARBLE_LD17
);

common_cctrl_top #(
  .AURORA_TYPE                        (AURORA_TYPE),
  .EVR_ILA_CHIPSCOPE_DBG              (EVR_ILA_CHIPSCOPE_DBG),
  .BPM_TEST_AURORA_ILA_CHIPSCOPE_DBG  (BPM_TEST_AURORA_ILA_CHIPSCOPE_DBG)
  ) common_cctrl_top_inst (
  .DDR_REF_CLK_P(DDR_REF_CLK_P),
  .DDR_REF_CLK_N(DDR_REF_CLK_N),
  .VCXO_EN(VCXO_EN),
  .PHY_RSTN(PHY_RSTN),

  .FPGA_TxD(FPGA_TxD),
  .FPGA_RxD(FPGA_RxD),

  .BOOT_CS_B(BOOT_CS_B),
  .BOOT_MOSI(BOOT_MOSI),
  .BOOT_MISO(BOOT_MISO),

  .FPGA_SCLK(FPGA_SCLK),
  .FPGA_CSB(FPGA_CSB),
  .FPGA_MOSI(FPGA_MOSI),
  .FPGA_MISO(FPGA_MISO),

  .MGT_CLK_0_N(MGT_CLK_0_N),
  .MGT_CLK_0_P(MGT_CLK_0_P),
  .MGT_CLK_1_N(MGT_CLK_1_N),
  .MGT_CLK_1_P(MGT_CLK_1_P),
  .MGT_CLK_2_N(MGT_CLK_2_N),
  .MGT_CLK_2_P(MGT_CLK_2_P),

  .RGMII_RX_CLK(RGMII_RX_CLK),
  .RGMII_RX_CTRL(RGMII_RX_CTRL),
  .RGMII_RXD(RGMII_RXD),
  .RGMII_TX_CLK(RGMII_TX_CLK),
  .RGMII_TX_CTRL(RGMII_TX_CTRL),
  .RGMII_TXD(RGMII_TXD),

  .QSFP1_RX_N(QSFP1_RX_N),
  .QSFP1_RX_P(QSFP1_RX_P),
  .QSFP1_TX_N(QSFP1_TX_N),
  .QSFP1_TX_P(QSFP1_TX_P),
  .QSFP2_RX_N(QSFP2_RX_N),
  .QSFP2_RX_P(QSFP2_RX_P),
  .QSFP2_TX_N(QSFP2_TX_N),
  .QSFP2_TX_P(QSFP2_TX_P),

  .TWI_SDA(TWI_SDA),
  .TWI_SCL(TWI_SCL),

  .PMOD1_0(PMOD1_0),
  .PMOD1_1(PMOD1_1),
  .PMOD1_2(PMOD1_2),
  .PMOD1_3(PMOD1_3),

  .PMOD2_0(PMOD2_0),
  .PMOD2_1(PMOD2_1),
  .PMOD2_2(PMOD2_2),
  .PMOD2_3(PMOD2_3),
  .PMOD2_4(PMOD2_4),
  .PMOD2_5(PMOD2_5),
  .PMOD2_6(PMOD2_6),
  .PMOD2_7(PMOD2_7),

  .MARBLE_LD16(MARBLE_LD16),
  .MARBLE_LD17(MARBLE_LD17)
);

endmodule
