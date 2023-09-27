/*  File: udp_io.c
 *  Desc: Re-entrant UDP comms API
 */

#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <unistd.h>   /* socklen_t read() and write() */
#include <fcntl.h>
#include <stdint.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

#include "udp_io.h"

typedef struct {
  unsigned char buf[ETH_MAXLEN];
} pkt_t;

#define CONN_TYPE_UNINITIALIZED     (0)
#define CONN_TYPE_SERVER            (1)
#define CONN_TYPE_CLIENT            (2)

#define UNPACK_IP32(ip32, ip_dest)     do {\
  ip_dest[3] = (ip32 >> 24) & 0xff;\
  ip_dest[2] = (ip32 >> 16) & 0xff;\
  ip_dest[1] = (ip32 >> 8) & 0xff;\
  ip_dest[0] = ip32 & 0xff;\
} while (0)

typedef struct {
  unsigned short udp_port;
  struct sockaddr_in src_addr;
  socklen_t src_addrlen;
  int udpfd;
  int type;
} conn_t;

static int _udp_receive(int nconn, void *dest, int nchars, int flags);

static conn_t conns[NUM_UDP_CONNS];
static int conn_next = 0;
static pkt_t pkt;


// ============================= Server API ==================================
// Alias for backwards compatibility
int udp_init(unsigned short port) {
  return udp_server_init(port);
}

