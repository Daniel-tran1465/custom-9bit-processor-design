module Fulladder_1bit (
    input logic a, b, ci,
    output logic s, co
    );

    // Standard full adder. `b` is expected to already be pre-inverted by the
    // caller (Fulladder_9bit XORs B with the global subtract-select before
    // wiring it here) when doing two's-complement subtraction - this cell
    // itself just needs to ripple the real per-bit carry `ci` into `s`.
    assign s  = a ^ b ^ ci;
    assign co = (a & b) | (ci & (a ^ b));

endmodule

