module clock_divider #(
    parameter int CLK_FREQ = 100_000_000,   // 100 MHz
    parameter int PROC_HZ  = 2,             // processor chạy 2 Hz
    parameter int SCAN_HZ  = 1000           // 7-seg quét 1 kHz
)(
    input  logic clk,
    input  logic resetn,
    output logic clk_proc,     // clock chậm cho processor
    output logic clk_scan      // clock quét 7-seg
);

    localparam int PROC_DIV = CLK_FREQ / PROC_HZ;
    localparam int SCAN_DIV = CLK_FREQ / SCAN_HZ;

    logic [$clog2(PROC_DIV)-1:0] cnt_proc;
    logic [$clog2(SCAN_DIV)-1:0] cnt_scan;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            cnt_proc  <= '0;
            cnt_scan  <= '0;
            clk_proc  <= 1'b0;
            clk_scan  <= 1'b0;
        end else begin
            // ---- Slow clock cho processor ----
            if (cnt_proc == PROC_DIV-1) begin
                cnt_proc <= '0;
                clk_proc <= ~clk_proc;
            end else
                cnt_proc <= cnt_proc + 1'b1;

            // ---- Scan clock cho 7-seg ----
            if (cnt_scan == SCAN_DIV-1) begin
                cnt_scan <= '0;
                clk_scan <= ~clk_scan;
            end else
                cnt_scan <= cnt_scan + 1'b1;
        end
    end

endmodule