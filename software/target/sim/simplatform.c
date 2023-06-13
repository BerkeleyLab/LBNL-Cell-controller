// simplatform.c

#include <string.h>
#include <stdio.h>
#include <signal.h>
#include <sys/time.h> // Needed for struct timeval
#include <time.h>     // Needed for clock()
#include <unistd.h>   // For STDIN_FILENO
#include <fcntl.h>    // For fcntl()

#include "simplatform.h"
#include "gpio.h"
#include "uart_fifo.h"
#include "udp_simple.h"
#include "cellControllerProtocol.h"

//#define TRAPEXIT

#define UDP_ADDR(index)     (XPAR_EPICS_UDP_BASEADDR+(4*(index)))
#define GPIO_ADDR(index)    (XPAR_AXI_LITE_GENERIC_REG_BASEADDR+(4*(index)))

// Redundant defines in console.c
#define UART_CSR_TX_FULL    0x80000000
#define UART_CSR_RX_READY   0x100

// Redundant defines from evr.c
#define EVR_REG(r)   (XPAR_EVR_AXI_0_BASEADDR+((r)*sizeof(uint32_t)))
#define EVENT_HEARTBEAT         122
#define EVENT_PPS               125
#define EVR_RAM_A(e) (XPAR_EVR_AXI_0_BASEADDR+0x2000+((e)*sizeof(uint32_t)))
#define EVR_RAM_INDEX_A(addr)   ((addr - (XPAR_EVR_AXI_0_BASEADDR+0x2000)) >> 2)
#define EVR_RAM_B(e) (XPAR_EVR_AXI_0_BASEADDR+0x4000+((e)*sizeof(uint32_t)))
#define EVR_RAM_INDEX_B(addr)   ((addr - (XPAR_EVR_AXI_0_BASEADDR+0x4000)) >> 2)

// Redundant defines from eyescan.c
#define DRP_LANE_SELECT_SHIFT       11 /* 2048 bytes per DRP lane */
#define EYSCAN_BASEADDR             XPAR_AURORA_DRP_BRIDGE_0_BASEADDR
#define EYESCAN_ADDR(base,reg)      ((base)+((reg)<<2))
#define EYESCAN_LANECOUNT           5
#define EYESCAN_LANE_BASE(lane)     (EYSCAN_BASEADDR+(lane<<DRP_LANE_SELECT_SHIFT))
#define EYESCAN_LANE0(reg)          (EYESCAN_ADDR(EYSCAN_BASEADDR,reg))
#define EYESCAN_LANE1(reg)          (EYESCAN_ADDR(EYESCAN_LANE_BASE(1),reg))
#define EYESCAN_LANE2(reg)          (EYESCAN_ADDR(EYESCAN_LANE_BASE(2),reg))
#define EYESCAN_LANE3(reg)          (EYESCAN_ADDR(EYESCAN_LANE_BASE(3),reg))
#define EYESCAN_LANE4(reg)          (EYESCAN_ADDR(EYESCAN_LANE_BASE(4),reg))
#define DRP_REG_PMA_RSV2          0x082
#define DRP_REG_TXOUT_RXOUT_DIV   0x088
#define DRP_REG_ES_PS_VOFF        0x03B
#define DRP_REG_ES_CSR            0x03D

// XADC
#define XADC_ADDR(offset)           (XPAR_XADC_WIZ_0_BASEADDR + offset)
#define R_TEMP          0x200 /* On-chip Temperature */
#define R_VCCINT        0x204 /* FPGA VCCINT */
#define R_VCCAUX        0x208 /* FPGA VCCAUX */
#define R_VBRAM         0x218 /* FPGA VBRAM */
#define R_CFR0          0x300 /* Configuration Register 0 */
#define R_CFR1          0x304 /* Configuration Register 1 */
#define R_CFR2          0x308 /* Configuration Register 2 */
#define R_SEQ00         0x320 /* Seq Reg 00 -- Channel Selection */
#define R_SEQ01         0x324 /* Seq Reg 01 -- Channel Selection */
#define R_SEQ02         0x328 /* Seq Reg 02 -- Average Enable */
#define R_SEQ03         0x32C /* Seq Reg 03 -- Average Enable */
#define R_SEQ04         0x330 /* Seq Reg 04 -- Input Mode Select */
#define R_SEQ05         0x334 /* Seq Reg 05 -- Input Mode Select */
#define R_SEQ06         0x338 /* Seq Reg 06 -- Acquisition Time Select */
#define R_SEQ07         0x33C /* Seq Reg 07 -- Acquisition Time Select */

