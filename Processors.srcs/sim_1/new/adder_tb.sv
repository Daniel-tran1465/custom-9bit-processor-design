`timescale 1ns/1ps
//
// Unit-level testbench for Fulladder_9bit (the ALU core, built from a
// Fulladder_1bit ripple chain). Purely combinational DUT, no clock needed.
//
// To run: set this module as the simulation top (Vivado Simulation Settings,
// or a separate simulation fileset/set) instead of tb.sv.
//
module adder_tb;
    logic [8:0] A, B;
    logic cin;
    logic [8:0] sum;
    logic co;

    Fulladder_9bit dut (
        .A(A),
        .B(B),
        .sum(sum),
        .cin(cin),
        .co(co)
    );

    int pass_count = 0;
    int fail_count = 0;

    task automatic check_add(input logic [8:0] a, input logic [8:0] b);
        logic [9:0] expected;
        A = a; B = b; cin = 1'b0;
        #1;
        expected = {1'b0, a} + {1'b0, b};
        if (sum === expected[8:0] && co === expected[9]) begin
            $display("  [PASS] %0d + %0d = %0d (co=%0b)", a, b, sum, co);
            pass_count++;
        end else begin
            $display("  [FAIL] %0d + %0d : exp sum=%0d co=%0b, got sum=%0d co=%0b",
                      a, b, expected[8:0], expected[9], sum, co);
            fail_count++;
        end
    endtask

    task automatic check_sub(input logic [8:0] a, input logic [8:0] b);
        logic [8:0] expected;
        A = a; B = b; cin = 1'b1;
        #1;
        expected = 9'(a - b);
        if (sum === expected) begin
            $display("  [PASS] %0d - %0d = %0d", a, b, $signed(sum));
            pass_count++;
        end else begin
            $display("  [FAIL] %0d - %0d : exp=%0d, got=%0d", a, b, expected, sum);
            fail_count++;
        end
    endtask

    initial begin
        int i;

        $display("\n[ADDER] Directed addition cases");
        check_add(9'd0,   9'd0);
        check_add(9'd1,   9'd0);
        check_add(9'd0,   9'd1);
        check_add(9'd1,   9'd1);     // requires carry propagation out of bit0
        check_add(9'd255, 9'd1);     // carry ripples across a byte boundary
        check_add(9'd511, 9'd1);     // full-width overflow -> co==1
        check_add(9'd170, 9'd85);    // 10101010 + 01010101, no carries generated
        check_add(9'd255, 9'd255);

        $display("\n[ADDER] Directed subtraction cases");
        check_sub(9'd0,   9'd0);
        check_sub(9'd5,   9'd3);
        check_sub(9'd3,   9'd5);     // negative result, exercises the borrow chain
        check_sub(9'd0,   9'd1);     // negative result, exercises the borrow chain
        check_sub(9'd255, 9'd1);
        check_sub(9'd511, 9'd511);

        $display("\n[ADDER] Randomized addition/subtraction");
        for (i = 0; i < 50; i++) begin : rand_loop
            logic [8:0] ra, rb;
            ra = $urandom_range(0, 511);
            rb = $urandom_range(0, 511);
            check_add(ra, rb);
            check_sub(ra, rb);
        end

        $display("");
        $display("=================================================");
        $display("  ADDER RESULTS: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("=================================================");
        $display("");

        $finish;
    end
endmodule
