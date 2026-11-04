`timescale 1ns/1ps
module tb_lec_debug;
    reg clk=0, reset_n=0;
    reg [7:0] data;
    reg send;
    wire tx_gold, busy_gold, done_gold;
    wire tx_gate, busy_gate, done_gate;

    uart_tx gold (.clk(clk), .reset_n(reset_n), .data(data), .send(send),
                  .tx(tx_gold), .busy(busy_gold), .done(done_gold));
    uart_tx_gate gate (.clk(clk), .reset_n(reset_n), .data(data), .send(send),
                       .tx(tx_gate), .busy(busy_gate), .done(done_gate));

    always #5 clk=~clk;

    initial begin
        $dumpfile("lec_debug.vcd");
        $dumpvars(0, tb_lec_debug);

        data = 8'h00; send = 0;
        repeat(2) @(posedge clk);
        reset_n = 1;

        // Check reset values
        @(posedge clk); #1;
        $display("After reset release:");
        $display("  Gold: tx=%b busy=%b done=%b", tx_gold, busy_gold, done_gold);
        $display("  Gate: tx=%b busy=%b done=%b", tx_gate, busy_gate, done_gate);

        // Apply one stimulus and check
        data = 8'hA5; send = 1;
        @(posedge clk); #1;
        $display("After send=1:");
        $display("  Gold: tx=%b busy=%b done=%b", tx_gold, busy_gold, done_gold);
        $display("  Gate: tx=%b busy=%b done=%b", tx_gate, busy_gate, done_gate);

        send = 0;
        repeat(20) @(posedge clk);
        $display("Test complete");
        $finish;
    end
endmodule
