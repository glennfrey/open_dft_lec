/*
 * uart_rx_mini.v -- Minimal 8N1 UART receiver (~10 FFs)
 *
 * Used as a second core in the hierarchical DFT wrapper demo.
 * Small enough to match uart_tx complexity for fair INTEST comparison.
 */
module uart_rx_mini (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        rxd,
    output reg  [7:0]  rx_data,
    output reg         rx_valid,
    input  wire        rx_ready
);

    localparam CLK_DIV = 434;   // 50 MHz / 115200 ≈ 434

    reg [3:0]  state;
    reg [12:0] baud_cnt;
    reg [3:0]  bit_idx;
    reg [7:0]  shift_reg;
    reg        rxd_sync;

    localparam IDLE  = 4'd0;
    localparam START = 4'd1;
    localparam DATA  = 4'd2;
    localparam STOP  = 4'd3;
    localparam DONE  = 4'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= IDLE;
            baud_cnt <= 13'd0;
            bit_idx  <= 4'd0;
            shift_reg<= 8'd0;
            rx_data  <= 8'd0;
            rx_valid <= 1'b0;
            rxd_sync <= 1'b1;
        end else begin
            rxd_sync <= rxd;
            rx_valid <= 1'b0;

            case (state)
                IDLE: begin
                    baud_cnt <= 13'd0;
                    if (rxd_sync == 1'b0) begin
                        state <= START;
                    end
                end

                START: begin
                    if (baud_cnt == CLK_DIV/2) begin
                        state <= DATA;
                        baud_cnt <= 13'd0;
                        bit_idx  <= 4'd0;
                    end else begin
                        baud_cnt <= baud_cnt + 1'd1;
                    end
                end

                DATA: begin
                    if (baud_cnt == CLK_DIV) begin
                        baud_cnt <= 13'd0;
                        shift_reg <= {rxd_sync, shift_reg[7:1]};
                        if (bit_idx == 4'd7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'd1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'd1;
                    end
                end

                STOP: begin
                    if (baud_cnt == CLK_DIV) begin
                        rx_data  <= shift_reg;
                        rx_valid <= 1'b1;
                        state    <= DONE;
                    end else begin
                        baud_cnt <= baud_cnt + 1'd1;
                    end
                end

                DONE: begin
                    if (rx_ready)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
