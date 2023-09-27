/* sel project simulator
 */

#include "Vcctrl_verilator_top.h"
#include "verilated.h"
#include "queue_ref.h"
#include "udp_io.h"
#include <signal.h>
#include <sys/time.h> // Needed for struct timeval
#include <unistd.h>   // For STDIN_FILENO
#include <stdio.h>
#include <string.h>
#include "xil_io.h"
#include "simplatform.h"
#include "aurora_mux.h"

#define TRAPEXIT
#define UDP_PORT          (50007)
#define TERM_CHAR         ('\n')
static unsigned short udp_port;  /* Global */
static int toExit = 0;

// Queue's of stream_mux_pkt_t
static queue_t stream_tx_queue;
static queue_t stream_rx_queue;

typedef struct {
  int fill;     // buffer fill level in bytes
  int ready;    // Message waiting
  //unsigned char buf[ETH_PAYLOAD_MAX];
} udp_buf_t;

static int UDP_stream_conn=-1;

static int sysService(void);
static void udpService(void);
static void _sigHandler(int c);
static void sysInit(const unsigned short udp_port);
static void topInit(void);
static int topTick(int nticks);
static int topTickUntil(int clksel, int val);
static uint32_t get_gpio_in(uint32_t addr);
static void cpuService(void);
static void streamMuxService(void);
static void feedStream(stream_mux_pkt_t *pkt);

// Static reference to 'top'
static Vcctrl_verilator_top *top = new Vcctrl_verilator_top;

int main(int argc, char** argv, char** env) {
  //VerilatedContext *contextp = new VerilatedContext;
  //contextp->commandArgs(argc, argv);
  Verilated::commandArgs(argc, argv);
  printf("cctrl Verilator simulator\r\n");
  printf("  Run with +udp_port=NNNN to use an alternate port\r\n\r\n");
  // Determine UDP port number from command line options
  unsigned short udp_port = UDP_PORT;
  const char* udp_arg = Verilated::commandArgsPlusMatch("udp_port=");
  if (udp_arg && strlen(udp_arg) > 1) {
    const char* udp_int = strchr(udp_arg, '=');
    if (udp_int) udp_port = strtol(udp_int+1, NULL, 10);
  }
  sysInit(udp_port);
  // Initialize
  topInit();
  int svcCounter = 0;
  unsigned char tx_data;
  int tx_delay = 0;
  // Generic variables to look for changes
  int v = 0;
  int v_0 = 0;
  int w = 0;
  int w_0 = 0;
  while (!toExit) {
    topTick(0);
    // Service the Simulated CPU
    cpuService();
    sysService();
    if (0) {
      // Handle bytes from cctrl_verilator_top
      // Service
      if (svcCounter++ == 8) {
        svcCounter = 0;
      }
      if (tx_delay) {
        tx_delay--;
      }
    }
    top->eval();
  }
  printf("End\n");
  top->final();
  delete top;
  //delete contextp;
  return 0;
}

static void topInit(void) {
  top->clkIn125 = 0;  // 125 MHz
  top->evrClk = 0;    // 100 MHz ??
  top->sysClk = 0;    // 100 MHz
  top->auroraUserClk = 0; // 125 MHz
  top->eval();
  return;
}

// Pretending topTick is called at 1GHz,
// DIV=4 yields 125MHz, DIV=5 yields 100MHz
#define DIV_CLKIN125      (4)
#define DIV_EVRCLK        (5)
#define DIV_SYSCLK        (5)
#define DIV_AURORAUSERCLK (4)
static int topTick(int nticks) {
  static int clkcounter = 0;
  int doBreak=0;
  int breakFirst=0;
  if (nticks < 1) {
    breakFirst = 1;
    nticks = -1;
  }
  while (nticks-- != 0) {
    clkcounter++;
    if ((clkcounter % DIV_CLKIN125) == 0) {
      top->clkIn125 = !top->clkIn125;
      doBreak=1;
    }
    if ((clkcounter % DIV_EVRCLK) == 0) {
      top->evrClk = !top->evrClk;
      doBreak=1;
    }
    if ((clkcounter % DIV_SYSCLK) == 0) {
      top->sysClk = !top->sysClk;
      doBreak=1;
    }
    if ((clkcounter % DIV_AURORAUSERCLK) == 0) {
      top->auroraUserClk = !top->auroraUserClk;
      doBreak=1;
    }
    if ((breakFirst) && (doBreak)) break;
  }
  top->eval();
  return clkcounter;
}

