module multiplexers (
input logic [8:0] D1,
input logic [8:0] D2,
input logic [8:0] D3,
input logic [8:0] D4,
input logic [8:0] D5,
input logic [8:0] D6,
input logic [8:0] D7,
input logic [8:0] D8,
input logic [8:0] D9,
input logic [8:0] D10,
input logic [9:0] sel,
output logic [8:0] out
);

always_comb begin
out = 9'b0;
	case(sel)
		10'b0000000001 : out <= D1;
		10'b0000000010 : out <= D2;
		10'b0000000100 : out <= D3;
		10'b0000001000 : out <= D4;
		10'b0000010000 : out <= D5;
		10'b0000100000 : out <= D6;
		10'b0001000000 : out <= D7;
		10'b0010000000 : out <= D8;
		10'b0100000000 : out <= D9;
		10'b1000000000 : out <= D10;
      default 		 : out <= 9'b0;
		endcase
end
	

endmodule
