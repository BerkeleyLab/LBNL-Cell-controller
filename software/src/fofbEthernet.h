#ifndef _FOFB_ETHERNET_H_
#define _FOFB_ETHERNET_H_

void fofbEthernetInit(void);
void fofbEthernetShowStatus(void);
uint32_t fofbEthernetGetPCSPMAstatus(void);
void fofbEthernetSetReadback(int idx, int mode);
void fofbEthernetBringUp(void);

#endif /* _FOFB_ETHERNET_H_ */
