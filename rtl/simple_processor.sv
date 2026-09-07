module simple_processor (
input logic Clock,
input logic Resetn,
input logic Run,
input logic [8:0] Button,
output logic Done,
output logic [8:0] LEDs,
output logic [8:0] Segs
);

logic [8:0] Q_inst;
logic [8:0] data_inst;

logic [8:0] Q_din;
logic [8:0] Q_din_buttons;
logic [8:0] processor_din;

logic W_D;

logic wr_en;
logic Led_en;
logic Seg_en;
logic Buttons_en;

assign wr_en = W_D && ~(Q_inst[7] || Q_inst[8]);
assign Led_en = W_D && ~(~Q_inst[7] || Q_inst[8]);
assign Seg_en = W_D && ~(Q_inst[7] || ~Q_inst[8]);
assign Buttons_en = W_D && ~(~Q_inst[7] || ~Q_inst[8]);

assign processor_din = (wr_en) ? Q_din : Q_din_buttons;

top_mem Memory (
.clk(Clock),
.ADDRESS(Q_inst),
.DATA(data_inst),
.q(Q_din),
.wr_en(wr_en)
);

centralprocessorunit Processor (
.clk(Clock),
.reset(Resetn),
.DIN(processor_din),
.Run(Run),
.Done(Done),
.ADDRout(Q_inst),
.D_OUT(data_inst),
.W_out(W_D)
);

register LED(
.clk(Clock),
.reset(Resetn),
.enable(Led_en),
.Rin(data_inst),
.Rout(LEDs)
);

register Seven_Seg(
.clk(Clock),
.reset(Resetn),
.enable(Seg_en),
.Rin(data_inst),
.Rout(Segs)
);

register Buttons(
.clk(Clock),
.reset(Resetn),
.enable(Buttons_en),
.Rin(Button),
.Rout(Q_din_buttons)
);

endmodule
