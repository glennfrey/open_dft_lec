/*
 * tb_equiv.v -- simulation-based sequential equivalence check
 *
 * Instantiates the RTL (uart_tx) and the synthesized gate netlist
 * (uart_tx_gate, renamed by the Makefile) side by side, resets both,
 * drives 5000 cycles of randomized stimulus (data, send bursts, periodic
 * reset pulses), and compares tx/busy/done every cycle after NBA settle.
 *
 * This is lockstep co-simulation equivalence -- the honest open-source
 * complement to formal LEC when the SMT backend is unavailable.
 */
`timescale 1ns/1ps

module tb_equiv;
    reg        clk = 0, reset_n = 0, send = 0;
    reg  [7:0] data = 0;
    wire tx_gold, busy_gold, done_gold;
    wire tx_gate, busy_gate, done_gate;

    integer errors = 0, cycles = 0;
    integer seed = 7;

    uart_tx dut_gold (
        .clk(clk), .reset_n(reset_n), .data(data), .send(send),
        .tx(tx_gold), .busy(busy_gold), .done(done_gold)
    );

    uart_tx_gate dut_gate (
        .clk(clk), .reset_n(reset_n), .data(data), .send(send),
        .tx(tx_gate), .busy(busy_gate), .done(done_gate)
    );

    always #5 clk = ~clk;

    // stimulus: random data/send, periodic reset pulses
    initial begin
        repeat (4) @(posedge clk);
        reset_n = 1;
        repeat (4) @(posedge clk);
        while (cycles < 5000) begin
            @(negedge clk);
            send = (($random(seed) & 7) == 0);
            data = $random(seed);
            if ((cycles % 997) == 500) begin
                reset_n = 0;
                @(negedge clk);
                @(negedge clk);
                reset_n = 1;
            end
            cycles = cycles + 1;
        end
        repeat (2) @(posedge clk);
        if (errors == 0)
            $display("TESTBENCH PASSED (5000 cycles lockstep, RTL vs gate netlist)");
        else
            $display("TESTBENCH FAILED (%0d mismatches)", errors);
        $finish;
    end

    // compare outputs each cycle after NBA settle
    always @(posedge clk) begin
        if (reset_n) begin
            #1;
            if (tx_gold !== tx_gate || busy_gold !== busy_gate || done_gold !== done_gate) begin
                $display("ERROR t=%0t gold(tx=%b busy=%b done=%b) gate(tx=%b busy=%b done=%b)",
                         $time, tx_gold, busy_gold, done_gold,
                                tx_gate, busy_gate, done_gate);
                errors = errors + 1;
            end
        end
    end

    initial begin
        #3000000;
        $display("ERROR: TIMEOUT");
        $finish;
    end
endmodule