// QSFP
#define MODULE_STATUS_OFFSET    2
#define TEMPERATURE_OFFSET     22
#define VSUPPLY_OFFSET         26
#define RXPOWER_0_OFFSET       34
#define IDENTIFIER_OFFSET     128
#define VENDOR_NAME_OFFSET    148
#define PART_NAME_OFFSET      168
#define REVISION_CODE_OFFSET  184
#define WAVELENGTH_OFFSET     186
#define SERIAL_NUMBER_OFFSET  196
#define DATE_CODE_OFFSET      212
#define DIAG_TYPE_OFFSET      220

// Aurora
#define CSR_GTX_RESET       0x1
#define CSR_AURORA_RESET    0x2
#define CSR_FA_ENABLE       0x4

// Badger
#define CONFIG_CSR_ENABLE_RX_ENABLE 0x80000000
#define CONFIG_CSR_RX_ENABLE        0x40000000
#define CONFIG_CSR_ADDRESS_MASK     (0xF << CONFIG_CSR_ADDRESS_SHIFT)
#define CONFIG_CSR_ADDRESS_SHIFT    8
#define CONFIG_CSR_DATA_MASK        0xFF

#define TX_CSR_W_START          0x80000000
#define TX_CSR_R_BUSY           0x80000000
#define TX_CSR_R_TOGGLE_A       0x40000000
#define TX_CSR_R_TOGGLE_B       0x20000000
#define TX_CSR_ADDRESS_MASK     (0x7FF << TX_CSR_ADDRESS_SHIFT)
#define TX_CSR_ADDRESS_SHIFT    16
#define TX_CSR_DATA_MASK        0xFFFF

#define RX_CSR_R_MAC_BANK           0x1
#define RX_CSR_R_MAC_HBANK          0x2
#define RX_CSR_W_MAC_HBANK_TOGGLE   0x2

#define ETH_MAXWORDS            ((ETH_MAXLEN + 3) >> 2)
#define BADGER_LENGTH_STATUS(length, status)    (((((length+46) & 0x780) << 1) | ((length+46) & 0x7F)) | (0x80 & (status << 7)))
        //    length = (((length_status & 0xF00) >> 1) | (length_status & 0x7F)) - 4;
#define BADGER_TX_ADDR(bus)   ((int)((bus >> 16) & 0x7FF))
#define BADGER_TX_DATA(bus)   ((uint32_t)(bus & 0xFFFF))


typedef struct {
  int length_status;
  int index;  // in words
  int fill;   // in bytes, not words!
  int pending;  // Message waiting
  eth_union_t pkt;
} eth_inbox_t;

typedef struct {
  int pending;  // Message currently sending
  int ready;    // Message ready to send
  int frameLength;
  eth_union_t pkt;
} eth_outbox_t;

static eth_inbox_t eth_inbox;
static eth_outbox_t eth_outbox;

static uint32_t auroraStatus = 0;

// This is strange.  I arrived at this proportionality constant imperically.
// clock()/CLOCKS_PER_SEC ended up being 30x too long.
#define SYSTICK_US()     (uint32_t)((uint64_t)30000000*clock()/CLOCKS_PER_SEC)

// Simulated EVR stuff
#define EVR_RAM_SIZE 0x100
uint32_t evr_ram_a[EVR_RAM_SIZE];
uint32_t evr_ram_b[EVR_RAM_SIZE];

typedef struct {
  int toExit;
  int msgReady;
} sim_console_state_t;

uint32_t _startTime;

uint8_t nextChar = 0;

// GLOBALS
static sim_console_state_t sim_console_state;

static unsigned short udp_port;

#ifdef TRAPEXIT
static void _sigHandler(int c);
#endif

// Static function prototypes
static unsigned int getQSFPDescChar(void);
static void setQSFPDescChar(int n);
static void udpService(void);

