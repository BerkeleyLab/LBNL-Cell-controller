module OBUFT (output O, input I, input T);
    assign O = T? 1'bZ : I;
endmodule
