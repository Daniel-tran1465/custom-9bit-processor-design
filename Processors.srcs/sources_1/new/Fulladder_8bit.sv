module Fulladder_9bit (
    input logic [8:0] A, B,
	 input logic cin,
    output logic [8:0] sum,
    output logic co
);
logic [6:0] temp;
logic [8:0] B_eff;

// Two's-complement adder/subtractor: invert every bit of B when cin==1
// (subtract) so the ripple-carry chain below just needs to add A + B_eff
// with an initial carry-in of cin (the "+1" that completes A + ~B + 1).
assign B_eff = B ^ {9{cin}};

 Fulladder_1bit U1 (
     .a(A[0]),
     .b(B_eff[0]),
     .ci(cin),
     .s(sum[0]),
     .co(temp[0])
    );

 Fulladder_1bit U2 (
     .a(A[1]),
     .b(B_eff[1]),
     .ci(temp[0]),
     .s(sum[1]),
     .co(temp[1])
    );

 Fulladder_1bit U3 (
     .a(A[2]),
     .b(B_eff[2]),
     .ci(temp[1]),
     .s(sum[2]),
     .co(temp[2])
    );

 Fulladder_1bit U4 (
     .a(A[3]),
     .b(B_eff[3]),
     .ci(temp[2]),
     .s(sum[3]),
     .co(temp[3])
    );

 Fulladder_1bit U5 (
     .a(A[4]),
     .b(B_eff[4]),
     .ci(temp[3]),
     .s(sum[4]),
     .co(temp[4])
    );

 Fulladder_1bit U6 (
     .a(A[5]),
     .b(B_eff[5]),
     .ci(temp[4]),
     .s(sum[5]),
     .co(temp[5])
    );

 Fulladder_1bit U7 (
     .a(A[6]),
     .b(B_eff[6]),
     .ci(temp[5]),
     .s(sum[6]),
     .co(temp[6])
    );

 Fulladder_1bit U8 (
     .a(A[7]),
     .b(B_eff[7]),
     .ci(temp[6]),
     .s(sum[7]),
     .co(temp[7])
    );

 Fulladder_1bit U9 (
     .a(A[8]),
     .b(B_eff[8]),
     .ci(temp[7]),
     .s(sum[8]),
     .co(co)
    );
endmodule
