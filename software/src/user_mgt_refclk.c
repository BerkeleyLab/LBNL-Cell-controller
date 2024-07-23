/*
 * Configure User MGT reference clock (SI570)
 * Complicated by the fact that the SI570 I2C address differs between boards.
 */

#include <stdio.h>
#include <stdint.h>
#include "user_mgt_refclk.h"
#include "iicProc.h"
#include "util.h"
#include "mmcMailbox.h"
#include "gpio.h"

/*
** Si57x defines and variables
*/
#define MARBLE_v1_2                               0
#define MARBLE_v1_3                               1
#define MARBLE_v1_4                               2
#define MARBLE_v1_5                               3
#define MB_PCB_REV_ADDR                        0x48
#define MB_SI570_I2C_ADDR                      0x60
#define MB_SI570_CONFIG_ADDR                   0x61
#define MB_SI570_FREQ_ADDR                     0x62
#define F_DCO_MIN                 (4.85*1000000000)
#define F_DCO_MAX                 (5.67*1000000000)
#define SI570_DEFAULT_TARGET_FREQUENCY  125000000.0
struct si57x_part_numbers {
    uint8_t iicAddr;
    double startupFrequency;
    int outputEnablePolarity;
    int temperatureStability;
} si57x_pn[] = {
    {0x55, 100000000, 1, 0}, // Part number 570BBC000121DG
    {0x75, 312500000, 1, 0}, // Part number 570BBB000309DG
    {0x77, 125000000, 0, 1}, // Part number 570NCB000933DG
    {0x55, 270000000, 0, 0}, // Part number 570NBB001808DG
};
struct marble_onboard_oscillators {
    uint8_t pcb_rev;
    struct si57x_part_numbers *si57x_information[5];
} marble_ob_xo[] = {
    {MARBLE_v1_2, {&si57x_pn[0], &si57x_pn[1], NULL}},
    {MARBLE_v1_3, {&si57x_pn[2], NULL}},
    {MARBLE_v1_4, {&si57x_pn[3], NULL}},
};
struct si57x_part_numbers si570_parameters = {0, 0, 0, 0};
static uint8_t Si570_reg_idx = 13; // internal register address


static int
setReg(int reg, int value)
{
    uint8_t cv = value;
    return iicProcWrite(si570_parameters.iicAddr, reg, &cv, 1);
}

 /**
 Perform small changes in the Si570 output frequency without interrupt the signal.
 Note: it require to call refInit() almost once to find iic address, and
 @param  offsetPPM the amount of ppm (referring to the current frequency) to be changed.
 */
