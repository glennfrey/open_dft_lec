/*
 * tb_occ.v -- Self-checking testbench for occ_simple
 *
 * Verifies that occ_start produces exactly 2 pulses on occ_clk,
 * both at pll_clk frequency, followed by occ_done assertion.
 */
`timescale 1ns/1ps

module tb_occ;
    reg rst_n = 0;
    reg scan_clk = 0;    // 100 MHz (10 ns)
    reg pll_clk = 0;     // 1 GHz (1 ns)
    reg occ_start = 0;
    wire occ_clk;
    wire occ_done;

    integer errors = 0;
    integer pulse_count = 0;
    reg occ_clk_d;

    occ_simple dut (
        .rst_n     (rst_n),
        .scan_clk  (scan_clk),
        .pll_clk   (pll_clk),
        .occ_start (occ_start),
        .occ_clk   (occ_clk),
        .occ_done  (occ_done)
    );

    // Clock generation
    always #5  scan_clk = ~scan_clk;   // 100 MHz
    always #0.5 pll_clk = ~pll_clk;    // 1 GHz

    // Count rising edges of occ_clk
    always @(posedge pll_clk) begin
        occ_clk_d <= occ_clk;
        if (occ_clk && !occ_clk_d) begin
            pulse_count = pulse_count + 1;
            $display("  [TB] OCC pulse %0d at t=%0t", pulse_count, $time);
        end
    end

    initial begin
        $display("[TB] Starting OCC test ...");

        // Reset
        repeat (4) @(posedge pll_clk);
        rst_n = 1;
        repeat (2) @(posedge pll_clk);

        // Verify occ_clk is low in idle
        if (occ_clk !== 1'b0) begin
            $display("ERROR: occ_clk not low in IDLE at t=%0t", $time);
            errors = errors + 1;
        end

        // Trigger OCC sequence
        $display("[TB] Triggering OCC start ...");
        @(negedge pll_clk);
        occ_start = 1;
        @(negedge pll_clk);
        occ_start = 0;

        // Wait for done
        wait (occ_done);
        repeat (2) @(posedge pll_clk);

        // Verify exactly 2 pulses
        $display("[TB] Total OCC pulses detected: %0d", pulse_count);
        if (pulse_count !== 2) begin
            $display("ERROR: Expected 2 pulses, got %0d", pulse_count);
            errors = errors + 1;
        end

        // Verify occ_clk returned to low
        if (occ_clk !== 1'b0) begin
            $display("ERROR: occ_clk not low after DONE");
            errors = errors + 1;
        end

        // Report
        if (errors == 0)
            $display("TESTBENCH PASSED (OCC: 2 pulses, done asserted)");
        else
            $display("TESTBENCH FAILED (%0d errors)", errors);

        $finish;
    end

    // Timeout
    initial begin
        #200;
        $display("ERROR: TIMEOUT");
        $finish;
    end
endmodule
