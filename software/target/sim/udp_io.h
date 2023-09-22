#ifndef UDP_IO_H
#define UDP_IO_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <sys/socket.h>
#include <unistd.h>   /* socklen_t read() and write() */

#define ETH_MAXLEN 1500   /* maximum line nchars */

#define PROTOCOL_IPV4 0x0800

#ifndef NUM_UDP_CONNS
#define NUM_UDP_CONNS   (4)
#endif

typedef struct ipv4Address {
    uint8_t  a[4];
} ipv4Address;  // size 4

#define IPV4_TYPE_UDP   17
struct ipv4Header {
    uint8_t         type_len;
    uint8_t         dscp_ecn;
    uint16_t        length;
    uint16_t        identification;
    uint16_t        flags_offset;
    uint8_t         ttl;
    uint8_t         protocol;
    uint16_t        checksum;
    ipv4Address     source;
    ipv4Address     destination;
};  // size 20

/*****************************************************************************
 * UDP header
 */
struct udpHeader {
    uint16_t    sourcePort;
    uint16_t    destinationPort;
    uint16_t    length;
    uint16_t    checksum;
};  // size 8

#define ETH_PACKET_MIN                      (14 + sizeof(struct ipv4Header)-sizeof(struct udpHeader))
#define ETH_PAYLOAD_MAX   (ETH_MAXLEN-sizeof(struct ipv4Header)-sizeof(struct udpHeader))
#define ETH_PACKET_LENGTH(payloadLength)    (payloadLength + ETH_PACKET_MIN)
#define ETH_PAYLOAD_LENGTH(frameLength)     ((int)(frameLength - 42))
#define IPV4_ADDR_FROM_U32(ad)              {(ad & 0xFF000000) >> 24, (ad & 0xFF0000) >> 16, (ad & 0xFF00) >> 8, (ad & 0xFF)}

typedef struct {
  uint8_t           destinationMAC[6];
  uint8_t           sourceMAC[6];
  uint8_t           protocol[2];
  struct ipv4Header ipv4; // size 20
  struct udpHeader  udp;  // size 8
  char              payload[ETH_PAYLOAD_MAX]; // offset = 6 + 6 + 2 + 20 + 8 = 42
} eth_packet_t;

typedef union {
  eth_packet_t pkt;
  uint32_t words[sizeof(eth_packet_t)/sizeof(uint32_t)];
  uint16_t shorts[sizeof(eth_packet_t)/sizeof(uint16_t)];
} eth_union_t;

// ============================= Server API ==================================
int udp_server_init(unsigned short port);
// Backwards-compatible alias for udp_server_init
int udp_init(unsigned short port);
int udp_reply(int nconn, const void *src, int nchars);
// ============================= Client API ==================================
int udp_client_init(unsigned short port, uint32_t ipAddr);
int udp_send(int nconn, const void *src, int nchars);
// ========================= Server/Client API ===============================
int udp_receive(int nconn, void *dest, int nchars);
int udp_receive_meta(int nconn, eth_packet_t *pkt);


#ifdef __cplusplus
}
#endif

#endif  /* UDP_IO_H */