int simService(void) {
  fd_set rset;        // A file-descriptor set for read mode
  int ri, rval;
  char rc;
  struct timeval timeout;
  FD_ZERO(&rset);     // Initialize the data to 0s
  FD_SET(STDIN_FILENO, &rset);    // Add STDIN to the read set
  // NOTE: select() MODIFIES TIMEOUT!!!   Need to reinitialize every time.
  timeout.tv_sec = 0;
  timeout.tv_usec = 1000;  // 1ms timeout
  rval = select(STDIN_FILENO+1, &rset, NULL, NULL, &timeout);
  int n = UART_QUEUE_ITEMS;
  if (rval) {
    while (n--) {
      ri = fgetc(stdin);
      if ((ri == EOF) || (ri == 0)) {
        break;
      }
      rc = (char)(ri & 0xff);
      UARTQUEUE_Add((uint8_t *)&rc);
    }
  }
  udpService();
  return 0;
}

void init_platform() {
  _startTime = SYSTICK_US();
#ifdef TRAPEXIT
  signal(SIGINT, _sigHandler);
#endif
  fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);
  sim_console_state.toExit = 0;
  sim_console_state.msgReady = 0;
  udp_port = CC_PROTOCOL_UDP_PORT;
  int rc = udp_init(udp_port);
  if (rc != 0) {
    printf("Error in UDP initialization\r\n");
    return;
  } else {
    printf("Listening on port %d\r\n", udp_port);
  }
  eth_inbox.length_status = BADGER_LENGTH_STATUS(0, 0);
  eth_inbox.index = 0;
  eth_inbox.pending = 0;
  eth_inbox.fill = 0;

  eth_outbox.ready = 0;
  eth_outbox.pending = 0;
  eth_outbox.frameLength = 0;
  return;
}

static void udpService(void) {
  // INBOX
  int rc = udp_receive_meta(&eth_inbox.pkt.pkt);
  // NOTE: clobbers any existing data
  if (rc > 0) {
    eth_inbox.fill = rc;
    eth_inbox.length_status = BADGER_LENGTH_STATUS(rc, 0);  // What is status bit?
    printf("Got packet len %d\r\n", rc);
    eth_inbox.pending = 1;
  } else if (rc < 0) {
    printf("Receive error\r\n");
    sim_console_state.toExit = 1;
    eth_inbox.pending = 0;
  }
  // OUTBOX
  if (eth_outbox.ready) {
    printf("Reply with frameLength = %d\r\n", eth_outbox.frameLength);
    printf("payload length = %d\r\n", ETH_PAYLOAD_LENGTH(eth_outbox.frameLength));
    rc = udp_reply((const void *)&(eth_outbox.pkt.pkt.payload), (int)ETH_PAYLOAD_LENGTH(eth_outbox.frameLength));
    eth_outbox.ready = 0;
  }
  return;
}

#ifdef TRAPEXIT
static void _sigHandler(int c) {
  printf("Exiting...\r\n");
  sim_console_state.toExit = 1;
  return;
}
#endif

void cleanup_platform() {
  return;
}

static int qsfpCharIndex = 0;

static void setQSFPDescChar(int n) {
  //n = (qsfp * 256 + offset) >> 1;
  int offset = (n << 1) & 0xff;
  qsfpCharIndex = offset;
  int qsfp = ((n << 1) & 0xff00) >> 8;
  //printf("qsfp %d offset %d\r\n", qsfp, offset);
  //GPIO_WRITE(GPIO_IDX_QSFP_IIC, qidx);
  //v = GPIO_READ(GPIO_IDX_QSFP_IIC);
  return;
}

#define QSFP_PARSE(s, offset) do { \
  n = qsfpCharIndex - offset; \
  if (n+1 < sizeof(s)/sizeof(char)) { rval = s[n+1] | (s[n] << 8); }} while (0)

