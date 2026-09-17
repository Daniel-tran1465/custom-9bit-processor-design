module register(
input logic clk,
input logic reset,
input logic enable,
input logic [8:0] Rin,
output logic [8:0] Rout
);

logic [8:0] R_inst;

assign R_inst = Rin;

always_ff@(posedge clk or negedge reset) begin
if(!reset) begin
	Rout <= {9{1'b0}};
end else begin
	if(enable == 1'b1) begin
		Rout <= R_inst;
	end
end
end

endmodule
