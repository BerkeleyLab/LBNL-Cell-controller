/* A subset of the QSFP I2C memory map
 * See: https://www.mouser.com/pdfdocs/AN-2152100GQSFP28LR4EEPROMmapRevC.pdf
 */
localparam QSFP_OVERRIDE_PRESENT     = 16;
localparam QSFP_MODULE_STATUS_OFFSET = 2;
localparam QSFP_TEMPERATURE_OFFSET   = 22;
localparam QSFP_VSUPPLY_OFFSET       = 26;
localparam QSFP_RXPOWER_0_OFFSET     = 34;
localparam QSFP_IDENTIFIER_OFFSET    =128;
localparam QSFP_VENDOR_NAME_OFFSET   =148;
localparam QSFP_PART_NAME_OFFSET     =168;
localparam QSFP_REVISION_CODE_OFFSET =184;
localparam QSFP_WAVELENGTH_OFFSET    =186;
localparam QSFP_SERIAL_NUMBER_OFFSET =196;
localparam QSFP_DATE_CODE_OFFSET     =212;

