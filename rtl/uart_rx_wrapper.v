/*
 * uart_rx_wrapper.v -- IEEE 1500-style wrapper for uart_rx_mini
 *
 * Modes: NORMAL (00), INTEST (01), EXTEST (10), BYPASS (11)
 * Scan chain: WSIR -> capture FFs -> update FFs -> WSOR
 */
module uart_rx_wrapper (
    input  wire        clk,
    input  wire        rst_n,

    // Functional I/O
    input  wire        rxd,
    output wire [7:0]  rx_data,
    output wire        rx_valid,
    input  wire        rx_ready,

    // Wrapper test ports
    input  wire        wsir,
    output wire        wsor,
    input  wire        wrck,
    input  wire        wrst_n,
    input  wire        shift_wr,
    input  wire        capture_wr,
    input  wire        update_wr,

    input  wire [1:0]  mode
);

    // Core signals
    wire       core_rxd;
    wire [7:0] core_rx_data;
    wire       core_rx_valid;

    // Capture FFs
    reg        cap_rxd;
    reg [7:0]  cap_rx_data;
    reg        cap_rx_valid;
    reg        cap_rx_ready;

    // Update FFs
    reg        upd_rxd;
    reg [7:0]  upd_rx_data;
    reg        upd_rx_valid;
    reg        upd_rx_ready;

    reg        bypass_reg;

    // Capture
    always @(posedge wrck or negedge wrst_n) begin
        if (!wrst_n) begin
            cap_rxd      <= 1'b1;
            cap_rx_data  <= 8'd0;
            cap_rx_valid <= 1'b0;
            cap_rx_ready <= 1'b0;
        end else if (capture_wr) begin
            case (mode)
                2'b01: begin // INTEST: capture core outputs
                    cap_rx_data  <= core_rx_data;
                    cap_rx_valid <= core_rx_valid;
                    cap_rxd      <= 1'b1;
                    cap_rx_ready <= 1'b0;
                end
                2'b10: begin // EXTEST: capture chip input
                    cap_rxd      <= rxd;
                    cap_rx_data  <= 8'd0;
                    cap_rx_valid <= 1'b0;
                    cap_rx_ready <= 1'b0;
                end
                default: ;
            endcase
        end
    end

    // Shift chain: 12 bits
    reg [11:0] shift_reg;

    // Update
    always @(posedge wrck or negedge wrst_n) begin
        if (!wrst_n) begin
            upd_rxd      <= 1'b1;
            upd_rx_data  <= 8'd0;
            upd_rx_valid <= 1'b0;
            upd_rx_ready <= 1'b0;
        end else if (update_wr) begin
            {upd_rx_ready, upd_rx_valid, upd_rx_data, upd_rxd} <= shift_reg[11:0];
        end
    end

    always @(posedge wrck or negedge wrst_n) begin
        if (!wrst_n) begin
            shift_reg  <= 12'd0;
            bypass_reg <= 1'b0;
        end else if (shift_wr) begin
            {shift_reg, bypass_reg} <= {shift_reg[10:0], bypass_reg, wsir};
        end else if (capture_wr) begin
            shift_reg <= {cap_rx_ready, cap_rx_valid, cap_rx_data, cap_rxd};
            bypass_reg <= bypass_reg;
        end
    end

    // Scan out: BYPASS mode outputs bypass_reg; EXTEST outputs captured rxd directly;
    // INTEST outputs shift_reg MSB (normal shift chain operation)
    assign wsor = (mode == 2'b11) ? bypass_reg :
                  (mode == 2'b10) ? cap_rxd : shift_reg[11];

    // Mode muxing
    assign core_rxd = (mode == 2'b01) ? upd_rxd : rxd;
    assign rx_data  = (mode == 2'b10) ? upd_rx_data  : core_rx_data;
    assign rx_valid = (mode == 2'b10) ? upd_rx_valid : core_rx_valid;
    // rx_ready is an input, not driven by wrapper in this simple model

    uart_rx_mini core (
        .clk      (clk),
        .rst_n    (rst_n),
        .rxd      (core_rxd),
        .rx_data  (core_rx_data),
        .rx_valid (core_rx_valid),
        .rx_ready (rx_ready)
    );

endmodule
