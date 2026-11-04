`timescale 1ns/1ps
module tb_lec_fixed;
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
    integer i;

    // Test vectors (deterministic)
    reg [8:0] testvec [0:15];
    initial begin
        testvec[0]  = {1'b0, 8'h00};  // send=0, data=00
        testvec[1]  = {1'b1, 8'hA5};  // send=1, data=A5
        testvec[2]  = {1'b0, 8'h00};  // send=0
        testvec[3]  = {1'b0, 8'h00};  // idle
        testvec[4]  = {1'b1, 8'h3C};  // send=1, data=3C
        testvec[5]  = {1'b0, 8'h00};  // send=0
        testvec[6]  = {1'b0, 8'h00};  // idle...
        testvec[7]  = {1'b0, 8'h00};
        testvec[8]  = {1'b0, 8'h00};
        testvec[9]  = {1'b0, 8'h00};
        testvec[10] = {1'b0, 8'h00};
        testvec[11] = {1'b0, 8'h00};
        testvec[12] = {1'b0, 8'h00};
        testvec[13] = {1'b0, 8'h00};
        testvec[14] = {1'b0, 8'h00};
        testvec[15] = {1'b0, 8'h00};
    end

    initial begin
        repeat(2) @(posedge clk);
        reset_n=1; repeat(2) @(posedge clk);

        // Run deterministic vectors
        for(i=0; i<16; i=i+1) begin
            {send, data} = testvec[i];
            @(posedge clk); #1;
            if(tx_gold!==tx_gate || busy_gold!==busy_gate || done_gold!==done_gate) begin
                $display("MISMATCH at vec %0d: send=%b data=%h", i, send, data);
                $display("  Gold: tx=%b busy=%b done=%b", tx_gold, busy_gold, done_gold);
                $display("  Gate: tx=%b busy=%b done=%b", tx_gate, busy_gate, done_gate);
                $display("LEC FAILED"); $finish(1);
            end
        end

        // Then random
        for(i=0; i<10000; i=i+1) begin
            data = $urandom_range(0, 255);
            send = $urandom_range(0, 1);
            @(posedge clk); #1;
            if(tx_gold!==tx_gate || busy_gold!==busy_gate || done_gold!==done_gate) begin
                $display("MISMATCH at rand cycle %0d", i);
                $display("  Gold: tx=%b busy=%b done=%b", tx_gold, busy_gold, done_gold);
                $display("  Gate: tx=%b busy=%b done=%b", tx_gate, busy_gate, done_gate);
                $display("LEC FAILED"); $finish(1);
            end
        end

        $display("LEC PASSED: all cycles verified"); $finish(0);
    end
endmodule
