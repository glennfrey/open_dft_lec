/*
 * uart_tx.v -- Simple 8N1 UART transmitter
 * Target block for the open-source DFT + LEC flow.
 * Lattice JD keywords covered: synthesis, equivalence check,
 * scan insertion (DFT), ATPG, tapeout-style sign-off.
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

    localparam IDLE = 2'd0,
               SEND = 2'd1;

    reg [1:0]                  state;
    reg [9:0]                  frame;   // {stop, data[7:0], start}
    reg [$clog2(TICKS)-1:0]    cnt;
    reg [3:0]                  bit_idx;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state   <= IDLE;
            tx      <= 1'b1;
            busy    <= 1'b0;
            done    <= 1'b0;
            frame   <= 10'h3FF;
            cnt     <= 0;
            bit_idx <= 4'd0;
        end else begin
            done <= 1'b0;  // 1-cycle pulse
            case (state)
                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    if (send) begin
                        frame   <= {1'b1, data, 1'b0};  // stop | D7..D0 | start
                        state   <= SEND;
                        busy    <= 1'b1;
                        cnt     <= 0;
                        bit_idx <= 4'd0;
                    end
                end
                SEND: begin
                    if (cnt == TICKS-1) begin
                        cnt  <= 0;
                        tx   <= frame[0];                  // LSB first
                        frame <= {1'b1, frame[9:1]};       // shift in idle '1's
                        if (bit_idx == 4'd9) begin         // stop bit just driven
                            state   <= IDLE;
                            busy    <= 1'b0;
                            done    <= 1'b1;
                            bit_idx <= 4'd0;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        cnt <= cnt + 1'b1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