static int
refSmallChanges(int offsetPPM)
{
    int i;
    uint8_t buf[5];
    uint64_t rfreq;

    if (offsetPPM > 3500) offsetPPM = 3500;
    else if (offsetPPM < -3500) offsetPPM = -3500;
    if (!iicProcSetMux(IIC_MUX_PORT_PORT_EXPANDER)) return 0;
    if (!iicProcRead(si570_parameters.iicAddr, Si570_reg_idx+1, buf, 5)) return 0;
    rfreq = buf[0] & 0x3F;
    for (i = 1 ; i < 5 ; i++) {
        rfreq = (rfreq << 8) | buf[i];
    }
    rfreq = ((rfreq * (1000000 + offsetPPM)) + 500000) / 1000000;
    for (i = 4 ; i > 0 ; i--) {
        buf[i] = rfreq & 0xFF;
        rfreq >>= 8;
    }
    buf[0] = (buf[0] & ~0x3F) | (rfreq & 0x3F);

    if (!setReg(137, 0x10)) return 0;
    if (!iicProcWrite(si570_parameters.iicAddr, Si570_reg_idx+1, buf, 5)) return 0;
    if (!setReg(137, 0x00)) return 0;
    if (!setReg(135, 0x40)) return 0;
    return 1;
}

 /**
 Set the Si570 target frequency and configure U39 IO0_0 polarity.
 Note: it require to call iicProcTakeControl() before
 @param  defaultFrequency the initial frequency of the batch.
 @param  targetFrequency desired frequency
 @param  enablePolarity insert 1 in case of Si570_OE active high, otherwise set it 0.
 @param  temperatureStability use 1 for 7 ppm type, otherwise set it 0 for  20 ppm and 50 ppm.
*/
static int
refInit(double defaultFrequency, double targetFrequency, uint8_t enablePolarity, uint8_t temperatureStability)
{
    int i;
    uint8_t buf[6], U39reg, hsdiv_reg, hsdiv_new=11, n1_reg, n1_new=128;
    uint64_t rfreq_reg;
    static const uint8_t hsdiv_values[] = { 11, 9, 7, 6, 5, 4 };

    // Internal register address definition according temperature stability (see datasheet)
    if(temperatureStability == 1)
        Si570_reg_idx = 13;
    else if (temperatureStability == 0)
        Si570_reg_idx = 7;

    if (!iicProcSetMux(IIC_MUX_PORT_PORT_EXPANDER)) return 0; //select Y6 and U39 channel

    if (!iicProcRead(0x21, 0, &U39reg, 1)) return 0; // read the IO0 register
    if(enablePolarity == 1) // drive the output of U39 (IO0_0 connected to Si570_EO)
        U39reg |= 0x1; // set the bit IO0_0 to 1
    else
        U39reg &= 0xFE; // set the bit IO0_0 to 0
    if (!iicProcWrite(0x21, 2, &U39reg, 1)) return 0; // set IO0 output register

    if (!setReg(135, 0x01)) return 0; // Reset the device to initial frequency
    if (!iicProcRead(si570_parameters.iicAddr, Si570_reg_idx, buf, 6)) return 0; // read the device registers

    /*  Buffer structure:
        [0] |HS_DIV[2:0] N1[6:2] |
        [1] |N1[1:0] RFREQ[37:32]|
        [2] |    RFREQ[31:24]    |
        [3] |    RFREQ[23:16]    |
        [4] |    RFREQ[15:8]     |
        [5] |    RFREQ[7:0]      |  */
    // Data decodification
    hsdiv_reg = (buf[0] >> 5) + 4;
    n1_reg = ((buf[0] & 0x1F)<<2 | (buf[1] >> 6)) + 1;
    rfreq_reg = (buf[1] & 0x3F);
    for (i = 2 ; i < 6 ; i++) {
        rfreq_reg = (rfreq_reg << 8) | buf[i];
    }

    // Internal cristal frequency
    double f_xtal = (defaultFrequency * hsdiv_reg * n1_reg)/(rfreq_reg/268435456.0);

    // Calculate HSDIV, N1, RFREQ with lower power consumption
    double F_DCO_MIN_FOUT_ratio_threshold = F_DCO_MIN / targetFrequency;
    for (uint8_t j=0; j<6; j++) {
        uint8_t hsdiv_tmp = hsdiv_values[j];
        double ratio = F_DCO_MIN_FOUT_ratio_threshold/hsdiv_tmp;
        uint8_t n1_tmp = ((ratio)-((uint32_t) ratio))*10 > 0 ? ratio+1 : ratio;
        if(n1_tmp & 1) n1_tmp++;
        if( (hsdiv_tmp*n1_tmp) < (hsdiv_new*n1_new) )
        {
            n1_new = n1_tmp;
            hsdiv_new = hsdiv_tmp;
        }
    }
    rfreq_reg = (uint64_t)( (( targetFrequency * hsdiv_new * n1_new / f_xtal))*268435456.0);
    buf[0] = ((hsdiv_new-4)<<5 & 0xE0) | ((n1_new-1)>>2 & 0x1F);
    buf[1] = ((n1_new-1)<<6 & 0xC0) | (rfreq_reg>>32 & 0x3F);
    for (i = 2; i < 6; i++) {
        buf[i]= (rfreq_reg>>((5-i)*8) & 0xFF);
    }

    // Command to set new frequency
    if (!setReg(137, 0x10)) return 0; // Freeze the DCO (bit4 - reg137)
    if (!iicProcWrite(si570_parameters.iicAddr, Si570_reg_idx, buf, 6)) return 0; // Writing the data registers
    if (!setReg(137, 0x00)) return 0; // Unfreeze the DCO (bit4 - reg137)
    if (!setReg(135, 0x40)) return 0; // Trigger new frequency (bit4 - reg135)
    return 1;
}