/* static int topTickUntil(int clksel, int val);
 *  Tick until clock selected by 'clksel' is equal to value 'val' (0, 1)
 *  clksel values:
 *    0: clkIn125
 *    1: evrClk
 *    2: sysClk
 *    3: auroraUserClk
 */
#define CLKSEL_CLKIN125   (0)
#define CLKSEL_EVRCLK     (1)
#define CLKSEL_SYSCLK     (2)
#define CLKSEL_AUCLK      (3)
static int topTickUntil(int clksel, int val) {
  int loopmax = 100;
  topTick(1);
  switch (clksel) {
    case CLKSEL_CLKIN125:
      while ((top->clkIn125 != val) && (loopmax-- > 0)) {
        topTick(1);
      }
      break;
    case CLKSEL_EVRCLK:
      while ((top->evrClk != val) && (loopmax-- > 0)) {
        topTick(1);
      }
      break;
    case CLKSEL_SYSCLK:
      while ((top->sysClk != val) && (loopmax-- > 0)) {
        topTick(1);
      }
      break;
    case CLKSEL_AUCLK:
      while ((top->auroraUserClk != val) && (loopmax-- > 0)) {
        topTick(1);
      }
      break;
  }
  if (loopmax > 0) {
    return 0;
  }
  // Timed out waiting for clk == val
  return -1;
}

static void sysInit(const unsigned short udp_port) {
#ifdef TRAPEXIT
  signal(SIGINT, _sigHandler);
#endif
  toExit = 0;
  QUEUE_Init(&stream_tx_queue, sizeof(stream_mux_pkt_t));
  QUEUE_Init(&stream_rx_queue, sizeof(stream_mux_pkt_t));
  int rc = udp_server_init(udp_port);
  if (rc < 0) {
    printf("Error in UDP initialization\r\n");
    return;
  } else {
    UDP_stream_conn = rc;
    printf("Stream MUX listening on port %d\r\n", udp_port);
  }

  return;
}

#define SYS_SVC_INTERVAL      (1)
static int sysService(void) {
  static int svcCounter = 0;
  if ((svcCounter++)%SYS_SVC_INTERVAL == 0) {
    udpService();
    streamMuxService();
  }
  return 0;
}

static void udpService(void) {
  // INBOX
  stream_mux_pkt_t pkt;
  int rc = udp_receive(UDP_stream_conn, &pkt, sizeof(stream_mux_pkt_t));
  // NOTE: clobbers any existing data
  if (rc > 0) {
    //printf("rc = %d\r\n", rc);
    //printf("Got packet len %d\r\n", rc);
    // Add to queue
    if (QUEUE_Add(&stream_rx_queue, &pkt) == QUEUE_FULL) {
      printf("RX Aurora Packet Stream queue is full\r\n");
    }
  } else if (rc < 0) {
    printf("Receive error\r\n");
    toExit = 1;
  }
  // OUTBOX
  if (QUEUE_Get(&stream_rx_queue, &pkt) != QUEUE_EMPTY) {
    rc = udp_reply(UDP_stream_conn, &pkt, sizeof(stream_mux_pkt_t));
  }
  return;
}

static void streamMuxService(void) {
  // Handle packets destined for the Verilated model (from UDP socket)
  stream_mux_pkt_t pkt;
  //int out = QUEUE_ShiftOut(&stream_rx_queue, (queue_item_t *)&pkt, STREAM_PACKET_SIZE);
  //if (out == STREAM_PACKET_SIZE) {
  if (QUEUE_Get(&stream_rx_queue, &pkt) != QUEUE_EMPTY) {
    printf("pkt.muxinfo = 0x%x\r\n", pkt.muxinfo);
    printf("pkt.auHeader = 0x%x\r\n", pkt.auHeader);
    printf("pkt.auDataX = 0x%x\r\n", pkt.auDataX);
    printf("pkt.auDataY = 0x%x\r\n", pkt.auDataY);
    printf("pkt.auDataS = 0x%x\r\n", pkt.auDataS);
    feedStream(&pkt);
  }
  // Handle packets leaving the Verilated model (to UDP socket)
  if (top->stream_mux_valid) {
    pkt.muxinfo = PACK_MUXINFO(top->stream_mux_src);
    pkt.auHeader = top->stream_out_header;
    pkt.auDataX = top->stream_out_datax;
    pkt.auDataY = top->stream_out_datay;
    pkt.auDataS = top->stream_out_datas;
    if (QUEUE_Add(&stream_tx_queue, &pkt) == QUEUE_FULL) {
      printf("TX Aurora Packet Stream queue is full\r\n");
    } else {
      // Make sure we don't trigger again on the same strobe
      topTickUntil(CLKSEL_AUCLK, 0);
      topTickUntil(CLKSEL_AUCLK, 1);
    }
  }
  return;
}

