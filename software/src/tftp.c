/*
 * Copyright 2020, Lawrence Berkeley National Laboratory
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS
 * AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Simple-minded TFTP server and dummy filesystem for bootstrap flash memory.
 * Certainly could be mangled by nefarious and/or duplicate clients.
 */
#include <stdio.h>
#include <string.h>
#include <xparameters.h>
#include "bootFlash.h"
#include "bwudp.h"
#include "gpio.h"
#include "iicProc.h"
#include "util.h"
#include "tftp.h"

#define TFTP_PORT 69

#define TFTP_OPCODE_RRQ   1
#define TFTP_OPCODE_WRQ   2
#define TFTP_OPCODE_DATA  3
#define TFTP_OPCODE_ACK   4
#define TFTP_OPCODE_ERROR 5

#define TFTP_ERROR_ACCESS_VIOLATION 2
#define TFTP_PAYLOAD_CAPACITY   512

#define TRANSFER_TIMEOUT_USEC 30000000 /* Assume client is gone after this */

#define FMC_EEPROM_SELECT (1UL<<31)

#define SYSTEM_PARAMETERS_NAME  "SystemParameters.bin"

struct fileInfo {
    const char *name;
    uint32_t    base;
    uint32_t    length;
    int         isText;
};

/* Assume that largest sector in flash is no larger than 64 KiB.
 * CCTRL_A.bit and CCTRL_B.bit size is 7 MiB. The first half of
 * flash is write protected.
 */
static const struct fileInfo fileTable[] = {
    { "CCTRL_A.bit",            MiB(FLASH_BITSTREAM_A_OFFSET), MiB(7),   0   },
    { "CCTRL_B.bit",            MiB(FLASH_BITSTREAM_B_OFFSET), MiB(7),   0   },
    { SYSTEM_PARAMETERS_NAME,   MiB(15)+KiB(0),               KiB(4),   0   },
    { "FullFlash.bin",          MiB(0),                       MiB(16),  0   },
    { "FMC1_EEPROM.bin",        FMC_EEPROM_SELECT+0,          256,      0   },
    { "FMC2_EEPROM.bin",        FMC_EEPROM_SELECT+1,          256,      0   } };
struct tftpPacket {
    uint16_t opcode;
    uint16_t arg;
    char     payload[TFTP_PAYLOAD_CAPACITY];
};
static int lastSendSize;
static char txBuf[TFTP_PAYLOAD_CAPACITY];

/*
 * Send a packet
 */
static void
sendPacket(bwudpHandle handle, int len)
{
    bwudpSend(handle, txBuf, len);
}

/*
 * Send an error reply
 */
static void
replyERR(bwudpHandle handle, const char *msg)
{
    int l = (2 * sizeof (uint16_t)) + strlen(msg) + 1;
    struct tftpPacket *txBufp = (struct tftpPacket *)txBuf;
    txBufp->opcode = htons(TFTP_OPCODE_ERROR);
    txBufp->arg = htons(TFTP_ERROR_ACCESS_VIOLATION);
    strcpy(txBufp->payload, msg);
    sendPacket(handle, l);
}

/*
 * Send a success reply
 */
static void
replyACK(bwudpHandle handle, int block)
{
    int l = 2 * sizeof (uint16_t);
    struct tftpPacket *txBufp = (struct tftpPacket *)txBuf;
    txBufp->opcode = htons(TFTP_OPCODE_ACK);
    txBufp->arg = htons(block);
    if (debugFlags & DEBUGFLAG_TFTP)
        printf("TFTP ACK block %d\n", block);
    sendPacket(handle, l);
}

/*
 * Send a data packet
 * Return 1 on success, 0 on failure
 */
static int
sendBlock(bwudpHandle handle, int block, uint32_t flashAddress, uint32_t bytesLeft)
{
    int l, nSend;
    struct tftpPacket *txBufp = (struct tftpPacket *)txBuf;
    nSend = bytesLeft;
    if (nSend > TFTP_PAYLOAD_CAPACITY)
        nSend = TFTP_PAYLOAD_CAPACITY;
    if (nSend) {
        if (flashAddress & FMC_EEPROM_SELECT) {
            if (!iicProcReadFMC_EEPROM(flashAddress & ~FMC_EEPROM_SELECT,
                                           (uint8_t *)txBufp->payload, nSend)) {
                replyERR(handle, "Read Error");
                return 0;
            }
        }
        else {
            if (bootFlashRead(flashAddress, nSend, txBufp->payload) != 0) {
                replyERR(handle, "Read Error");
                return 0;
            }
        }
    }
    l = (2 * sizeof(uint16_t)) + nSend;
    txBufp->opcode = htons(TFTP_OPCODE_DATA);
    txBufp->arg = htons(block);
    if (debugFlags & DEBUGFLAG_TFTP)
        printf("TFTP send %d (block %d) from %u\n", nSend, block,
                                                    (unsigned int)flashAddress);
    sendPacket(handle, l);
    lastSendSize = nSend;
    return 1;
}

