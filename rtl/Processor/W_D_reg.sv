module W_D_reg(
input logic clk,
input logic reset,
input logic enable,
input logic Rin,
output logic Rout
);

logic  R_inst;

assign R_inst = Rin;

always_ff@(posedge clk or negedge reset) begin
if(!reset) begin
	Rout <= 1'b0;
end else begin
	if(enable == 1'b1) begin
		Rout <= R_inst;
	end
end
end

endmodule
