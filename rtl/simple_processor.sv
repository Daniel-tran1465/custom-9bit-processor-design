module simple_processor (
input logic Clock,
input logic Resetn,
input logic Run,
input logic [8:0] Button,
output logic Done,
output logic [8:0] LEDs,
output logic [7:0] anode_out,
output logic [7:0] ssd_cathode_out
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
logic Led_en_d, Seg_en_d;

logic clk_proc;
logic clk_scan;

logic [8:0] Segs;
logic [2:0] current_digit;


assign wr_en = W_D && ~(Q_inst[7] || Q_inst[8]);
assign Led_en_d = W_D && ~(~Q_inst[7] || Q_inst[8]);
assign Seg_en_d = W_D && ~(Q_inst[7] || ~Q_inst[8]);
assign Buttons_en = W_D && ~(~Q_inst[7] || ~Q_inst[8]);

assign processor_din =  (wr_en) ? Q_din : Q_din_buttons;


always_ff @(posedge Clock) begin
    Led_en <= Led_en_d;
    Seg_en <= Seg_en_d;
end

clock_divider #(
    .CLK_FREQ (100_000_000),
    .PROC_HZ  (20),
    .SCAN_HZ  (1000)
) Divider (
    .clk     (Clock),
    .resetn  (Resetn),
    .clk_proc(clk_proc),
    .clk_scan(clk_scan)
);

top_mem Memory (
.clk(Clock),
.ADDRESS(Q_inst),
.DATA(data_inst),
.q(Q_din),
.wr_en(wr_en)
);

centralprocessorunit Processor (
.clk(clk_proc),
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

bcd_decode DECODE_BCD(
.bcd(current_digit),
.ssd_cathode_out(ssd_cathode_out)
);

led_segment SEVEN_SEGMENT(
.clk(clk_scan),
.reset(Resetn),
.bus(Segs),
.current_digit(current_digit),
.anode_out(anode_out)
);

endmodule

