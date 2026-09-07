module centralprocessorunit (
input logic clk,
input logic reset,
input logic [8:0] DIN,
input logic Run,
output logic Done,
output logic [8:0] ADDRout,
output logic [8:0] D_OUT,
output logic W_out
);
////////////////////// //bus
logic [8:0] bus;
///////////////////// //regA, regG, Addsub
logic [8:0] reg_A_out;
logic [8:0] reg_G_in;
logic [8:0] reg_G_out;
logic co;
///////////////////// //register R0 to R7
logic [8:0] R0_out;
logic [8:0] R1_out;
logic [8:0] R2_out;
logic [8:0] R3_out;
logic [8:0] R4_out;
logic [8:0] R5_out;
logic [8:0] R6_out;
logic [8:0] R7_out;
///////////////////// // IR
logic [8:0] IRout;
///////////////////// //Control unit FSM
logic IRin;
logic Gout;
logic DINout;
logic [7:0] R_out;
logic AddSub;
logic A_in;
logic G_in;
logic [7:0] R_in;
logic ADDR_in;
logic DOUT_in;
logic W_D;
logic incr_pc;
////////////////////
logic G_nonzero;
logic G_lessthanzero;
assign G_nonzero = | Gout;
assign G_lessthanzero = reg_G_out[8];

////////////////////////////
register reg_A (
.clk(clk),
.reset(reset),
.enable(A_in),
.Rin(bus),
.Rout(reg_A_out)
);

Fulladder_8bit Addsub (
.A(reg_A_out), 
.B(bus),
.sum(reg_G_in),
.cin(AddSub),
.co(co)
);

register reg_G (
.clk(clk),
.reset(reset),
.enable(G_in),
.Rin(reg_G_in),
.Rout(reg_G_out)
);
////////////////////////////
register R0 (
.clk(clk),
.reset(reset),
.enable(R_in[0]),
.Rin(bus),
.Rout(R0_out)
);

register R1 (
.clk(clk),
.reset(reset),
.enable(R_in[1]),
.Rin(bus),
.Rout(R1_out)
);

register R2 (
.clk(clk),
.reset(reset),
.enable(R_in[2]),
.Rin(bus),
.Rout(R2_out)
);

register R3 (
.clk(clk),
.reset(reset),
.enable(R_in[3]),
.Rin(bus),
.Rout(R3_out)
);

register R4 (
.clk(clk),
.reset(reset),
.enable(R_in[4]),
.Rin(bus),
.Rout(R4_out)
);

register R5 (
.clk(clk),
.reset(reset),
.enable(R_in[5]),
.Rin(bus),
.Rout(R5_out)
);

register R6 (
.clk(clk),
.reset(reset),
.enable(R_in[6]),
.Rin(bus),
.Rout(R6_out)
);

R7_Counter R7 (
.clk(clk),
.reset(reset),
.enable(R_in[7]),
.counter_en(incr_pc),
.Rin(bus),
.Rout(R7_out)
);
/////////////////////////////
multiplexers mux_inst (
.D1(DIN),
.D2(R0_out),
.D3(R1_out),
.D4(R2_out),
.D5(R3_out),
.D6(R4_out),
.D7(R5_out),
.D8(R6_out),
.D9(R7_out),
.D10(reg_G_out),
.sel({DINout, Gout, R_out[7], R_out[6], R_out[5], R_out[4], R_out[3], R_out[2], R_out[1], R_out[0]}),
.out(bus)
);
///////////////////
register IR (
.clk(clk),
.reset(reset),
.enable(IRin),
.Rin(DIN),
.Rout(IRout)
);
///////////////////
ControlUnitFSM CUF_inst (
.run(Run),
.resetn(reset),
.clk(clk),
.DIN(DIN),
.G_nonzero(G_nonzero),
.G_lessthanzero(G_lessthanzero),
.IRin(IRin),
.R_out(R_out),
.Gout(Gout),
.DINout(DINout),
.R_in(R_in),
.Ain(A_in),
.AddSub(AddSub),
.Gin(G_in),
.Done(Done),
.ADDRin(ADDR_in),
.DOUTin(DOUT_in),
.W_D(W_D),
.incr_pc(incr_pc) 
);
//////////////////
register ADDR (
.clk(clk),
.reset(reset),
.enable(ADDR_in),
.Rin(bus),
.Rout(ADDRout)
);

register DOUT (
.clk(clk),
.reset(reset),
.enable(DOUT_in),
.Rin(bus),
.Rout(D_OUT)
);

register WD (
.clk(clk),
.reset(reset),
.enable(W_D),
.Rin(1'b1),
.Rout(W_out)
);
//////////////////
assign BusWires = bus;

endmodule
