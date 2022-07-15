module FDP (Q, C, D, PRE);

    parameter INIT = 1'b1;

    output Q;
    reg    Q;

    input  C, D, PRE;

    always @(posedge PRE or posedge C)
        if (PRE)
        Q <= 1;
        else
        Q <= D;

endmodule
