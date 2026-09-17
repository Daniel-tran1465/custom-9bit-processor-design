`timescale 1ns/1ps
module tb;
    logic clk = 0, resetn = 0, run = 0;
    logic [8:0] Button = 0;
    logic Done;
    logic [8:0] LEDs;
    logic [7:0] anode_out, ssd_cathode_out;

    simple_processor dut (
    .Clock(clk),
    .Resetn(resetn),
    .Run(run),
    .Button(Button),
    .Done(Done),
    .LEDs(LEDs),
    .anode_out(anode_out),
    .ssd_cathode_out(ssd_cathode_out)
    );
    always #5 clk = ~clk;

    defparam dut.Divider.PROC_DIV = 4;    // chia 4 -> FSM chay gan nhu full speed
    defparam dut.Divider.SCAN_DIV = 4;    // scan 7-seg cung chia 4

    /////////////////////////////////////////////////////////////////////////
    // Opcode / addressing constants (must match ControlUnitFSM decode table
    // and simple_processor device-select logic on Q_inst[8:7])
    /////////////////////////////////////////////////////////////////////////
    localparam logic [2:0] OP_MV    = 3'b000;
    localparam logic [2:0] OP_MVI   = 3'b001;
    localparam logic [2:0] OP_ADD   = 3'b010;
    localparam logic [2:0] OP_SUB   = 3'b011;
    localparam logic [2:0] OP_LOAD  = 3'b100;
    localparam logic [2:0] OP_STORE = 3'b101;
    localparam logic [2:0] OP_BRNE  = 3'b110;
    localparam logic [2:0] OP_BRLT  = 3'b111;

    localparam logic [2:0] R0 = 3'd0, R1 = 3'd1, R2 = 3'd2, R3 = 3'd3,
                            R4 = 3'd4, R5 = 3'd5, R6 = 3'd6;

    // Q_inst[8:7]==2'b10 -> SEG register, ==2'b01 -> LED register, ==2'b00 -> RAM
    localparam logic [8:0] ADDR_SEG = 9'b1_0000_0000;
    localparam logic [8:0] ADDR_LED = 9'b0_1000_0000;

    /////////////////////////////////////////////////////////////////////////
    // ROM helpers - a tiny "assembler" so test programs read like assembly
    // instead of hand-packed binary literals.
    /////////////////////////////////////////////////////////////////////////
    task automatic clear_rom;
        integer i;
        for (i = 0; i < 128; i++)
            dut.Memory.U0.rom[i] = 9'b0;
    endtask

    task automatic rom_write(input int addr, input logic [8:0] data);
        dut.Memory.U0.rom[addr] = data;
    endtask

    // register-register form: opcode Rx, Ry  (MV/ADD/SUB/LOAD/STORE)
    task automatic emit_r(ref int addr, input logic [2:0] op, input logic [2:0] rx, input logic [2:0] ry);
        rom_write(addr, {op, rx, ry});
        addr = addr + 1;
    endtask

    // immediate form: opcode Rx, #imm  (MVI) / opcode, target (BRNE/BRLT)
    task automatic emit_i(ref int addr, input logic [2:0] op, input logic [2:0] rx, input logic [8:0] imm);
        rom_write(addr, {op, rx, 3'b000});
        rom_write(addr + 1, imm);
        addr = addr + 2;
    endtask

    task automatic do_reset;
        resetn = 0;
        run    = 0;
        repeat (5) @(posedge clk);
        resetn = 1;
        @(posedge clk);
    endtask

    task automatic run_for(input int cycles);
        run = 1;
        repeat (cycles) @(posedge clk);
        run = 0;
        repeat (5) @(posedge clk);
    endtask

    /////////////////////////////////////////////////////////////////////////
    int pass_count = 0;
    int fail_count = 0;
    /////////////////////////////////////////////////////////////////////////
    task automatic check_segs(input logic [8:0] expected, input string name);
        if (dut.Segs === expected) begin
            $display("  [PASS] %-32s exp=0x%03X got=0x%03X", name, expected, dut.Segs);
            pass_count++;
        end else begin
            $display("  [FAIL] %-32s exp=0x%03X got=0x%03X", name, expected, dut.Segs);
            fail_count++;
        end
    endtask

    task automatic check_leds(input logic [8:0] expected, input string name);
        if (LEDs === expected) begin
            $display("  [PASS] %-32s exp=0x%03X got=0x%03X", name, expected, LEDs);
            pass_count++;
        end else begin
            $display("  [FAIL] %-32s exp=0x%03X got=0x%03X", name, expected, LEDs);
            fail_count++;
        end
    endtask

    task automatic check_idle(input string name);
        if (dut.Processor.CUF_inst.current_state === dut.Processor.CUF_inst.IDLE) begin
            $display("  [PASS] %-32s state=IDLE", name);
            pass_count++;
        end else begin
            $display("  [FAIL] %-32s state=%0d (expected IDLE)", name, dut.Processor.CUF_inst.current_state);
            fail_count++;
        end
    endtask

    /////////////////////////////////////////////////////////////////////////
    initial begin
        int addr;
        int target_addr;
        int patch_addr;

        #200; // waiting for force applying

        //=================================================================
        $display("\n[TEST 1] MVI R1,#5 -> STORE to 7-seg");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd5);
        emit_i(addr, OP_MVI,   R2, ADDR_SEG);
        emit_r(addr, OP_STORE, R1, R2);
        do_reset();
        run_for(500);
        check_segs(9'd5, "MVI+STORE=5 (SEG)");

        //=================================================================
        $display("\n[TEST 2] MV: MVI R1,#7 ; MV R2,R1 -> STORE R2 to LED");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd7);
        emit_r(addr, OP_MV,    R2, R1);
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R2, R5);
        do_reset();
        run_for(500);
        check_leds(9'd7, "MV R2,R1 == 7");

        //=================================================================
        $display("\n[TEST 3] ADD: R1=3, R2=4, R1=R1+R2 -> STORE to LED");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd3);
        emit_i(addr, OP_MVI,   R2, 9'd4);
        emit_r(addr, OP_ADD,   R1, R2);
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R1, R5);
        do_reset();
        run_for(600);
        check_leds(9'(3 + 4), "ADD R1,R2 == 7");

        //=================================================================
        $display("\n[TEST 4] SUB (positive result): R1=10, R2=3, R1=R1-R2 -> STORE to LED");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd10);
        emit_i(addr, OP_MVI,   R2, 9'd3);
        emit_r(addr, OP_SUB,   R1, R2);
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R1, R5);
        do_reset();
        run_for(600);
        check_leds(9'(10 - 3), "SUB R1,R2 == 7");

        //=================================================================
        $display("\n[TEST 5] SUB (negative result, two's complement wraps): R1=3, R2=10 -> STORE to LED");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd3);
        emit_i(addr, OP_MVI,   R2, 9'd10);
        emit_r(addr, OP_SUB,   R1, R2);
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R1, R5);
        do_reset();
        run_for(600);
        check_leds(9'(3 - 10), "SUB R1,R2 == -7 (9-bit wraparound)");

        //=================================================================
        $display("\n[TEST 6] LOAD/STORE RAM round-trip: MEM[0]=42, LOAD back, STORE to LED");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd42);
        emit_i(addr, OP_MVI,   R2, 9'd0);      // RAM address 0 (Q_inst[8:7]==00)
        emit_r(addr, OP_STORE, R1, R2);        // MEM[0] = 42
        emit_i(addr, OP_MVI,   R3, 9'd0);      // reuse RAM address 0
        emit_r(addr, OP_LOAD,  R4, R3);        // R4 = MEM[0]
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R4, R5);
        do_reset();
        run_for(800);
        check_leds(9'd42, "LOAD R4,[R3] round-trip == 42");

        //=================================================================
        $display("\n[TEST 7] BRNE not taken (R1-R2==0): fallthrough path executes");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd5);
        emit_i(addr, OP_MVI,   R2, 9'd5);
        emit_r(addr, OP_SUB,   R1, R2);        // result 0 -> G_nonzero==0
        emit_i(addr, OP_BRNE,  R0, 9'd0);      // target unused, branch not taken
        emit_i(addr, OP_MVI,   R4, 9'd42);     // fallthrough marker
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R4, R5);
        do_reset();
        run_for(700);
        check_leds(9'd42, "BRNE not-taken fallthrough == 42");

        //=================================================================
        $display("\n[TEST 8] BRNE taken (R1-R2!=0): jumps over fallthrough path");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd5);
        emit_i(addr, OP_MVI,   R2, 9'd3);
        emit_r(addr, OP_SUB,   R1, R2);        // result 2 -> G_nonzero==1
        patch_addr = addr + 1;                 // address of BRNE's immediate operand word
        emit_i(addr, OP_BRNE,  R0, 9'd0);      // placeholder target, patched below
        emit_i(addr, OP_MVI,   R4, 9'd42);     // must be SKIPPED
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R4, R5);        // must be SKIPPED
        target_addr = addr;                    // branch target lands here
        rom_write(patch_addr, target_addr[8:0]);
        emit_i(addr, OP_MVI,   R6, 9'd55);     // taken-path marker
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R6, R5);
        do_reset();
        run_for(700);
        check_leds(9'd55, "BRNE taken lands on target == 55");

        //=================================================================
        $display("\n[TEST 9] BRLT not taken (R1-R2>=0): fallthrough path executes");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd5);
        emit_i(addr, OP_MVI,   R2, 9'd3);
        emit_r(addr, OP_SUB,   R1, R2);        // result 2 -> G_lessthanzero==0
        emit_i(addr, OP_BRLT,  R0, 9'd0);
        emit_i(addr, OP_MVI,   R4, 9'd42);     // fallthrough marker
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R4, R5);
        do_reset();
        run_for(700);
        check_leds(9'd42, "BRLT not-taken fallthrough == 42");

        //=================================================================
        $display("\n[TEST 10] BRLT taken (R1-R2<0): jumps over fallthrough path");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd3);
        emit_i(addr, OP_MVI,   R2, 9'd10);
        emit_r(addr, OP_SUB,   R1, R2);        // result -7 -> G_lessthanzero==1
        patch_addr = addr + 1;
        emit_i(addr, OP_BRLT,  R0, 9'd0);      // placeholder target, patched below
        emit_i(addr, OP_MVI,   R4, 9'd42);     // must be SKIPPED
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R4, R5);        // must be SKIPPED
        target_addr = addr;
        rom_write(patch_addr, target_addr[8:0]);
        emit_i(addr, OP_MVI,   R6, 9'd55);     // taken-path marker
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R6, R5);
        do_reset();
        run_for(700);
        check_leds(9'd55, "BRLT taken lands on target == 55");

        //=================================================================
        $display("\n[TEST 11] Countdown loop: R1=3 ; while(R1 -= 1) loop ; STORE R1 to LED (expect 0)");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd3);
        emit_i(addr, OP_MVI,   R2, 9'd1);
        emit_i(addr, OP_MVI,   R3, ADDR_LED);
        target_addr = addr;                    // loop:
        emit_r(addr, OP_SUB,   R1, R2);        //   R1 = R1 - 1
        emit_i(addr, OP_BRNE,  R0, target_addr[8:0]); // loop while R1 != 0
        emit_r(addr, OP_STORE, R1, R3);        // R1 == 0 here
        do_reset();
        run_for(1200);
        check_leds(9'd0, "countdown loop finished with R1 == 0");

        //=================================================================
        $display("\n[TEST 12] Reset asserted mid-execution recovers cleanly on next run");
        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd99);
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R1, R5);
        do_reset();
        run = 1;
        repeat (20) @(posedge clk);  // interrupt partway through the program
        resetn = 0;                  // assert reset mid-flight
        repeat (5) @(posedge clk);
        check_idle("FSM forced back to IDLE during mid-run reset");
        resetn = 1;
        run    = 0;
        repeat (5) @(posedge clk);

        clear_rom();
        addr = 0;
        emit_i(addr, OP_MVI,   R1, 9'd7);
        emit_i(addr, OP_MVI,   R5, ADDR_LED);
        emit_r(addr, OP_STORE, R1, R5);
        do_reset();
        run_for(500);
        check_leds(9'd7, "clean run after mid-run reset recovers correctly");

        //=================================================================
        $display("");
        $display("=================================================");
        $display("  RESULTS: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("=================================================");
        $display("");

        if (fail_count > 0)
            $fatal(1, "%0d test(s) failed", fail_count);

        $finish;
    end

    initial begin
        #50_000_000;   // 50 ms
        $display("[ERROR] GLOBAL TIMEOUT");
        $finish;
    end

    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile("tb.vcd");
            $dumpvars(0, tb);
        end
    end

endmodule
