module Fulladder_8bit (
    input logic [7:0] A, B,
	 input logic cin,
    output logic [7:0] sum,
    output logic co
);
logic [6:0] temp;
 Fulladder_1bit U1 (
     .a(A[0]),
     .b(B[0]),
     .ci(cin),
     .s(sum[0]),
     .co(temp[0])
    );

 Fulladder_1bit U2 (
     .a(A[1]),
     .b(B[1]),
     .ci(temp[0]),
     .s(sum[1]),
     .co(temp[1])
    );

 Fulladder_1bit U3 (
     .a(A[2]),
     .b(B[2]),
     .ci(temp[1]),
     .s(sum[2]),
     .co(temp[2])
    );

 Fulladder_1bit U4 (
     .a(A[3]),
     .b(B[3]),
     .ci(temp[2]),
     .s(sum[3]),
     .co(temp[3])
    );

 Fulladder_1bit U5 (
     .a(A[4]),
     .b(B[4]),
     .ci(temp[3]),
     .s(sum[4]),
     .co(temp[4])
    );

 Fulladder_1bit U6 (
     .a(A[5]),
     .b(B[5]),
     .ci(temp[4]),
     .s(sum[5]),
     .co(temp[5])
    );

 Fulladder_1bit U7 (
     .a(A[6]),
     .b(B[6]),
     .ci(temp[5]),
     .s(sum[6]),
     .co(temp[6])
    );

 Fulladder_1bit U8 (
     .a(A[7]),
     .b(B[7]),
     .ci(temp[6]),
     .s(sum[7]),
     .co(co)
    );

endmodule
