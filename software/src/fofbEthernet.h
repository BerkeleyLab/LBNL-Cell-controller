#ifndef _FOFB_ETHERNET_H_
#define _FOFB_ETHERNET_H_

#define PS_ETH_TX_IDX           0
#define PS_ETH_RX_IDX           1
#define PS_ETH_NUM_DEVICES      2

void fofbEthernetInit(void);
void fofbEthernetShowStatus(void);
uint32_t fofbEthernetGetPCSPMAstatus(void);
void fofbEthernetSetReadback(int idx, int mode);
void fofbEthernetBringUp(void);

#endif /* _FOFB_ETHERNET_H_ */
