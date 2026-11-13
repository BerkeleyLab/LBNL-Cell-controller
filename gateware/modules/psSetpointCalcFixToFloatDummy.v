//
// Dummy module
// Keep everything in scaled fixed point for now
// Provide a little latency
//
module psSetpointCalcFixToFloatDummy (
    input        aclk,
    input        s_axis_a_tvalid,
    input        s_axis_a_tlast,
    input [31:0] s_axis_a_tdata,
    output reg        m_axis_result_tvalid = 0,
    output reg        m_axis_result_tlast,
    output reg [31:0] m_axis_result_tdata);

reg s_axis_a_tvalid_d = 0, s_axis_a_tlast_d;
reg [31:0] s_axis_a_tdata_d;

always @(posedge aclk) begin
    s_axis_a_tvalid_d <= s_axis_a_tvalid;
    if (s_axis_a_tvalid) begin
        s_axis_a_tlast_d <= s_axis_a_tlast;
        s_axis_a_tdata_d <= $signed(s_axis_a_tdata[27:0]);
    end
    else begin
        s_axis_a_tlast_d <= 1'bx;
        s_axis_a_tdata_d <= {32{1'bx}};
    end
    m_axis_result_tvalid <= s_axis_a_tvalid_d;
    m_axis_result_tlast <= s_axis_a_tlast_d;
    m_axis_result_tdata <= s_axis_a_tdata_d;
end
endmodule