static void feedStream(stream_mux_pkt_t *pkt) {
  if (((pkt->muxinfo >> 16) & 0xffff) != MUXINFO_MAGIC) {
    printf("Magic fail\r\n");
    return;
  }
  printf("Magic hit\r\n");
  topTickUntil(CLKSEL_AUCLK, 0);
  int nstream = (pkt->muxinfo) & 0x3;
  top->stream_mux_sel = nstream;
  top->stream_in_header = pkt->auHeader;
  top->stream_in_datax = pkt->auDataX;
  top->stream_in_datay = pkt->auDataY;
  top->stream_in_datas = pkt->auDataS;
  top->stream_mux_strobe = 1;
  topTickUntil(CLKSEL_AUCLK, 1);
  topTickUntil(CLKSEL_AUCLK, 0);
  top->stream_mux_strobe = 0;
  return;
}

#ifdef TRAPEXIT
static void _sigHandler(int c) {
  printf("Exiting...\r\n");
  toExit = 1;
  return;
}
#endif

// Number of times through the Verilator main loop before executing a CPU main loop
#define CPU_SVC_INTERVAL      (10)
static void cpuService(void) {
  static int svcCounter = 0;
  if ((svcCounter++)%CPU_SVC_INTERVAL == 0) {
    cpuMain();
  }
  return;
}

#define XPAR_AXI_LITE_GENERIC_REG_BASEADDR 0x44A30000
#define XPAR_AXI_LITE_GENERIC_REG_HIGHADDR 0x44A3FFFF
#define XPAR_BRAM_BPM_SETPOINTS_S_AXI_BASEADDR 0xC0000000U
#define XPAR_BRAM_BPM_SETPOINTS_S_AXI_HIGHADDR 0xC0001FFFU

#define GPIO_ADDR(index)    (XPAR_AXI_LITE_GENERIC_REG_BASEADDR+(4*(index)))

//Recall (gpio.h): #define GPIO_READ(i)    Xil_In32(XPAR_AXI_LITE_GENERIC_REG_BASEADDR+(4*(i)))
uint32_t vl_Xil_In32(uint32_t addrEnc) {
  uint32_t val = 0;
  uint32_t addrDec = 0;
  if ((addrEnc >= XPAR_AXI_LITE_GENERIC_REG_BASEADDR) && (addrEnc <= XPAR_AXI_LITE_GENERIC_REG_HIGHADDR)) {
    // GPIO_IN memory range
    addrDec = (addrEnc-XPAR_AXI_LITE_GENERIC_REG_BASEADDR)/4;
    val = get_gpio_in(addrDec);
  } else if ((addrEnc >= XPAR_BRAM_BPM_SETPOINTS_S_AXI_BASEADDR) && (addrEnc <= XPAR_BRAM_BPM_SETPOINTS_S_AXI_HIGHADDR)) {
    // BPM setpoint memory range
    // TODO - Figure out what we need to do here
  }
  return val;
}

//Recall (gpio.h): #define GPIO_WRITE(i,x) Xil_Out32(XPAR_AXI_LITE_GENERIC_REG_BASEADDR+(4*(i)),(x))
void vl_Xil_Out32(uint32_t addrEnc, uint32_t val) {
  uint32_t addrDec = 0;
  if ((addrEnc >= XPAR_AXI_LITE_GENERIC_REG_BASEADDR) && (addrEnc <= XPAR_AXI_LITE_GENERIC_REG_HIGHADDR)) {
    // GPIO_IN memory range
    addrDec = (addrEnc-XPAR_AXI_LITE_GENERIC_REG_BASEADDR)/4;
    top->GPIO_OUT = val;
    top->GPIO_STROBES = (1 << addrDec);
    topTick(0);
    top->GPIO_STROBES = 0;
  } else if ((addrEnc >= XPAR_BRAM_BPM_SETPOINTS_S_AXI_BASEADDR) && (addrEnc <= XPAR_BRAM_BPM_SETPOINTS_S_AXI_HIGHADDR)) {
    // BPM setpoint memory range
    // TODO - Figure out what we need to do here
  }
  return;
}

