/* Generate traffic for cell controller tests
 */

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <time.h>   // For nanosleep()
#include "udp_io.h"
#include "ipcfg.h"
#include "aurora_mux.h"

#define TRAPEXIT
#define DEFAULT_UDP_PORT        (50007)
#define CELL_INDEX_INIT             (0)
#define CELL_INDEX_MAX             (15)

static void _sigHandler(int c);
static void _sendPacket(stream_mux_pkt_t *pkt, int nstream, int cell_index, int fofb_index);
static void _handlePacket(stream_mux_pkt_t *pkt);

const uint8_t defaultIP[] = {127, 0, 0, 1};
//const uint8_t defaultIP[] = {1, 0, 0, 127};

static int conn = -1;
static int toExit = 0;

static void waitms(int nms) {
  struct timespec minsleep = {1*(nms / 1000), 1000000*(nms % 1000)};
  nanosleep(&minsleep, NULL);
  return;
}

int main(int argc, char *argv[]) {
#ifdef TRAPEXIT
  signal(SIGINT, _sigHandler);
#endif
  stream_mux_pkt_t pkt;
  unsigned short udp_port = DEFAULT_UDP_PORT;
  uint32_t ip32 = PACK_IP32(defaultIP);
  if (argc > 1) {
    getIpPort(argv[1], &ip32, &udp_port, ip32, DEFAULT_UDP_PORT);
  }
  printf("Generating traffic on ");
  PRINT_IP32(ip32);
  printf(":%d\r\n", udp_port);
  conn = udp_client_init(udp_port, ip32);
  if (conn < 0) {
    printf("UDP initialization failed\r\n");
    return -1;
  }
  for (int n = CELL_INDEX_INIT; n < CELL_INDEX_MAX; n++) {
    // TODO Make valid FOFB indicies
    _sendPacket(&pkt, NSTREAM_CELL_CCW, n, 5);
    waitms(1);
    _handlePacket(&pkt);
    waitms(1);
    if (toExit) {
      break;
    }
  }
  return 0;
}

static void _sigHandler(int c) {
#ifdef TRAPEXIT
  printf("Exiting...\r\n");
  toExit = 1;
#endif
  return;
}

static void _sendPacket(stream_mux_pkt_t *pkt, int nstream, int cell_index, int fofb_index) {
  pkt->muxinfo = PACK_MUXINFO(nstream);
  pkt->auHeader = PACK_AUHEADER(1, cell_index, fofb_index);
  pkt->auDataX = 0x123456;
  pkt->auDataY = 0x789abc;
  pkt->auDataS = PACK_AUDATAS(0, 0, 0xdef000);
  udp_send(conn, (const void *)pkt, sizeof(stream_mux_pkt_t));
  return;
}

static void _handlePacket(stream_mux_pkt_t *pkt) {
  int rc;
  int cell_index;
  rc = udp_receive(conn, (void *)pkt, sizeof(stream_mux_pkt_t));
  if (rc > 0) {
    cell_index = UNPACK_CELL_INDEX(pkt->auHeader);
    printf("Received packet from cell index %d\r\n", cell_index);
    /*
    printf("inpkt.muxinfo = 0x%x\r\n", pkt->muxinfo);
    printf("inpkt.auHeader = 0x%x\r\n", pkt->auHeader);
    printf("inpkt.auDataX = 0x%x\r\n", pkt->auDataX);
    printf("inpkt.auDataY = 0x%x\r\n", pkt->auDataY);
    printf("inpkt.auDataS = 0x%x\r\n", pkt->auDataS);
    */
  }
  return;
}