static unsigned int getQSFPDescChar(void) {
  unsigned int rval = 0x2020;
  const char datecode[] = "200327\0";
  const char serialnum[] = "6789998212\0";
  const unsigned char wavelength[] = {51, 254};
  const char revision[] = "6789998212\0";
  const char vendor[] = "Fake Stuff Inc.\0";
  const char partname[] = "Pretend QSFP\0";
  const char id[] = {4, 6};
  const char rxpwr[] = {10, 20};
  const char vsupply[] = {3, 3};
  const char temp[] = {0, 1}; // ?
  int n;
  if (qsfpCharIndex >= DIAG_TYPE_OFFSET) {
    rval = 0; // ?
  } else if (qsfpCharIndex >= DATE_CODE_OFFSET) {
    QSFP_PARSE(datecode, DATE_CODE_OFFSET);
  } else if (qsfpCharIndex >= SERIAL_NUMBER_OFFSET) {
    QSFP_PARSE(serialnum, SERIAL_NUMBER_OFFSET);
  } else if (qsfpCharIndex >= WAVELENGTH_OFFSET) {
    QSFP_PARSE(wavelength, WAVELENGTH_OFFSET);
  } else if (qsfpCharIndex >= REVISION_CODE_OFFSET) {
    QSFP_PARSE(revision, REVISION_CODE_OFFSET);
  } else if (qsfpCharIndex >= PART_NAME_OFFSET) {
    QSFP_PARSE(partname, PART_NAME_OFFSET);
  } else if (qsfpCharIndex >= VENDOR_NAME_OFFSET) {
    QSFP_PARSE(vendor, VENDOR_NAME_OFFSET);
  } else if (qsfpCharIndex >= IDENTIFIER_OFFSET) {
    QSFP_PARSE(id, IDENTIFIER_OFFSET);
  } else if (qsfpCharIndex >= RXPOWER_0_OFFSET) {
    QSFP_PARSE(rxpwr, RXPOWER_0_OFFSET);
  } else if (qsfpCharIndex >= VSUPPLY_OFFSET) {
    QSFP_PARSE(vsupply, VSUPPLY_OFFSET);
  } else if (qsfpCharIndex >= TEMPERATURE_OFFSET) {
    QSFP_PARSE(temp, TEMPERATURE_OFFSET);
  } else if (qsfpCharIndex >= MODULE_STATUS_OFFSET) {
    rval = 0;
  }
  return rval;
}

