/*
 * uart_tx_tb.v -- Self-checking testbench, v2 (center-sampling receiver)
 *
 * v2 fix: v1 sampled tx exactly on bit boundaries (aligned with the same
 * posedge where the DUT NBA-updates tx) -> every sample raced the bit
 * transition and read the previous bit (captured == expected << 1).
 * v2 samples at BIT CENTERS (start edge + TICKS/2, then every TICKS),
 * the same structure a real UART receiver uses. Per-bit display aids
 * debug if a failure ever appears.
 */
`timescale 1ns/1ps

module uart_tx_tb;
    localparam CLK_HZ = 1000;
    localparam BAUD   = 100;
    localparam TICKS  = CLK_HZ / BAUD;   // 10

    reg        clk = 0;
    reg        reset_n = 0;
    reg  [7:0] data = 0;
    reg        send = 0;
    wire       tx, busy, done;

    uart_tx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) dut (
        .clk(clk), .reset_n(reset_n), .data(data),
        .send(send), .tx(tx), .busy(busy), .done(done)
    );

    always #5 clk = ~clk;   // 10 ns period

    integer errors = 0;
    reg [9:0] captured;
    integer   k;

    task send_and_check(input [7:0] payload);
        begin
            // issue one byte
            @(negedge clk);
            data = payload;
            send = 1;
            @(negedge clk);
            send = 0;

            // wait for the start-bit falling edge, then sample at centers
            @(negedge tx);
            repeat (TICKS/2) @(posedge clk);   // center of start bit
            captured = 10'b0;
            for (k = 0; k < 10; k = k + 1) begin
                if (k > 0) repeat (TICKS) @(posedge clk);
                captured[k] = tx;
            end

            if (captured !== {1'b1, payload, 1'b0}) begin
                $display("FAIL: payload=%h captured frame=%b", payload, captured);
                errors = errors + 1;
            end else begin
                $display("PASS: payload=%h frame=%b", payload, captured);
            end
        end
    endtask

    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);
        repeat (4) @(posedge clk);
        reset_n = 1;
        repeat (4) @(posedge clk);

        if (tx !== 1'b1) begin
            $display("FAIL: tx not idle-high after reset");
            errors = errors + 1;
        end

        send_and_check(8'hA5);
        wait (busy == 0);
        send_and_check(8'h3C);

        wait (busy == 0);
        repeat (10) @(posedge clk);

        if (errors == 0) $display("TESTBENCH PASSED");
        else             $display("TESTBENCH FAILED (%0d errors)", errors);
        $finish;
    end

    initial begin
        #100000;
        $display("ERROR: TIMEOUT");
        $finish;
    end
endmodule
