module MyROM
#(parameter int unsigned width = 9,
parameter int unsigned depth = 128,
parameter string initFile = "my_ROM.mem",
parameter int unsigned addrBits = 9)
(
input logic clk,
input logic [addrBits-1:0] ADDRESS,
input logic [width-1:0] DATAOUT,
output logic [8:0] q,
input logic wr_en
);


logic [width-1:0] rom [0:depth-1];

initial begin
    if (initFile != "") begin
        $readmemb(initFile, rom);
    end
end

always_ff @ (posedge clk)
begin
	if(wr_en == 1'b1) begin
		rom[ADDRESS] <= DATAOUT;
	end
end

assign q = rom[ADDRESS];

endmodule
