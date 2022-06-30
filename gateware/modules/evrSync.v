//
// Provide fast acquisition marker synchronized to event
//
module evrSync #(
    parameter FA_DIVISOR = 152 * 328 / 4,
    parameter WATCHDOG   = 124640000 / FA_DIVISOR) (
    input      clk, 
    input      triggerIn,
    input      FAenable,
    output reg FAmarker = 0,
    output reg isSynchronized = 0,
    output reg triggered = 0);

reg                           triggerIn_d1;
reg    [$clog2(WATCHDOG)-1:0] watchdog = 0;
reg  [$clog2(FA_DIVISOR)-1:0] fa_counter = 0;
reg                     [4:0] fa_stretch = 0;

always @(posedge clk) begin
    // Generate outputs
    if (fa_counter == 0) begin
        if (FAenable) FAmarker <= 1;
        fa_stretch <= ~0;
    end
    else if (fa_stretch == 0) begin
        FAmarker <= 0;
    end
    else begin
        fa_stretch <= fa_stretch - 1;
    end

    // Synchronize with event system
    triggerIn_d1 <= triggerIn;
    if (triggerIn && !triggerIn_d1) begin
        if (fa_counter == 0) begin
            isSynchronized <= 1;
        end
        else begin
            isSynchronized <= 0;
        end
        triggered <= 1;
        watchdog <= WATCHDOG - 1;
        fa_counter <= FA_DIVISOR - 1;
    end
    else begin
        if (fa_counter == 0) begin
            fa_counter <= FA_DIVISOR - 1;
            if (watchdog == 0) begin
                triggered <= 0;
            end
            else begin
                watchdog <= watchdog - 1;
            end
        end
        else begin
            fa_counter <= fa_counter - 1;
        end
    end
end

endmodule
