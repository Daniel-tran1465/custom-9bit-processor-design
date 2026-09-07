module Fulladder_1bit (
    input logic a, b, ci,
    output logic s, co
    );

    assign s = a^b^ci;
    assign co= a&b | ci&a | ci&b;

endmodule