int
readSI570parameterFromPCBrev()
{
    uint8_t pcb_version = mmcMailboxRead(MB_PCB_REV_ADDR) & 0xf; // [0:3]=PCB rev
    printf("PCB version %d detected - using Si570 associated parameters.\n", pcb_version+2);
    iicProcSetMux(IIC_MUX_PORT_PORT_EXPANDER);
    for (uint8_t i=0; i < ARRAY_SIZE(marble_ob_xo); i++) {
        if (marble_ob_xo[i].pcb_rev == pcb_version) {
            for(uint8_t j=0; j<ARRAY_SIZE(marble_ob_xo[i].si57x_information); j++) {
                if (marble_ob_xo[i].si57x_information[j] == NULL) {
                    return 0;
                }
                if (iicProcWrite(marble_ob_xo[i].si57x_information[j]->iicAddr, -1, NULL, 0)) { // i2c address matches
                    si570_parameters.iicAddr = marble_ob_xo[i].si57x_information[j]->iicAddr;
                    si570_parameters.startupFrequency = marble_ob_xo[i].si57x_information[j]->startupFrequency;
                    si570_parameters.outputEnablePolarity = marble_ob_xo[i].si57x_information[j]->outputEnablePolarity;
                    si570_parameters.temperatureStability = marble_ob_xo[i].si57x_information[j]->temperatureStability;
                    return 1;
                }
            }
        }
    }
    return 0;
}

int
readSI570parameterFromMailbox()
{
    uint8_t i2c_address = 0;
    uint32_t initialFrequency = 0;

    i2c_address = mmcMailboxRead(MB_SI570_I2C_ADDR)>>1;
    for (uint8_t i = 0; i<4; i++) {
        initialFrequency |=  mmcMailboxRead(MB_SI570_FREQ_ADDR+i)<<((3-i)*8);
    }
    uint8_t config = mmcMailboxRead(MB_SI570_CONFIG_ADDR);
    // Mailbox configuration validity check
    if(i2c_address == 0 || initialFrequency == 0 || (config & 0x40) != 0x40) {
        warn("Reading Si570 information from mailbox failed.");
        if(debugFlags & DEBUGFLAG_SI570_SETTING) {
            printf("\tMailbox information read:\n\t*) ADDR=0x%02x\n\t*) FREQ=%d Hz\n\t*) CONF=0x%02x\n",
                    i2c_address, initialFrequency, config);
        }
        return 0;
    }
    si570_parameters.iicAddr = i2c_address;
    si570_parameters.startupFrequency = initialFrequency;
    si570_parameters.outputEnablePolarity = config & 0x1;
    si570_parameters.temperatureStability = (config & 0x2)>>1;
    print("Using Si570 parameters stored in mailbox.\n");
    return 1;
}

int
userMGTrefClkAdjust(int offsetPPM)
{
    int r = 0;
    iicProcTakeControl();
    if (si570_parameters.iicAddr == 0) {
        // Method 1 - fetching parameter from mailbox
        if(!readSI570parameterFromMailbox()) {
            // Method 2 - using PCB rev value
            if(!readSI570parameterFromPCBrev()) {
                warn("Unable to find Si570 I2C address. Aborting initialization.");
                return 0;
            }
        }
    }
    r = refInit(si570_parameters.startupFrequency,
                SI570_DEFAULT_TARGET_FREQUENCY,
                si570_parameters.outputEnablePolarity,
                si570_parameters.temperatureStability);
    r &= refSmallChanges(offsetPPM);
    iicProcRelinquishControl();
    if(debugFlags & DEBUGFLAG_SI570_SETTING) {
        printf("Si570_parameters:\n");
        printf("\t*) I2C_address = 0x%2x\n", si570_parameters.iicAddr);
        printf("\t*) startupFrequency = %d Hz\n", (uint32_t)si570_parameters.startupFrequency);
        printf("\t*) outputEnablePolarity = %d\n", si570_parameters.outputEnablePolarity);
        printf("\t*) temperatureStability = %d\n", si570_parameters.temperatureStability);
    }
    if (r) {
        printf("MGT SI570 (0x%02X) successfully updated.\n", si570_parameters.iicAddr);
    }
    else {
        warn("Unable to update MGT SI570");
    }
    return r;
}
