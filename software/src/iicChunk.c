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
 * IIC readout using i2c_chunk firmware
 */
#include <stdio.h>
#include "gpio.h"
#include "iicChunk.h"
#include "iicCommandTable.h"
#include "util.h"

#define CSR_RESET           0x80000000
#define CSR_FREEZE          0x40000000
#define CSR_RUN             0x20000000
#define CSR_R_ERROR         0x10000000
#define CSR_W_WRITE         0x10000000
#define CSR_ADDR_WIDTH_MASK 0xF000000
#define CSR_ADDR_WIDTH_SHIFT 24
#define CSR_DATA_MASK       0xFF0000
#define CSR_DATA_SHIFT      16
#define CSR_UPDATED         0x8000

#define IIC_INA219_COUNT        3
#define IIC_IDX_INA219_BASE     U17_SHUNTV
#define IIC_IDX_INA219_STRIDE   4

/* QSFP */
#define QSFP_COUNT              2
#define QSFP_INFO_SIZE          (QSFP1_TEMPERATURE_SIZE + \
                                    QSFP1_VSUPPLY_SIZE + \
                                    QSFP1_RXPOWER_SIZE + \
                                    QSFP1_TXBIAS_SIZE + \
                                    QSFP1_TXPWR_SIZE)
#define QSFP_WORD_SIZE          4
#define QSFP_INFO_SIZE_WORD     (QSFP_INFO_SIZE/QSFP_WORD_SIZE)
#define QSFP1_IDX_PER_CHANNEL_BASE  QSFP1_TEMPERATURE
#define QSFP2_IDX_PER_CHANNEL_BASE  QSFP2_TEMPERATURE

static int iicReadbackBase;
void
iicChunkInit(void)
{
    uint32_t csr = GPIO_READ(GPIO_IDX_I2C_CHUNK_CSR);
    int addressWidth = (csr & CSR_ADDR_WIDTH_MASK) >> CSR_ADDR_WIDTH_SHIFT;
    int capacity = 1 << addressWidth;

    iicReadbackBase = capacity / 2;
    GPIO_WRITE(GPIO_IDX_I2C_CHUNK_CSR, CSR_RESET);
    GPIO_WRITE(GPIO_IDX_I2C_CHUNK_CSR, 0);
    GPIO_WRITE(GPIO_IDX_I2C_CHUNK_CSR, CSR_RUN);
    microsecondSpin(100000);
    csr = GPIO_READ(GPIO_IDX_I2C_CHUNK_CSR);
    if (csr & CSR_R_ERROR) warn("I2C error");
    if (!(csr & CSR_RUN)) warn("I2C not running");
}

static int
grab8(int offset)
{
    GPIO_WRITE(GPIO_IDX_I2C_CHUNK_CSR, CSR_FREEZE | CSR_RUN |
                                                    (iicReadbackBase + offset));
    return (GPIO_READ(GPIO_IDX_I2C_CHUNK_CSR)&CSR_DATA_MASK) >> CSR_DATA_SHIFT;
}

static int
grab16(int offset)
{
    int vh = grab8(offset);
    int vl = grab8(offset+1);
    return (vh << 8) | vl;
}

uint32_t *
iicChunkReadback(uint32_t *buf)
{
    int i, b;

    GPIO_WRITE(GPIO_IDX_I2C_CHUNK_CSR, CSR_FREEZE | CSR_RUN);

    *buf++ = (grab8(U39_PORT_DATA+1) << 24) |
             (grab8(U39_PORT_DATA) << 16) |
             (grab8(U34_PORT_DATA+1) << 8)  |
              grab8(U34_PORT_DATA);
    for (i = 0, b = IIC_IDX_INA219_BASE ; i < IIC_INA219_COUNT ;
                                              i++, b += IIC_IDX_INA219_STRIDE) {
        *buf++ = (grab16(b+2) << 16) | grab16(b);
    }

    /* QSFP 1 */
    for (i = 0, b = QSFP1_IDX_PER_CHANNEL_BASE ; i < QSFP_INFO_SIZE_WORD ;
        i++, b += QSFP_WORD_SIZE) {
        *buf++ = (grab16(b+2) << 16) | grab16(b);
    }

    /* QSFP 2 */
    for (i = 0, b = QSFP2_IDX_PER_CHANNEL_BASE ; i < QSFP_INFO_SIZE_WORD ;
        i++, b += QSFP_WORD_SIZE) {
        *buf++ = (grab16(b+2) << 16) | grab16(b);
    }

    GPIO_WRITE(GPIO_IDX_I2C_CHUNK_CSR, CSR_RUN);
    return buf;
}

int
iicChunkIsQSFPpresent(int channel)
{
    if (channel < 0 || channel > 1) {
        return 0;
    }

    return (grab8(U34_PORT_DATA + channel) & 0x20) == 0;
}

void
iicChunkSuspend(void)
{
    uint32_t then;
    GPIO_WRITE(GPIO_IDX_I2C_CHUNK_CSR, 0);
    then = MICROSECONDS_SINCE_BOOT();
    while (GPIO_READ(GPIO_IDX_I2C_CHUNK_CSR) & CSR_RUN) {
        if ((MICROSECONDS_SINCE_BOOT() - then) >= 80000) {
            printf("iicSuspend failed!\n");
            break;
        }
    }
}

void
iicChunkResume(void)
{
    GPIO_WRITE(GPIO_IDX_I2C_CHUNK_CSR, CSR_RUN);
}
