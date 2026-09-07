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
out = {9{1'b0}};
	case(sel)
		9'b000000000 : out <= D1;
		9'b000000001 : out <= D2;
		9'b000000010 : out <= D3;
		9'b000000100 : out <= D4;
		9'b000001000 : out <= D5;
		9'b000010000 : out <= D6;
		9'b000100000 : out <= D7;
		9'b001000000 : out <= D8;
		9'b010000000 : out <= D9;
		9'b100000000 : out <= D10;
      default 		 : out <= {9{1'b0}};
		endcase
end
	

endmodule