uint32_t Xil_In32(uint32_t addr) {
  uint32_t rval = 0;
  static uint32_t ppscounter, now = 0;
  if ((addr >= EVR_RAM_A(0)) && (addr < EVR_RAM_A(EVR_RAM_SIZE))) {
    rval = evr_ram_a[EVR_RAM_INDEX_A(addr)];
  } else if ((addr >= EVR_RAM_B(0)) && (addr < EVR_RAM_B(EVR_RAM_SIZE))) {
    rval = evr_ram_b[EVR_RAM_INDEX_B(addr)];
  } else {
    switch (addr) {
      case UDP_ADDR(0): // bmb7_udp (csr)
        break;
      case UDP_ADDR(1): // bmb7_udp (data)
        break;
      case GPIO_ADDR(GPIO_IDX_UART_CSR):
        if (nextChar == 0) {
          if (UARTQUEUE_Read(&nextChar) != UART_QUEUE_OK) {
            nextChar = 0;
          }
        }
        rval = UART_CSR_RX_READY | nextChar;
        break;
      case GPIO_ADDR(GPIO_IDX_MICROSECONDS):
        rval = SYSTICK_US() - _startTime;
        break;
      case GPIO_ADDR(GPIO_IDX_QSFP_IIC):
        // From eyescan.c
        //v = GPIO_READ(GPIO_IDX_QSFP_IIC);
        //rval = 0xfefe; // TODO - What is reality?
        rval = getQSFPDescChar();
        break;
      case GPIO_ADDR(0):
        break;
      case GPIO_ADDR(6):
        break;
      case GPIO_ADDR(8):
        break;
      case GPIO_ADDR(GPIO_IDX_AURORA_CSR):
        rval = auroraStatus;
        break;
      case GPIO_ADDR(10):
        break;
      case GPIO_ADDR(14):
        break;
      case GPIO_ADDR(28):
        // ? What's going on here?
        break;
      case GPIO_ADDR(29):
        break;
      case GPIO_ADDR(35):
        break;
#ifdef MARBLE
      case GPIO_ADDR(GPIO_IDX_NET_CONFIG_CSR):      // Marble bwudp
        break;
      case GPIO_ADDR(GPIO_IDX_NET_RX_CSR):
        // RX_CSR should return RX_CSR_R_MAC_BANK bit equal to RX_CSR_R_MAC_HBANK bit
        if (eth_inbox.pending == 0) {
          rval = RX_CSR_R_MAC_BANK; // Let's try just this for now.
        } else {
          printf("csr is 0\r\n");
        }
        break;
      case GPIO_ADDR(GPIO_IDX_NET_RX_DATA):
        // index 0 is 'length_status' where
        //    length = (((length_status & 0xF00) >> 1) | (length_status & 0x7F)) - 4;
        if (eth_inbox.index == 0) {
          rval = eth_inbox.length_status;
        } else if (eth_inbox.index < ETH_MAXWORDS) {
          rval = eth_inbox.pkt.words[eth_inbox.index-1];
        }
        break;
      case GPIO_ADDR(GPIO_IDX_NET_TX_CSR):
        // Return TX_CSR_R_BUSY when busy
        if (eth_outbox.pending) {
          rval = TX_CSR_R_BUSY;
        }
        break;
#endif // MARBLE
      case EVR_REG(0):
        break;
      case EVR_REG(1):
        break;
      case EVR_REG(2):
        break;
      case EVR_REG(3):
        break;
      case EVR_REG(4):
        break;
      case EVR_REG(5):
        break;
      case EVR_REG(6):
        break;
      case EVR_REG(7):
        break;
      case EVR_REG(8):
        break;
      case EVR_REG(9):
        break;
      case EVR_REG(10):
        break;
      case EVR_REG(11):
        break;
      case EVR_REG(12):
        break;
      case EVR_REG(13):
        break;
      case EVR_REG(14):
        break;
      case EVR_REG(15):
        break;
      case EVR_REG(16):
        break;
      case EVR_REG(17):
        // csr? Chip select register?
        // If rval & 0x01, tells EVR to use RAM_B, else RAM_A I guess.
        break;
      case EVR_REG(24):
        break;
      case EVR_REG(28):
        // Returning zero here means we should return a valid event in EVR_REG(31)?
        break;
      case EVR_REG(29):
        // Return seconds
        rval = (uint32_t)((SYSTICK_US() - _startTime)/1000000);
        break;
      case EVR_REG(30):
        // Return ticks
        rval = (uint32_t)(SYSTICK_US() - _startTime);
        break;
      case EVR_REG(31):
        // Return event code
        now = SYSTICK_US();
        if (now - ppscounter >= 1000000) {
          ppscounter = now;
          rval = EVENT_PPS;
        } else {
          rval = EVENT_HEARTBEAT;
        }
        break;
      case EYESCAN_LANE0(DRP_REG_ES_PS_VOFF): // eyescan Lane 0 DRP_REG_ES_PS_VOFF
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0xec
        rval = 0xcccc;
        break;
      case EYESCAN_LANE0(DRP_REG_ES_CSR): // eyescan Lane 0 DRP_REG_ES_CSR
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0xf4
        rval = 0xcccc;
        break;
      case EYESCAN_LANE0(DRP_REG_PMA_RSV2): // eyescan Lane 0 DRP_REG_PMA_RSV2
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x208
        rval = 0xcccc;
        break;
      case EYESCAN_LANE0(0xa8): // eyescan Lane 0 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x2a0
        rval = 0x4440;
        break;
      case EYESCAN_LANE0(0xa9): // eyescan Lane 0 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x2a4
        rval = 0x3330;
        break;
      case EYESCAN_LANE0(0xaa): // eyescan Lane 0 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x2a8
        rval = 0x2220;
        break;
      case EYESCAN_LANE0(0xab): // eyescan Lane 0 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x2ac
        rval = 0x1110;
        break;
      case EYESCAN_LANE0(0xac): // eyescan Lane 0 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x2b0:
        rval = 0x0000;
        break;
      case EYESCAN_LANE1(DRP_REG_ES_PS_VOFF): // eyescan Lane 1 DRP_REG_ES_PS_VOFF
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x8ec
        rval = 0xcccc;
        break;
      case EYESCAN_LANE1(DRP_REG_ES_CSR): // eyescan Lane 1 DRP_REG_ES_CSR
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x8f4
        rval = 0xcccc;
        break;
      case EYESCAN_LANE1(DRP_REG_PMA_RSV2): // eyescan Lane 1 DRP_REG_PMA_RSV2
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0xa08
        rval = 0xcccc;
        break;
      case EYESCAN_LANE1(0xa8): // eyescan Lane 1 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0xaa0
        rval = 0x4441;
        break;
      case EYESCAN_LANE1(0xa9): // eyescan Lane 1 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0xaa4
        rval = 0x3331;
        break;
      case EYESCAN_LANE1(0xaa): // eyescan Lane 1 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0xaa8
        rval = 0x2221;
        break;
      case EYESCAN_LANE1(0xab): // eyescan Lane 1 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0xaac
        rval = 0x1111;
        break;
      case EYESCAN_LANE1(0xac): // eyescan Lane 1 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0xab0
        rval = 0x1000;
        break;
      case EYESCAN_LANE2(DRP_REG_ES_PS_VOFF): // eyescan Lane 2 DRP_REG_ES_PS_VOFF
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x10ec
        rval = 0xcccc;
        break;
      case EYESCAN_LANE2(DRP_REG_ES_CSR): // eyescan Lane 2 DRP_REG_ES_CSR
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x10f4
        rval = 0xcccc;
        break;
      case EYESCAN_LANE2(DRP_REG_PMA_RSV2): // eyescan Lane 2 DRP_REG_PMA_RSV2
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x1208
        rval = 0xcccc;
        break;
      case EYESCAN_LANE2(0xa8): // eyescan Lane 2 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x12a0
        rval = 0x4442;
        break;
      case EYESCAN_LANE2(0xa9): // eyescan Lane 2 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x12a4
        rval = 0x3332;
        break;
      case EYESCAN_LANE2(0xaa): // eyescan Lane 2 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x12a8
        rval = 0x2222;
        break;
      case EYESCAN_LANE2(0xab): // eyescan Lane 2 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x12ac
        rval = 0x1112;
        break;
      case EYESCAN_LANE2(0xac): // eyescan Lane 2 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x12b0
        rval = 0x2000;
        break;
      case EYESCAN_LANE3(DRP_REG_ES_PS_VOFF): // eyescan Lane 3 DRP_REG_ES_PS_VOFF
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x18ec
        rval = 0xcccc;
        break;
      case EYESCAN_LANE3(DRP_REG_ES_CSR): // eyescan Lane 3 DRP_REG_ES_CSR
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x18f4
        rval = 0xcccc;
        break;
      case EYESCAN_LANE3(DRP_REG_PMA_RSV2): // eyescan Lane 3 DRP_REG_PMA_RSV2
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x1a08
        rval = 0xcccc;
        break;
      case EYESCAN_LANE3(0xa8): // eyescan Lane 3 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x1aa0
        rval = 0x4443;
        break;
      case EYESCAN_LANE3(0xa9): // eyescan Lane 3 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x1aa4
        rval = 0x3333;
        break;
      case EYESCAN_LANE3(0xaa): // eyescan Lane 3 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x1aa8
        rval = 0x2223;
        break;
      case EYESCAN_LANE3(0xab): // eyescan Lane 3 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x1aac
        rval = 0x1113;
        break;
      case EYESCAN_LANE3(0xac): // eyescan Lane 3 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x1ab0
        rval = 0x3000;
        break;
      case EYESCAN_LANE4(DRP_REG_ES_PS_VOFF): // eyescan Lane 4 DRP_REG_ES_PS_VOFF
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x20ec
        rval = 0xcccc;
        break;
      case EYESCAN_LANE4(DRP_REG_ES_CSR): // eyescan Lane 4 DRP_REG_ES_CSR
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x20f4
        rval = 0xcccc;
        break;
      case EYESCAN_LANE4(DRP_REG_PMA_RSV2): // eyescan Lane 4 DRP_REG_PMA_RSV2
        // XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x2208
        rval = 0xcccc;
        break;
      case EYESCAN_LANE4(0xa8): // eyescan Lane 4 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x22a0
        rval = 0x4444;
        break;
      case EYESCAN_LANE4(0xa9): // eyescan Lane 4 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x22a4
        rval = 0x3334;
        break;
      case EYESCAN_LANE4(0xaa): // eyescan Lane 4 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x22a8
        rval = 0x2224;
        break;
      case EYESCAN_LANE4(0xab): // eyescan Lane 4 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x22ac
        rval = 0x1114;
        break;
      case EYESCAN_LANE4(0xac): // eyescan Lane 4 RXCDR_CFG
        //XPAR_AURORA_DRP_BRIDGE_0_BASEADDR + 0x22b0
        rval = 0x4000;
        break;
      case XADC_ADDR(R_TEMP):
        break;
      case XADC_ADDR(R_VCCINT):
        break;
      case XADC_ADDR(R_VCCAUX):
        break;
      case XADC_ADDR(R_VBRAM):
        break;
      case XADC_ADDR(R_CFR0):
        break;
      case XADC_ADDR(R_CFR1):
        break;
      case XADC_ADDR(R_CFR2):
        break;
      case XADC_ADDR(R_SEQ00):
        break;
      case XADC_ADDR(R_SEQ01):
        break;
      case XADC_ADDR(R_SEQ02):
        break;
      case XADC_ADDR(R_SEQ03):
        break;
      case XADC_ADDR(R_SEQ04):
        break;
      case XADC_ADDR(R_SEQ05):
        break;
      case XADC_ADDR(R_SEQ06):
        break;
      case XADC_ADDR(R_SEQ07):
        break;
      default:
        printf("? 0x%x\r\n", addr);
        break;
    }
  }
  return rval;
}

