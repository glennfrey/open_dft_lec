/*
 * tb_mbist.v -- Self-checking testbench for mbist_simple + sram_8x16
 *
 * Test 1: Good memory -> MBIST should PASS
 * Test 2: Inject stuck-at-1 fault at bit 0 of address 3 -> MBIST should FAIL
 */
`timescale 1ns/1ps

module tb_mbist;
    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;
    wire done;
    wire fail;

    wire [2:0]  mut_addr;
    wire        mut_wen;
    wire [15:0] mut_wdata;
    wire [15:0] mut_rdata;

    integer errors = 0;
    reg inject_fault;   // set to 1 to force bit 0 of addr 3 to 1
    reg fail_latch;     // local reg for task output

    // Clock
    always #5 clk = ~clk;   // 100 MHz

    // Memory Under Test (with built-in fault injection for demo)
    sram_8x16 mut (
        .clk          (clk),
        .wen          (mut_wen),
        .addr         (mut_addr),
        .wdata        (mut_wdata),
        .rdata        (mut_rdata),
        .fault_inject (inject_fault)
    );

    // MBIST Controller
    mbist_simple bist (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .done      (done),
        .fail      (fail),
        .mut_addr  (mut_addr),
        .mut_wen   (mut_wen),
        .mut_wdata (mut_wdata),
        .mut_rdata (mut_rdata)
    );

    task run_mbist;
        input fault_mode;
        output fail_result;
        begin
            inject_fault = fault_mode;
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;
            wait (done);
            fail_result = fail;  // latch fail immediately when done goes high
            repeat (2) @(posedge clk);
        end
    endtask

    initial begin
        $display("[TB] Starting MBIST tests ...");

        // Reset
        repeat (4) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        // --- Test 1: Good memory ---
        $display("[TB] Test 1: Good memory (no fault injection)");
        run_mbist(0, fail_latch);
        if (fail_latch) begin
            $display("ERROR: Good memory reported FAIL");
            errors = errors + 1;
        end else begin
            $display("  PASS: Good memory correctly reported PASS");
        end

        // Reset for next test
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        // --- Test 2: Inject stuck-at-1 fault (inverts all bits) ---
        $display("[TB] Test 2: Inverted data fault (all bits flipped)");
        run_mbist(1, fail_latch);
        if (!fail_latch) begin
            $display("ERROR: Faulty memory reported PASS (should FAIL)");
            errors = errors + 1;
        end else begin
            $display("  PASS: Faulty memory correctly detected and reported FAIL");
        end

        // Report
        if (errors == 0)
            $display("TESTBENCH PASSED (MBIST detects both good and faulty memory)");
        else
            $display("TESTBENCH FAILED (%0d errors)", errors);

        $finish;
    end

    // Timeout
    initial begin
        #5000;
        $display("ERROR: TIMEOUT");
        $finish;
    end
endmodule
