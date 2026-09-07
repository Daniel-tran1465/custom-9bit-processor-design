module top_mem (
input logic clk,
input logic [8:0] ADDRESS,
input logic [8:0] DATA,
input logic wr_en,
output logic q
);

MyROM U0 (
.clk (clk ),
.ADDRESS (ADDRESS ),
.DATAOUT (DATA ),
.q(q),
.wr_en(wr_en)
);

endmodule
