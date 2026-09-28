/*
 * uart_tx_buggy.v -- DELIBERATE BUG for the LEC demo.
 * Bit ordering error: frame shifted left instead of right, so the start
 * bit is not emitted first. `make lec-bug` should FAIL equivalence.
 */
module uart_tx #(
    parameter CLK_HZ = 50_000_000,
    parameter BAUD   = 115200
)(
    input  wire       clk,
    input  wire       reset_n,
    input  wire [7:0] data,
    input  wire       send,
    output reg        tx,
    output reg        busy,
    output reg        done
);
    localparam TICKS = CLK_HZ / BAUD;
    localparam IDLE = 2'd0, SEND = 2'd1;

    reg [1:0]               state;
    reg [9:0]               frame;
    reg [$clog2(TICKS)-1:0] cnt;
    reg [3:0]               bit_idx;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE; tx <= 1'b1; busy <= 1'b0; done <= 1'b0;
            frame <= 10'h3FF; cnt <= 0; bit_idx <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    tx <= 1'b1; busy <= 1'b0;
                    if (send) begin
                        frame <= {1'b1, data, 1'b0};
                        state <= SEND; busy <= 1'b1; cnt <= 0; bit_idx <= 0;
                    end
                end
                SEND: begin
                    if (cnt == TICKS-1) begin
                        cnt <= 0;
                        tx <= frame[0];
                        frame <= {frame[8:0], 1'b1};  // BUG: shifts LEFT
                        if (bit_idx == 4'd9) begin
                            state <= IDLE; busy <= 1'b0; done <= 1'b1; bit_idx <= 0;
                        end else bit_idx <= bit_idx + 1'b1;
                    end else cnt <= cnt + 1'b1;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
