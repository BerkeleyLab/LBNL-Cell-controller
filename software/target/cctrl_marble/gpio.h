/*
 * Indices into the big general purpose I/O block.
 * Used to generate Verilog parameter statements too, so be careful with
 * the syntax:
 *      Spaces only (no tabs).
 *      Register definitions must precede include statements.
 *      All defines before first include statement must be base-10 constants.
 */

#ifndef _GPIO_H_
#define _GPIO_H_

#define GPIO_IDX_COUNT 64

#define GPIO_IDX_FIRMWARE_BUILD_DATE       0 // Firmware build POSIX seconds(R)
#define GPIO_IDX_MICROSECONDS              1 // 1 MHz counter(R)
#define GPIO_IDX_SECONDS                   2 // 1 Hz counter(R)
#define GPIO_IDX_EVENT_STATUS              3 // EVR additional status(R)
#define GPIO_IDX_UART_CSR                  4 // Console UART TX(R/W)
#define GPIO_IDX_QSFP_IIC                  5 // QSFP control lines and IIC(R/W)
#define GPIO_IDX_PILOT_TONE_I2C            6 // Pilot tone generator(R/W)
#define GPIO_IDX_PILOT_TONE_CSR            7 // Pilot tone control(R/W)
#define GPIO_IDX_LINK_STATISTICS_CSR       8 // Link status histograms(R/W)
#define GPIO_IDX_AURORA_CSR                9 // Aurora links control(R/W)
#define GPIO_IDX_CELL_COMM_CSR            10 // Cell communication control(R/W)
#define GPIO_IDX_CELL_RX_BITMAP           11 // Cells with data(R)
#define GPIO_IDX_BPM_RX_BITMAP            12 // BPMs with data(R)
#define GPIO_IDX_FOFB_ENABLE_BITMAP       13 // Cells with FOFB enabled (R)
#define GPIO_IDX_BPMLINKS_CSR             14 // BPM readout control(R/W)
#define GPIO_IDX_BPMLINKS_EXTRA_STATUS    15 // BPM readout additional status(R)
#define GPIO_IDX_BPM_READOUT_X            16 // BPM readout addr(W)/X value(R)
#define GPIO_IDX_BPM_READOUT_Y            17 // BPM readout Y value(R)
#define GPIO_IDX_BPM_READOUT_S            18 // BPM readout S value(R)
#define GPIO_IDX_ERROR_CONVERT_CSR        19 // FIFO control(W)/status(R)
#define GPIO_IDX_ERROR_CONVERT_WDATA      20 // Value to be converted(W)
#define GPIO_IDX_ERROR_CONVERT_RDATA_HI   21 // Converted value MSBs(R)
#define GPIO_IDX_ERROR_CONVERT_RDATA_LO   22 // Converted value LSBs(R)
#define GPIO_IDX_DSP_CSR                  23 // DSP control(W)/status(R)
#define GPIO_IDX_FOFB_CSR                 24 // FOFB control(R/W)
#define GPIO_IDX_EEBI_CSR                 25 // EEBI control(W)/status(R)
#define GPIO_IDX_EEBI_FAULT_TIME_SECONDS  26 // EEBI most recent fault time(R)
#define GPIO_IDX_EEBI_FAULT_TIME_TICKS    27 // EEBI most recent fault time(R)
#define GPIO_IDX_ETHERNET0_CSR            28 // First PS QSFP ethernet CSR(R/W)
#define GPIO_IDX_ETHERNET1_CSR            29 // First PS QSFP ethernet CSR(R/W)
#define GPIO_IDX_EVENT_LOG_CSR            30 // Event logger CSR(R/W)
#define GPIO_IDX_EVENT_LOG_TICKS          31 // Event logger tick counter(R)
#define GPIO_IDX_FREQUENCY_MONITOR_CSR    32 // Frequency counters(R/W)
#define GPIO_IDX_PILOT_TONE_REFERENCE     35 // Pilot tone ref generator(R/W)
#define GPIO_IDX_FOFB_PS_SETPOINT         36 // Access to ps setpoints(R/W)
#define GPIO_IDX_FOFB_PS_SETPOINT_STATUS  37 // Access to ps setpoints(R)
#define GPIO_IDX_AWG_CSR                  38 // AWG control/status(R/W)
#define GPIO_IDX_AWG_ADDRESS              39 // AWG address(W),trigger sec(R)
#define GPIO_IDX_AWG_DATA                 40 // AWG data(W), trigger ticks(R)
#define GPIO_IDX_WFR_CSR                  41 // Recorder CSR(R/W)
#define GPIO_IDX_WFR_ADDRESS              42 // Recorder readout address(R/W)
#define GPIO_IDX_WFR_W_CHANNEL_BITMAP     43 // Recorder channel bitmap(W)
#define GPIO_IDX_WFR_R_TX_DATA            43 // Recorder transmit readout(R)
#define GPIO_IDX_WFR_W_PRETRIGGER         44 // Recorder pretrigger 'count'(W)
#define GPIO_IDX_WFR_R_RX_DATA            44 // Recorder receive readout (R)
#define GPIO_IDX_WFR_W_POSTTRIGGER        45 // Recorder posttrigger 'count'(W)
#define GPIO_IDX_WFR_R_SECONDS            45 // Recorder timestamp seconds(R)
#define GPIO_IDX_WFR_R_TICKS              46 // Recorder timestamp ticks(R)
#define GPIO_IDX_NET_CONFIG_CSR           47 // BantamweightUDP config CSR
#define GPIO_IDX_NET_RX_CSR               48 // BantamweightUDP RX CSR
#define GPIO_IDX_NET_RX_DATA              49 // BantamweightUDP RX DATA
#define GPIO_IDX_NET_TX_CSR               50 // BantamweightUDP TX CSR & DATA

#define GPIO_DSP_CMD_LATCH_ADDRESS        0
#define GPIO_DSP_CMD_LATCH_HIGH_VALUE     1
#define GPIO_DSP_CMD_WRITE_MATRIX_ELEMENT 2
#define GPIO_DSP_CMD_WRITE_FOFB_GAIN      3
#define GPIO_DSP_CMD_WRITE_PS_OFFSET      4
#define GPIO_DSP_CMD_WRITE_PS_CLIP_LIMIT  5
#define GPIO_DSP_CMD_WRITE_FFB_CLIP_LIMIT 6
#define GPIO_DSP_CMD_FIR_RELOAD           7
#define GPIO_DSP_CMD_FIR_CONFIG           8
#define GPIO_DSP_CMD_SHIFT                28

#define GPIO_AWG_CAPACITY           8192
#define GPIO_RECORDER_CAPACITY      32768
#define GPIO_CHANNEL_COUNT          24
#define GPIO_FOFB_MATRIX_ADDR_WIDTH 9

#include <xil_io.h>
#include <xparameters.h>

#define GPIO_READ(i)    Xil_In32(XPAR_AXI_LITE_GENERIC_REG_BASEADDR+(4*(i)))
#define GPIO_WRITE(i,x) Xil_Out32(XPAR_AXI_LITE_GENERIC_REG_BASEADDR+(4*(i)),(x))

#define MICROSECONDS_SINCE_BOOT()     GPIO_READ(GPIO_IDX_MICROSECONDS)
#define SECONDS_SINCE_BOOT()  GPIO_READ(GPIO_IDX_SECONDS)

#endif