int udp_server_init(unsigned short port) {
  if (conn_next >= NUM_UDP_CONNS) {
    printf("Ran out of connection memory. Increase NUM_UDP_CONNS or use heap.");
    return -1;
  }
  conn_t *pconn = &conns[conn_next];
  if ((pconn->udpfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
    printf("socket error\r\n");
    return -1;
  }
  struct sockaddr_in sa_rcvr;
  memset(&sa_rcvr, 0, sizeof(sa_rcvr));
  sa_rcvr.sin_family=AF_INET;
  sa_rcvr.sin_addr.s_addr=htonl(INADDR_ANY);
  sa_rcvr.sin_port=htons(port);
  if (bind(pconn->udpfd, (struct sockaddr *)&sa_rcvr, sizeof(sa_rcvr)) == -1) {
    printf("could not bind to udp port %u\r\n", port);
    return -1;
  }
  fcntl(pconn->udpfd, F_SETFL, O_NONBLOCK);
  pconn->udp_port = port;
  pconn->type = CONN_TYPE_SERVER;
  return conn_next++;
}

static int _udp_receive(int nconn, void *dest, int nchars, int flags) {
  if ((nconn < 0) || (nconn >= conn_next)) {
    printf("Invalid connection number: %d (only %d connections type)\r\n",
           nconn, conn_next);
    return -1;
  }
  conn_t *pconn = &conns[nconn];
  if (pconn->type == CONN_TYPE_UNINITIALIZED) {
    printf("Connection %d not initialized.\r\n", nconn);
    return -1;
  }
  int rc;
  pconn->src_addrlen = sizeof(struct sockaddr_in);
  rc = recvfrom(pconn->udpfd, pkt.buf, ETH_MAXLEN, flags, (struct sockaddr *)&(pconn->src_addr), &(pconn->src_addrlen));
  int nmax = nchars > rc ? rc : nchars; // min(rc, nchars)
  if (rc < 0) {
    if (errno == EAGAIN) {
      return 0;
    } else {
      printf("Error; errno = %s (%d)\r\n", strerror(errno), errno);
      return (int)(-errno);
    }
  } else {
    for (int n = 0; n < nmax; n++) {
      *((char *)dest + n) = pkt.buf[n];
    }
  }
  return nmax;
}

int udp_receive(int nconn, void *dest, int nchars) {
  return _udp_receive(nconn, dest, nchars, MSG_DONTWAIT);
}

int udp_receive_wait(int nconn, void *dest, int nchars) {
  return _udp_receive(nconn, dest, nchars, 0);
}

int udp_receive_meta(int nconn, eth_packet_t *pkt) {
  int rc = udp_receive(nconn, (void *)pkt->payload, ETH_PAYLOAD_MAX);
  if (rc > 0) {
    conn_t *pconn = &conns[nconn];
    //pkt->destinationMAC = {0, 0, 0, 0, 0, 0};
    //pkt->sourceMAC = {0, 0, 0, 0, 0, 0};
    pkt->protocol[0] = 0x08;
    pkt->protocol[1] = 0x00; // PROTOCOL_IPV4. Network byte order?
    pkt->ipv4.type_len = 0;
    pkt->ipv4.dscp_ecn = 0;
    pkt->ipv4.length = ETH_PACKET_LENGTH(rc);
    pkt->ipv4.identification = 0;
    pkt->ipv4.flags_offset = 0;
    pkt->ipv4.ttl = 255;
    pkt->ipv4.protocol = IPV4_TYPE_UDP;
    pkt->ipv4.checksum = 0;
    *(uint32_t *)&(pkt->ipv4.source) = pconn->src_addr.sin_addr.s_addr;
    //pkt->ipv4.destination = {0, 0, 0, 0};
    //printf("rc = 0x%x\r\n", rc);
    pkt->udp.length = htons(rc);
    //printf("udp.length = 0x%x\r\n", pkt->udp.length);
    pkt->udp.destinationPort = pconn->udp_port;
    pkt->udp.sourcePort = pconn->src_addr.sin_port;
    return ETH_PACKET_LENGTH(rc);
  }
  return 0;
}

int udp_reply(int nconn, const void *src, int nchars) {
  if ((nconn < 0) || (nconn >= conn_next)) {
    printf("Invalid connection number: %d (only %d connections type)\r\n",
           nconn, conn_next);
    return -1;
  }
  conn_t *pconn = &conns[nconn];
  if (pconn->type != CONN_TYPE_SERVER) {
    printf("Connection %d not server-type.\r\n", nconn);
    return -1;
  }
  int rc = sendto(pconn->udpfd, (char *)src, nchars, 0, (struct sockaddr *)&(pconn->src_addr), pconn->src_addrlen);
  //printf("rc = %d\r\n", rc);
  return rc;
}

// ============================= Client API ==================================
int udp_client_init(unsigned short port, uint32_t ipAddr) {
  if (conn_next >= NUM_UDP_CONNS) {
    printf("Ran out of connection memory. Increase NUM_UDP_CONNS or use heap.");
    return -1;
  }
  conn_t *pconn = &conns[conn_next];
  if ((pconn->udpfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
    printf("socket error\r\n");
    return -1;
  }
  memset(&pconn->src_addr, 0, sizeof(struct sockaddr_in));
  pconn->src_addr.sin_family=AF_INET;
  pconn->src_addr.sin_addr.s_addr=ipAddr; // Already in network-byte-order uint32_t //inet_addr(ipAddr);
  pconn->src_addr.sin_port=htons(port);

  int rc = connect(pconn->udpfd, (const struct sockaddr *)&pconn->src_addr, (socklen_t)sizeof(struct sockaddr_in));
  if (rc != 0) {
    printf("connect failed. rc = %d\r\n", rc);
    return -1;
  }
  pconn->type = CONN_TYPE_CLIENT;
  pconn->src_addrlen = sizeof(struct sockaddr_in);
  return conn_next++;
}

int udp_send(int nconn, const void *src, int nchars) {
  if ((nconn < 0) || (nconn >= conn_next)) {
    printf("Invalid connection number: %d (only %d connections type)\r\n", nconn, conn_next);
    return -1;
  }
  conn_t *pconn = &conns[nconn];
  if (pconn->type != CONN_TYPE_CLIENT) {
    printf("udp_send must use client-type connections. Use udp_reply for server-type\r\n");
    return -1;
  }
  errno = 0;
  int rc = sendto(pconn->udpfd, (char *)src, nchars, 0, (struct sockaddr *)&pconn->src_addr, sizeof(struct sockaddr));
  if (rc < 0) {
    printf("rc = %d, errno = %d\r\n", rc, errno);
    perror("Goofed");
  }
  printf("rc = %d\r\n", rc);
  return rc;
}