static void
tftpHandler(bwudpHandle handle, char *payload, int length)
{
    /*
     * Processing a packet can take a long time if it results in a flash erase
     * operation.  We just just live with blocking network input while the
     * erase is active.
     * Ignore runt packets.
     */
    uint8_t *cp = (uint8_t *)payload;
    int opcode;
    static int isText;
    static uint32_t flashAddress;
    static uint32_t bytesLeft;
    static uint16_t lastBlock;
    static int fileIndex = -1;
    static uint32_t then;

    if (length < (2 * sizeof(uint16_t))) {
        return;
    }
    opcode = (cp[0] << 8) | cp[1];
    if (debugFlags & DEBUGFLAG_TFTP) {
        printf("TFTP %d OP:%d ARG:%d\n", length, opcode, (cp[2] << 8) | cp[3]);
    }
    if ((opcode == TFTP_OPCODE_RRQ) || (opcode == TFTP_OPCODE_WRQ)) {
        char *name = (char *)cp + sizeof(uint16_t), *mode = NULL;
        int nullCount = 0, i = 2;
        if ((fileIndex >= 0)
         && ((MICROSECONDS_SINCE_BOOT() - then) < TRANSFER_TIMEOUT_USEC)) {
            replyERR(handle, "Busy");
            return;
        }
        fileIndex = -1;
        for (;;) {
            if (i >= length) {
                replyERR(handle, "TFTP request too short");
                return;
            }
            if (cp[i++] == '\0') {
                nullCount++;
                if (nullCount == 1)
                    mode = (char *)cp + i;
                if (nullCount == 2) {
                    int f;
                    if (debugFlags & DEBUGFLAG_TFTP)
                        printf("NAME:%s  MODE:%s\n", name, mode);
                    if (strcasecmp(mode, "octet") != 0) {
                        replyERR(handle, "Bad Type");
                        return;
                    }
                    for (f = 0 ; f < sizeof fileTable/sizeof fileTable[0];f++) {
                        if (!strcmp(name, fileTable[f].name)) {
                            fileIndex = f;
                            break;
                        }
                    }
                    break;
                }
            }
        }
        if (fileIndex < 0) {
            replyERR(handle, "Bad Name");
            return;
        }
        flashAddress = fileTable[fileIndex].base;
        bytesLeft = fileTable[fileIndex].length;
        isText = fileTable[fileIndex].isText;
        if (opcode == TFTP_OPCODE_RRQ) {
            lastBlock = 1;
            if (!sendBlock(handle, lastBlock, flashAddress, bytesLeft)) {
                fileIndex = -1;
            }
            return;
        }
        else {
            lastBlock = 0;
            replyACK(handle, lastBlock);
        }
    }
    else if ((opcode == TFTP_OPCODE_DATA) && (fileIndex >= 0)) {
        uint16_t block = (cp[2] << 8) | cp[3];
        if (block == lastBlock) {
            replyACK(handle, block);
        }
        else if (block == (uint16_t)(lastBlock + 1)) {
            int nBytes = length - (2 * sizeof(uint16_t));
            lastBlock = block;
            if (nBytes > 0) {
                if (nBytes > bytesLeft) {
                    replyERR(handle, "File too big");
                    fileIndex = -1;
                    return;
                }
                else {
                    if (flashAddress & FMC_EEPROM_SELECT) {
                        if (!iicProcWriteFMC_EEPROM(
                                              flashAddress & ~FMC_EEPROM_SELECT,
                                              cp + (2 * sizeof(uint16_t)),
                                              nBytes)) {
                            replyERR(handle, "Write error");
                            fileIndex = -1;
                            return;
                        }
                    }
                    else {
                        if (bootFlashWrite(flashAddress, nBytes,
                                          (cp + (2 * sizeof(uint16_t)))) != 0) {
                            replyERR(handle, "Write error");
                            fileIndex = -1;
                            return;
                        }
                    }
                }
                flashAddress += nBytes;
                bytesLeft -= nBytes;
            }
            if (nBytes < TFTP_PAYLOAD_CAPACITY) {
                if (isText) {
                    if (bootFlashWrite(flashAddress, 1, "") != 0) {
                        replyERR(handle, "Write error");
                        fileIndex = -1;
                        return;
                    }
                }
                fileIndex = -1;
            }
            replyACK(handle, block);
        }
        then = MICROSECONDS_SINCE_BOOT();
    }
    else if ((opcode == TFTP_OPCODE_ACK) && (fileIndex >= 0)) {
        uint16_t block = (cp[2] << 8) | cp[3];
        if (block == lastBlock) {
            lastBlock++;
            flashAddress += lastSendSize;
            bytesLeft -= lastSendSize;
            if ((lastSendSize < TFTP_PAYLOAD_CAPACITY)
              || !sendBlock(handle, lastBlock, flashAddress, bytesLeft)) {
                    fileIndex = -1;
            }
        }
        else {
            sendPacket(handle, lastSendSize);
        }
        then = MICROSECONDS_SINCE_BOOT();
    }
}

void
tftpInit(void)
{
    if (bwudpRegisterServer(htons(TFTP_PORT), tftpHandler) < 0) {
        warn("Can't register TFTP server");
    }
}

static int
findSystemParameters(void)
{
    int f;
    for (f = 0 ; f < sizeof fileTable/sizeof fileTable[0];f++) {
        if (!strcmp(fileTable[f].name, SYSTEM_PARAMETERS_NAME)) {
            return f;
        }
    }
    return -1;
}

int
tftpReadSystemParameters(uint32_t length, void *buf)
{
    int f = findSystemParameters();
    if (f < 0) return -1;
    return bootFlashRead(fileTable[f].base, length, buf);
}

int
tftpWriteSystemParameters(uint32_t length, const void *buf)
{
    int f = findSystemParameters();
    if (f < 0) return -1;
    return bootFlashWrite(fileTable[f].base, length, buf);
}
