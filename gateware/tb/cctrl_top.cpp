/* sel project simulator
 */

#include "Vcctrl_verilator_top.h"
#include "verilated.h"
#include "queue_ref.h"
#include "udp_simple.h"
#include <signal.h>
#include <sys/time.h> // Needed for struct timeval
#include <unistd.h>   // For STDIN_FILENO
#include <stdio.h>

#define TRAPEXIT
#define UDP_PORT          (3001)
#define TERM_CHAR         ('\n')
static unsigned short udp_port;  /* Global */
static int toExit = 0;
static queue_t scrap_tx_queue;
static queue_t scrap_rx_queue;

typedef struct {
  int fill;     // buffer fill level in bytes
  int ready;    // Message waiting
  unsigned char buf[ETH_PAYLOAD_MAX];
} udp_buf_t;

static udp_buf_t eth_inbox;
static udp_buf_t eth_outbox;

static int sysService(void);
static void udpService(void);
static void _sigHandler(int c);
static void sysInit(const unsigned short udp_port);
static void buffer_data(unsigned char c);
static int get_next_byte(volatile unsigned char *c);
static void topInit(Vcctrl_verilator_top *top);
static void topTick(Vcctrl_verilator_top *top);

int main(int argc, char** argv, char** env) {
  //VerilatedContext *contextp = new VerilatedContext;
  //contextp->commandArgs(argc, argv);
  Verilated::commandArgs(argc, argv);
  printf("cctrl Verilator simulator\r\n");
  printf("  Run with +udp_port=NNNN to use an alternate port\r\n");
  // Determine UDP port number from command line options
  unsigned short udp_port = UDP_PORT;
  const char* udp_arg = Verilated::commandArgsPlusMatch("udp_port=");
  if (udp_arg && strlen(udp_arg) > 1) {
    const char* udp_int = strchr(udp_arg, '=');
    if (udp_int) udp_port = strtol(udp_int+1, NULL, 10);
  }
  sysInit(udp_port);
  // Initialize
  Vcctrl_verilator_top *top = new Vcctrl_verilator_top;
  topInit(top);
  int svcCounter = 0;
  unsigned char tx_data;
  int tx_delay = 0;
  // Generic variables to look for changes
  int v = 0;
  int v_0 = 0;
  int w = 0;
  int w_0 = 0;
  while (!toExit) {
    topTick(top);
    if (0) {
      // Handle bytes from cctrl_verilator_top
      // Service
      if (svcCounter++ == 8) {
        sysService();
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

static void topInit(Vcctrl_verilator_top *top) {
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
static void topTick(Vcctrl_verilator_top *top) {
  static int clkcounter = 0;
  int doBreak=0;
  while (1) {
    clkcounter++;
    if ((clkcounter % DIV_CLKIN125) == 0) {
      top->clkIn125 <= ~top->clkIn125;
      doBreak=1;
    }
    if ((clkcounter % DIV_EVRCLK) == 0) {
      top->evrClk <= ~top->evrClk;
      doBreak=1;
    }
    if ((clkcounter % DIV_SYSCLK) == 0) {
      top->sysClk <= ~top->sysClk;
      doBreak=1;
    }
    if ((clkcounter % DIV_AURORAUSERCLK) == 0) {
      top->auroraUserClk <= ~top->auroraUserClk;
      doBreak=1;
    }
    if (doBreak) break;
  }
  top->eval();
  return;
}

static void buffer_data(unsigned char c) {
  queue_ret_t rval;
  rval = QUEUE_Add(&scrap_tx_queue, (queue_item_t *)&c);
  int nchars;
  if (c == TERM_CHAR) {
    // Copy to eth_outbox.buf
    //printf("Detected TERM_CHAR\r\n");
    // TODO - Here I could instead shift until newline char to handle multiple messages in the buffer
    nchars = QUEUE_ShiftOut(&scrap_tx_queue, (queue_item_t *)eth_outbox.buf, QUEUE_MAX_ITEMS);
    //printf("Shifting %d bytes\r\n", nchars);
    eth_outbox.fill = nchars;
    eth_outbox.ready = 1;
  }
  return;
}

static int get_next_byte(volatile unsigned char *c) {
  return (int)QUEUE_Get(&scrap_rx_queue, (queue_item_t *)c);
}

static void sysInit(const unsigned short udp_port) {
#ifdef TRAPEXIT
  signal(SIGINT, _sigHandler);
#endif
  toExit = 0;
  QUEUE_Init(&scrap_tx_queue);
  QUEUE_Init(&scrap_rx_queue);
  int rc = udp_init(udp_port);
  if (rc != 0) {
    printf("Error in UDP initialization\r\n");
    return;
  } else {
    printf("Listening on port %d\r\n", udp_port);
  }
  eth_inbox.ready = 0;
  eth_inbox.fill = 0;

  eth_outbox.ready = 0;
  eth_outbox.fill = 0;
  return;
}

static int sysService(void) {
  udpService();
  return 0;
}

static void udpService(void) {
  // INBOX
  //int rc = udp_receive_meta(&eth_inbox.pkt.pkt);
  int rc = udp_receive(eth_inbox.buf, ETH_PAYLOAD_MAX);
  // NOTE: clobbers any existing data
  if (rc > 0) {
    eth_inbox.fill = rc;
    //printf("Got packet len %d\r\n", rc);
    eth_inbox.ready = 1;
    // Add to queue
    for (int n = 0; n < rc; n++) {
      if (QUEUE_Add(&scrap_rx_queue, (queue_item_t *)&(eth_inbox.buf[n])) == QUEUE_FULL) {
        printf("Broke early: n = %d\r\n", n);
        break;
      }
    }
  } else if (rc < 0) {
    printf("Receive error\r\n");
    toExit = 1;
    eth_inbox.ready = 0;
  }
  // OUTBOX
  if (eth_outbox.ready) {
    //rc = udp_reply(, (int)ETH_PAYLOAD_LENGTH(eth_outbox.frameLength));
    printf("udp_reply with %d bytes\r\n", eth_outbox.fill);
    rc = udp_reply(eth_outbox.buf, eth_outbox.fill);
    eth_outbox.fill = 0;
    eth_outbox.ready = 0;
  }
  return;
}

#ifdef TRAPEXIT
static void _sigHandler(int c) {
  printf("Exiting...\r\n");
  toExit = 1;
  return;
}
#endif


