`timescale 1ns/1ps
//
// Unit-level testbench for ControlUnitFSM in isolation from the rest of the
// datapath. Drives IRout / G_nonzero / G_lessthanzero directly and walks the
// FSM through fixed numbers of clock edges (state sequence is deterministic:
// IDLE -> SELECTING -> FETCH -> FETCH_WAIT -> DECODE -> <opcode state> ...),
// then checks the combinational control outputs at each state.
//
// To run: set this module as the simulation top (Vivado Simulation Settings,
// or a separate simulation fileset/set) instead of tb.sv.
//
module fsm_tb;
    logic clk = 0, resetn = 0, run = 0;
    logic [8:0] IRout = 9'b0;
    logic G_nonzero = 0, G_lessthanzero = 0;

    logic IRin, Gout, DINout, Ain, AddSub, Gin, Done, ADDRin, DOUTin, W_D, incr_pc;
    logic [7:0] R_out, R_in;

    ControlUnitFSM dut (
        .run(run),
        .resetn(resetn),
        .clk(clk),
        .IRout(IRout),
        .G_nonzero(G_nonzero),
        .G_lessthanzero(G_lessthanzero),
        .IRin(IRin),
        .R_out(R_out),
        .Gout(Gout),
        .DINout(DINout),
        .R_in(R_in),
        .Ain(Ain),
        .AddSub(AddSub),
        .Gin(Gin),
        .Done(Done),
        .ADDRin(ADDRin),
        .DOUTin(DOUTin),
        .W_D(W_D),
        .incr_pc(incr_pc)
    );
    always #5 clk = ~clk;

    localparam logic [2:0] R0 = 3'd0, R1 = 3'd1, R2 = 3'd2, R3 = 3'd3,
                            R4 = 3'd4, R5 = 3'd5, R6 = 3'd6;
    localparam logic [2:0] OP_MV=3'b000, OP_MVI=3'b001, OP_ADD=3'b010, OP_SUB=3'b011,
                            OP_LOAD=3'b100, OP_STORE=3'b101, OP_BRNE=3'b110, OP_BRLT=3'b111;

    int pass_count = 0;
    int fail_count = 0;

    task automatic check(input bit cond, input string name);
        if (cond) begin
            $display("  [PASS] %s", name);
            pass_count++;
        end else begin
            $display("  [FAIL] %s", name);
            fail_count++;
        end
    endtask

    task automatic do_reset;
        resetn = 0;
        run    = 0;
        repeat (2) @(posedge clk);
        resetn = 1;
        @(posedge clk);
    endtask

    // Reset, preload IRout with {opcode,rx,ry}, then walk exactly the 5
    // fixed edges every instruction takes to go IDLE -> ... -> DECODE ->
    // <opcode's first execute state>.
    task automatic goto_decode(input logic [2:0] opcode, input logic [2:0] rx, input logic [2:0] ry);
        do_reset();
        IRout = {opcode, rx, ry};
        run = 1;
        repeat (5) @(posedge clk);
    endtask

    task automatic goto_bb1(input logic [2:0] opcode);
        goto_decode(opcode, 3'b000, 3'b000);
        @(posedge clk); // BRNE/BRLT state -> BB1
    endtask

    task automatic check_branch(input logic [2:0] opcode, input logic gnz, input logic glz,
                                 input logic expect_taken, input string name);
        goto_bb1(opcode);
        G_nonzero = gnz;
        G_lessthanzero = glz;
        #1;
        @(posedge clk); // BB1 -> FETCH (not taken) or BB2 (taken)
        if (expect_taken)
            check(dut.current_state === dut.BB2, name);
        else
            check(dut.current_state === dut.FETCH, name);
    endtask

    initial begin
        $display("\n[FSM] Reset behavior");
        do_reset();
        check(dut.current_state === dut.IDLE, "after reset, state == IDLE");

        $display("\n[FSM] run==0 forces IDLE from any state");
        goto_decode(OP_MV, R1, R2);
        run = 0;
        @(posedge clk);
        check(dut.current_state === dut.IDLE, "run deasserted mid-instruction forces IDLE");

        $display("\n[FSM] async reset forces IDLE from any state");
        goto_decode(OP_ADD, R1, R2); // lands in ADD state
        resetn = 0;
        #1;
        check(dut.current_state === dut.IDLE, "resetn deasserted mid-instruction forces IDLE (async)");
        resetn = 1;

        //=================================================================
        $display("\n[FSM] MV Rx,Ry");
        goto_decode(OP_MV, R2, R5);
        check(dut.current_state === dut.MV, "DECODE(MV) -> MV state");
        check(R_in  === (8'b1 << R2), "MV: R_in selects Rx");
        check(R_out === (8'b1 << R5), "MV: R_out selects Ry");
        check(Done  === 1'b1, "MV: Done asserted (single-cycle op)");
        @(posedge clk);
        check(dut.current_state === dut.FETCH, "MV -> FETCH");

        //=================================================================
        $display("\n[FSM] MVI Rx,#imm");
        goto_decode(OP_MVI, R3, 3'b000);
        check(dut.current_state === dut.MVI, "DECODE(MVI) -> MVI state");
        check(R_out  === 8'b10000000, "MVI: R_out selects R7 (PC) to fetch operand address");
        check(ADDRin === 1'b1, "MVI: ADDRin latches operand address");
        check(incr_pc === 1'b1, "MVI: incr_pc advances PC past the operand word");
        @(posedge clk);
        check(dut.current_state === dut.MVI_T2, "MVI -> MVI_T2");
        check(DINout === 1'b1, "MVI_T2: DINout reads the operand word");
        check(R_in   === (8'b1 << R3), "MVI_T2: R_in selects Rx");
        check(Done   === 1'b1, "MVI_T2: Done asserted");
        @(posedge clk);
        check(dut.current_state === dut.FETCH, "MVI_T2 -> FETCH");

        //=================================================================
        $display("\n[FSM] ADD Rx,Ry");
        goto_decode(OP_ADD, R1, R4);
        check(dut.current_state === dut.ADD, "DECODE(ADD) -> ADD state");
        check(R_out === (8'b1 << R1), "ADD: R_out selects Rx onto bus");
        check(Ain   === 1'b1, "ADD: Ain latches operand A");
        @(posedge clk);
        check(dut.current_state === dut.ADD_T2, "ADD -> ADD_T2");
        check(R_out  === (8'b1 << R4), "ADD_T2: R_out selects Ry onto bus");
        check(AddSub === 1'b0, "ADD_T2: AddSub==0 selects addition");
        check(Gin    === 1'b1, "ADD_T2: Gin latches the sum");
        @(posedge clk);
        check(dut.current_state === dut.ADD_T3, "ADD_T2 -> ADD_T3");
        check(Gout === 1'b1, "ADD_T3: Gout drives the sum onto bus");
        check(R_in  === (8'b1 << R1), "ADD_T3: R_in writes back to Rx");
        check(Done  === 1'b1, "ADD_T3: Done asserted");
        @(posedge clk);
        check(dut.current_state === dut.FETCH, "ADD_T3 -> FETCH");

        //=================================================================
        $display("\n[FSM] SUB Rx,Ry");
        goto_decode(OP_SUB, R2, R0);
        check(dut.current_state === dut.SUB, "DECODE(SUB) -> SUB state");
        @(posedge clk);
        check(dut.current_state === dut.SUB_S2, "SUB -> SUB_S2");
        check(AddSub === 1'b1, "SUB_S2: AddSub==1 selects subtraction (two's complement)");
        @(posedge clk);
        check(dut.current_state === dut.SUB_S3, "SUB_S2 -> SUB_S3");
        check(Done === 1'b1, "SUB_S3: Done asserted");
        @(posedge clk);
        check(dut.current_state === dut.FETCH, "SUB_S3 -> FETCH");

        //=================================================================
        $display("\n[FSM] LOAD Rx,[Ry]");
        goto_decode(OP_LOAD, R6, R0);
        check(dut.current_state === dut.LOAD, "DECODE(LOAD) -> LOAD state");
        check(R_out  === (8'b1 << R0), "LOAD: R_out selects Ry (address) onto bus");
        check(ADDRin === 1'b1, "LOAD: ADDRin latches the address");
        @(posedge clk);
        check(dut.current_state === dut.LOAD_L2, "LOAD -> LOAD_L2");
        check(R_in   === (8'b1 << R6), "LOAD_L2: R_in selects Rx");
        check(DINout === 1'b1, "LOAD_L2: DINout reads memory data onto bus");
        check(Done   === 1'b1, "LOAD_L2: Done asserted");
        @(posedge clk);
        check(dut.current_state === dut.FETCH, "LOAD_L2 -> FETCH");

        //=================================================================
        $display("\n[FSM] STORE Rx,[Ry]");
        goto_decode(OP_STORE, R2, R6);
        check(dut.current_state === dut.STORE, "DECODE(STORE) -> STORE state");
        check(R_out  === (8'b1 << R6), "STORE: R_out selects Ry (address) onto bus");
        check(ADDRin === 1'b1, "STORE: ADDRin latches the address");
        @(posedge clk);
        check(dut.current_state === dut.STORE_S2, "STORE -> STORE_S2");
        check(R_out  === (8'b1 << R2), "STORE_S2: R_out selects Rx (data) onto bus");
        check(DOUTin === 1'b1, "STORE_S2: DOUTin latches the data");
        check(W_D    === 1'b1, "STORE_S2: W_D issues the memory write");
        check(Done   === 1'b1, "STORE_S2: Done asserted");
        @(posedge clk);
        check(dut.current_state === dut.FETCH, "STORE_S2 -> FETCH");

        //=================================================================
        $display("\n[FSM] BRNE / BRLT branch-flag decoding at BB1");
        check_branch(OP_BRNE, 1'b0, 1'b0, 1'b0, "BRNE not taken when G==0");
        check_branch(OP_BRNE, 1'b1, 1'b0, 1'b1, "BRNE taken when G!=0 (positive)");
        check_branch(OP_BRNE, 1'b1, 1'b1, 1'b1, "BRNE taken when G!=0 (negative)");

        check_branch(OP_BRLT, 1'b0, 1'b0, 1'b0, "BRLT not taken when G==0");
        check_branch(OP_BRLT, 1'b1, 1'b1, 1'b1, "BRLT taken when G<0");
        // KNOWN ISSUE: BB1's condition is `bbcase == 2'b00 -> not taken, else taken`,
        // i.e. "branch iff G_nonzero || G_lessthanzero". Since G_lessthanzero implies
        // G_nonzero, that reduces to "branch iff G_nonzero" for BOTH BRNE and BRLT -
        // BB1 never looks at which opcode (BRNE vs BRLT) it was entered from. So a
        // BRLT on a POSITIVE nonzero result (G_nonzero=1, G_lessthanzero=0) is
        // expected architecturally to NOT branch, but the current RTL branches
        // anyway. This check is expected to FAIL until ControlUnitFSM.sv's BB1
        // state is fixed to key off the originating opcode (or a latched flag).
        check_branch(OP_BRLT, 1'b1, 1'b0, 1'b0,
            "BRLT not taken when G>0 (KNOWN ISSUE: see comment above)");

        $display("");
        $display("=================================================");
        $display("  FSM RESULTS: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("=================================================");
        $display("");

        $finish;
    end

    initial begin
        #1_000_000;
        $display("[ERROR] GLOBAL TIMEOUT");
        $finish;
    end
endmodule