// This is so ugly...
static uint32_t get_gpio_in(uint32_t addr) {
  uint32_t val=0;
  switch (addr) {
    case 0:
      val = top->GPIO_IN0;
      break;
    case 1:
      val = top->GPIO_IN1;
      break;
    case 2:
      val = top->GPIO_IN2;
      break;
    case 3:
      val = top->GPIO_IN3;
      break;
    case 4:
      val = top->GPIO_IN4;
      break;
    case 5:
      val = top->GPIO_IN5;
      break;
    case 6:
      val = top->GPIO_IN6;
      break;
    case 7:
      val = top->GPIO_IN7;
      break;
    case 8:
      val = top->GPIO_IN8;
      break;
    case 9:
      val = top->GPIO_IN9;
      break;
    case 10:
      val = top->GPIO_IN10;
      break;
    case 11:
      val = top->GPIO_IN11;
      break;
    case 12:
      val = top->GPIO_IN12;
      break;
    case 13:
      val = top->GPIO_IN13;
      break;
    case 14:
      val = top->GPIO_IN14;
      break;
    case 15:
      val = top->GPIO_IN15;
      break;
    case 16:
      val = top->GPIO_IN16;
      break;
    case 17:
      val = top->GPIO_IN17;
      break;
    case 18:
      val = top->GPIO_IN18;
      break;
    case 19:
      val = top->GPIO_IN19;
      break;
    case 20:
      val = top->GPIO_IN20;
      break;
    case 21:
      val = top->GPIO_IN21;
      break;
    case 22:
      val = top->GPIO_IN22;
      break;
    case 23:
      val = top->GPIO_IN23;
      break;
    case 24:
      val = top->GPIO_IN24;
      break;
    case 25:
      val = top->GPIO_IN25;
      break;
    case 26:
      val = top->GPIO_IN26;
      break;
    case 27:
      val = top->GPIO_IN27;
      break;
    case 28:
      val = top->GPIO_IN28;
      break;
    case 29:
      val = top->GPIO_IN29;
      break;
    case 30:
      val = top->GPIO_IN30;
      break;
    case 31:
      val = top->GPIO_IN31;
      break;
    case 32:
      val = top->GPIO_IN32;
      break;
    case 33:
      val = top->GPIO_IN33;
      break;
    case 34:
      val = top->GPIO_IN34;
      break;
    case 35:
      val = top->GPIO_IN35;
      break;
    case 36:
      val = top->GPIO_IN36;
      break;
    case 37:
      val = top->GPIO_IN37;
      break;
    case 38:
      val = top->GPIO_IN38;
      break;
    case 39:
      val = top->GPIO_IN39;
      break;
    case 40:
      val = top->GPIO_IN40;
      break;
    case 41:
      val = top->GPIO_IN41;
      break;
    case 42:
      val = top->GPIO_IN42;
      break;
    case 43:
      val = top->GPIO_IN43;
      break;
    case 44:
      val = top->GPIO_IN44;
      break;
    case 45:
      val = top->GPIO_IN45;
      break;
    case 46:
      val = top->GPIO_IN46;
      break;
    case 47:
      val = top->GPIO_IN47;
      break;
    case 48:
      val = top->GPIO_IN48;
      break;
    case 49:
      val = top->GPIO_IN49;
      break;
    case 50:
      val = top->GPIO_IN50;
      break;
    case 51:
      val = top->GPIO_IN51;
      break;
    case 52:
      val = top->GPIO_IN52;
      break;
    case 53:
      val = top->GPIO_IN53;
      break;
    case 54:
      val = top->GPIO_IN54;
      break;
    case 55:
      val = top->GPIO_IN55;
      break;
    case 56:
      val = top->GPIO_IN56;
      break;
    case 57:
      val = top->GPIO_IN57;
      break;
    case 58:
      val = top->GPIO_IN58;
      break;
    case 59:
      val = top->GPIO_IN59;
      break;
    case 60:
      val = top->GPIO_IN60;
      break;
    case 61:
      val = top->GPIO_IN61;
      break;
    case 62:
      val = top->GPIO_IN62;
      break;
    case 63:
      val = top->GPIO_IN63;
      break;
    default:
      break;
  }
  return val;
}

