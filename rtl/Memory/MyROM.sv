module MyROM
#(parameter int unsigned width = 9,
parameter int unsigned depth = 32,
parameter string intFile = "my_ROM.mif",
parameter int unsigned addrBits = 9)
(
input logic clk,
input logic [addrBits-1:0] ADDRESS,
input logic [width-1:0] DATAOUT,
output logic [8:0] q,
input logic wr_en
);


(* ram_init_file = intFile *) logic [width-1:0] rom [0:depth-1];

always_ff @ (posedge clk)
begin
if(clk) begin
	if(wr_en == 1'b1) begin
		q <= rom[ADDRESS];
	end else begin
		q <= DATAOUT;
	end
end
end

endmodule
