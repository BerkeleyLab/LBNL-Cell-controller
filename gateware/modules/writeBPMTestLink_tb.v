`timescale 1ns / 100ps

module writeBPMTestLink_tb;

//
// Functions
//

function automatic f_gen_bit_one;
    input real prob;
    real temp;
begin
    // $random is surronded by the concat operator in order
    // to provide us with only unsigned (bit vector) data.
    // Generates valud in a 0..1 range
    temp = ({$random} % 100 + 1)/100.00;//threshold;

    if (temp <= prob)
        f_gen_bit_one = 1'b1;
    else
        f_gen_bit_one = 1'b0;
end
endfunction

function automatic f_gen_data_rdy_gen;
    input real prob;
begin
    f_gen_data_rdy_gen = f_gen_bit_one(prob);
end
endfunction

reg module_done = 0;
integer errors = 0;
integer idx = 0;
initial begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("writeBPMTestLink.vcd");
        $dumpvars(0, writeBPMTestLink_tb);
    end

    wait(module_done);
    $display("%s",errors==0?"# PASS":"# FAIL");
    $finish();
end

integer cc;
reg auClk = 0;
initial begin
    auClk = 0;
    for (cc = 0; cc < 3000; cc = cc+1) begin
        auClk = 1; #5;
        auClk = 0; #5;
    end
end

reg module_ready = 0;
reg auChannelUp = 0;

wire  [31:0] BPM_TEST_AXI_STREAM_TX_tdata;
wire         BPM_TEST_AXI_STREAM_TX_tvalid;
wire         BPM_TEST_AXI_STREAM_TX_tlast;
reg          BPM_TEST_AXI_STREAM_TX_tready;

// generate FA strobe every few clock cycles
localparam STROBE_CNT_MAX = 200;
localparam STROBE_CNT_WIDTH = $clog2(STROBE_CNT_MAX+1);

reg auFAStrobe = 0;
reg [STROBE_CNT_WIDTH-1:0] strobeCnt = 0;
always @(posedge auClk) begin
    if (!module_ready) begin
        strobeCnt <= 0;
        auFAStrobe <= 0;
    end
    else begin
        strobeCnt <= strobeCnt + 1;
        auFAStrobe <= 0;

        if (strobeCnt == STROBE_CNT_MAX) begin
            strobeCnt <= 0;
            auFAStrobe <= 1;
        end

    end
end

// Generate READY signal with some probability
always @(posedge auClk) begin
    if (!module_ready) begin
        BPM_TEST_AXI_STREAM_TX_tready <= 0;
    end
    else begin
        BPM_TEST_AXI_STREAM_TX_tready <= f_gen_data_rdy_gen(0.5);
    end
end

//
// BPM test data streamer
//

writeBPMTestLink #()
  DUT(
    .auroraUserClk(auClk),
    .auroraFAstrobe(auFAStrobe),
    .auroraChannelUp(auChannelUp),

    // BPM links
    .BPM_TEST_AXI_STREAM_TX_tdata(BPM_TEST_AXI_STREAM_TX_tdata),
    .BPM_TEST_AXI_STREAM_TX_tvalid(BPM_TEST_AXI_STREAM_TX_tvalid),
    .BPM_TEST_AXI_STREAM_TX_tlast(BPM_TEST_AXI_STREAM_TX_tlast),
    .BPM_TEST_AXI_STREAM_TX_tready(BPM_TEST_AXI_STREAM_TX_tready)
);

// stimulus
initial begin
    @(posedge auClk);
    module_ready = 1;

    repeat (200)
        @(posedge auClk);

    auChannelUp = 1;
    @(posedge auClk);
end

endmodule