void Xil_Out32(uint32_t addr, uint32_t val) {
  uint8_t c;
  if ((addr >= EVR_RAM_A(0)) && (addr < EVR_RAM_A(EVR_RAM_SIZE))) {
    evr_ram_a[EVR_RAM_INDEX_A(addr)] = val;
  } else if ((addr >= EVR_RAM_B(0)) && (addr < EVR_RAM_B(EVR_RAM_SIZE))) {
    evr_ram_b[EVR_RAM_INDEX_B(addr)] = val;
  } else {
    switch (addr) {
#ifdef MARBLE
      case GPIO_ADDR(GPIO_IDX_NET_CONFIG_CSR):      // Marble bwudp
        break;
      case GPIO_ADDR(GPIO_IDX_NET_RX_CSR):
        // RX_CSR should return RX_CSR_R_MAC_BANK bit equal to RX_CSR_R_MAC_HBANK bit
        break;
      case GPIO_ADDR(GPIO_IDX_NET_RX_DATA):
        // badger.c writes 'index' to this address
        eth_inbox.index = (int)val;
        if (val > 0) {
          eth_inbox.pending = 0;
        }
        break;
      case GPIO_ADDR(GPIO_IDX_NET_TX_CSR):
        // Data is output here... for some reason
        //GPIO_WRITE(GPIO_IDX_NET_TX_CSR, (index << TX_CSR_ADDRESS_SHIFT) | *p16);
        //wire [PK_TXBUF_DATA_WIDTH-1:0] sysTxData = sysGPIO_OUT[0+:PK_TXBUF_DATA_WIDTH];
        // wire [PK_TXBUF_ADDR_WIDTH-1:0] sysTxAddress = sysGPIO_OUT[PK_TXBUF_DATA_WIDTH+:PK_TXBUF_ADDR_WIDTH];
        // Data is bits 0-15, address is bits 16-25
        if (val == TX_CSR_W_START) {
          // Send the packet
          eth_outbox.ready = 1;
        } else {
          int addr = BADGER_TX_ADDR(val);
          uint32_t data = BADGER_TX_DATA(val);
          if (addr == 0) {
            // data is interpreted as frameLength
            eth_outbox.frameLength = data;
          } else {
            // data is packet data
            eth_outbox.pkt.shorts[addr-1] = data;
          }
        }
        break;
#endif // MARBLE
      case GPIO_ADDR(GPIO_IDX_UART_CSR):
        if (val == UART_CSR_RX_READY) {
          if (nextChar) {
            UARTQUEUE_Inc();
            nextChar = 0;
          }
        }
        c = (uint8_t)(val & 0xff);
        printf("%c", c);
        break;
      case GPIO_ADDR(GPIO_IDX_QSFP_IIC):
        setQSFPDescChar(val);
        // From eyescan.c
        //GPIO_WRITE(GPIO_IDX_QSFP_IIC, qidx);
        break;
      case GPIO_ADDR(GPIO_IDX_AURORA_CSR):
        if (val & CSR_GTX_RESET) {
          // I'm not sure how GTX reset and AURORA reset differ in terms of status bits
          auroraStatus &= (~0xF000);
        } else if (val & CSR_AURORA_RESET ) {
          auroraStatus &= (~0xF000);
        } else if (val & CSR_FA_ENABLE) {
          auroraStatus |= (0xF400);
        }
        break;
      default:
        break;
    }
  }
  return;
}

#ifndef MARBLE
int udpInit(uint32_t csrAddress, const char *name) {
  return 0;
}

int udpRxCheck32(unsigned int udpIndex, uint32_t *dest, int capacity) {
  return 0;
}

int udpTx32(unsigned int udpIndex, const uint32_t *src, int count) {
  return 0;
}

int udpTxIsBusy(unsigned int udpIndex) {
  return 0;
}

int udpRxCheck8(unsigned int udpIndex, uint8_t *dest, int capacity) {
  return 0;
}

int udpTx8(unsigned int udpIndex, const uint8_t *src, int count) {
  return 0;
}
#endif


