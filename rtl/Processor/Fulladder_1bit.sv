module Fulladder_1bit (
    input logic a, b, ci,
    output logic s, co
    );
    
    logic b_inst;
    
    assign b_inst = b ^ ci;
    
    assign s = a^b_inst^ci;
    assign co= a&b_inst | ci&a | ci&b_inst;

endmodule

