module fmpsReadLinksCell #(
    parameter SYSCLK_RATE       = 100000000,
    parameter INDEX_WIDTH       = 5,
    parameter    FAstrobeDebug  = "false",
    parameter      statusDebug  = "false",
    parameter     rawDataDebug  = "false",
    parameter     ccwLinkDebug  = "false",
    parameter      cwLinkDebug  = "false",
    parameter   fmpsCountDebug  = "false",
    parameter  readoutDebug  = "false"
    ) (
    input  wire        sysClk,

    // Control/Status
    input wire                                                    csrStrobe,
    input wire                                             [31:0] GPIO_OUT,
    (*mark_debug=statusDebug*) output wire                 [31:0] csr,
    (*mark_debug=statusDebug*) output wire [(1<<INDEX_WIDTH)-1:0] fmpsBitmapAllFASnapshot,
    (*mark_debug=statusDebug*) output wire [(1<<INDEX_WIDTH)-1:0] fmpsEnableBitmapFASnapshot,

    (*mark_debug=statusDebug*) output wire [(1<<INDEX_WIDTH)-1:0] fmpsBitmapAll,
    (*mark_debug=statusDebug*) output wire [(1<<INDEX_WIDTH)-1:0] fmpsBitmapEnabled,
    (*mark_debug=statusDebug*) output wire                        fmpsEnabled,

    output wire [INDEX_WIDTH-1:0] fmpsIndex,
    output wire            [31:0] fmpsData,
    output wire                   fmpsValid,

    // Synchronization
    (*mark_debug=FAstrobeDebug*) input  wire FAstrobe,

    // Link statistics
    (*mark_debug=statusDebug*) output wire       sysStatusStrobe,
    (*mark_debug=statusDebug*) output wire [2:0] sysStatusCode,
    (*mark_debug=statusDebug*) output wire       sysTimeoutStrobe,

    // Values to microBlaze
    input  wire                       uBreadoutStrobe,
    output wire                [31:0] uBreadout,

    // Start of Aurora user clock domain nets
    input  wire                              auClk,
    (*mark_debug=FAstrobeDebug*) input  wire auFAstrobe,
    input  wire                              auReset,
    output wire                              auCCWfmpsInhibit,
    output wire                              auCWfmpsInhibit,

    // Tap of outgoing FMPS links
    (*mark_debug=rawDataDebug*) input  wire        auFMPSCCWlinkTVALID,
    (*mark_debug=rawDataDebug*) input  wire        auFMPSCCWlinkTLAST,
    (*mark_debug=rawDataDebug*) input  wire [31:0] auFMPSCCWlinkTDATA,

    (*mark_debug=rawDataDebug*) input  wire        auFMPSCWlinkTVALID,
    (*mark_debug=rawDataDebug*) input  wire        auFMPSCWlinkTLAST,
    (*mark_debug=rawDataDebug*) input  wire [31:0] auFMPSCWlinkTDATA);

wire      [INDEX_WIDTH-1:0] fmpsReadoutAddress;
wire                [31:0] fmpsReadout;

fmpsReadLinks #(.SYSCLK_RATE(SYSCLK_RATE),
                .INDEX_WIDTH(INDEX_WIDTH),
                .FAstrobeDebug(FAstrobeDebug),
                .statusDebug(statusDebug),
                .rawDataDebug(rawDataDebug),
                .ccwLinkDebug(ccwLinkDebug),
                .cwLinkDebug(cwLinkDebug),
                .fmpsCountDebug(fmpsCountDebug),
                .readoutDebug(readoutDebug))
  fmpsReadLinks (
       .sysClk(sysClk),
       .csrStrobe(csrStrobe),
       .GPIO_OUT(GPIO_OUT),
       .csr(csr),

       .fmpsBitmapAllFASnapshot(fmpsBitmapAllFASnapshot),
       .fmpsEnableBitmapFASnapshot(fmpsEnableBitmapFASnapshot),
       .fmpsEnabled(fmpsEnabled),

       .fmpsBitmapAll(fmpsBitmapAll),
       .fmpsBitmapEnabled(fmpsBitmapEnabled),

       .FAstrobe(FAstrobe),
       .auReset(auReset),
       .sysStatusStrobe(sysStatusStrobe),
       .sysStatusCode(sysStatusCode),
       .sysTimeoutStrobe(sysTimeoutStrobe),

       .fmpsReadoutAddress(fmpsReadoutAddress),
       .fmpsReadout(fmpsReadout),

       .uBreadoutStrobe(uBreadoutStrobe),
       .uBreadout(uBreadout),

       .auClk(auClk),
       .auFAstrobe(auFAstrobe),
       .auCCWfmpsInhibit(auCCWfmpsInhibit),
       .auCWfmpsInhibit(auCWfmpsInhibit),

       .auFMPSCCWlinkTVALID(auFMPSCCWlinkTVALID),
       .auFMPSCCWlinkTLAST(auFMPSCCWlinkTLAST),
       .auFMPSCCWlinkTDATA(auFMPSCCWlinkTDATA),

       .auFMPSCWlinkTVALID(auFMPSCWlinkTVALID),
       .auFMPSCWlinkTLAST(auFMPSCWlinkTLAST),
       .auFMPSCWlinkTDATA(auFMPSCWlinkTDATA)
   );

   fmpsReadoutStream fmpsReadoutStream (
       .sysClk(sysClk),
       .fmpsCSR(csr),

       .fmpsBitmapAll(fmpsBitmapAll),
       .fmpsReadoutAddress(fmpsReadoutAddress),
       .fmpsReadout(fmpsReadout),

       .fmpsIndex(fmpsIndex),
       .fmpsData(fmpsData),
       .fmpsValid(fmpsValid)
   );

endmodule
