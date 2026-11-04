/*
 * uart_tx_wrapper.v -- IEEE 1500-style wrapper for uart_tx
 *
 * Modes (controlled by wrapper instruction register):
 *   NORMAL  (00): Transparent — functional I/O pass through
 *   INTEST  (01): Test core internal logic — wrapper drives core inputs,
 *                 captures core outputs via scan chain
 *   EXTEST  (10): Test interconnect — wrapper drives chip outputs,
 *                 captures chip inputs via scan chain
 *   BYPASS  (11): 1-bit bypass register (shortest path)
 *
 * Scan chain: WSIR (wrapper serial input) -> capture FFs -> update FFs -> WSOR
 */
module uart_tx_wrapper (
    // Functional clock / reset
    input  wire clk,
    input  wire rst_n,

    // Functional I/O (chip pins)
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output wire       tx_busy,
    output wire       tx_out,
    output wire       tx_done,

    // Wrapper test ports (IEEE 1500 style)
    input  wire wsir,           // wrapper scan input (for wrapper chain)
    output wire wsor,           // wrapper scan output
    input  wire wrck,           // wrapper clock
    input  wire wrst_n,         // wrapper reset
    input  wire shift_wr,       // shift wrapper chain
    input  wire capture_wr,     // capture pin states
    input  wire update_wr,      // load update FFs

    // Mode select (2-bit, from WIR)
    input  wire [1:0] mode      // 00=NORMAL, 01=INTEST, 10=EXTEST, 11=BYPASS
);

    // Internal core signals
    wire [7:0] core_tx_data;
    wire       core_tx_valid;
    wire       core_tx_busy;
    wire       core_tx_out;
    wire       core_tx_done;

    // Capture FFs (sample functional I/O)
    reg [7:0] cap_tx_data;
    reg       cap_tx_valid;
    reg       cap_tx_busy;
    reg       cap_tx_out;
    reg       cap_tx_done;

    // Update FFs (drive values in EXTEST mode)
    reg [7:0] upd_tx_data;
    reg       upd_tx_valid;
    reg       upd_tx_busy;
    reg       upd_tx_out;
    reg       upd_tx_done;

    // Bypass register
    reg bypass_reg;

    // -----------------------------------------------------------------
    // Capture phase
    // -----------------------------------------------------------------
    always @(posedge wrck or negedge wrst_n) begin
        if (!wrst_n) begin
            cap_tx_data  <= 8'd0;
            cap_tx_valid <= 1'b0;
            cap_tx_busy  <= 1'b0;
            cap_tx_out   <= 1'b0;
            cap_tx_done  <= 1'b0;
        end else if (capture_wr) begin
            case (mode)
                2'b01: begin // INTEST: capture core outputs
                    cap_tx_busy <= core_tx_busy;
                    cap_tx_out  <= core_tx_out;
                    cap_tx_done <= core_tx_done;
                    cap_tx_data <= 8'd0;  // inputs not captured in INTEST
                    cap_tx_valid<= 1'b0;
                end
                2'b10: begin // EXTEST: capture chip inputs
                    cap_tx_data <= tx_data;
                    cap_tx_valid<= tx_valid;
                    cap_tx_busy <= 1'b0;
                    cap_tx_out  <= 1'b0;
                    cap_tx_done <= 1'b0;
                end
                default: ;
            endcase
        end
    end

    // -----------------------------------------------------------------
    // Shift chain: 22 bits total
    //   order: tx_data[0..7], tx_valid, tx_busy, tx_out, tx_done
    //   plus bypass bit at end
    // -----------------------------------------------------------------
    reg [21:0] shift_reg;

    // -----------------------------------------------------------------
    // Update phase
    // -----------------------------------------------------------------
    always @(posedge wrck or negedge wrst_n) begin
        if (!wrst_n) begin
            upd_tx_data  <= 8'd0;
            upd_tx_valid <= 1'b0;
            upd_tx_busy  <= 1'b0;
            upd_tx_out   <= 1'b0;
            upd_tx_done  <= 1'b0;
        end else if (update_wr) begin
            {upd_tx_done, upd_tx_out, upd_tx_busy, upd_tx_valid, upd_tx_data} <=
                shift_reg;
        end
    end

    always @(posedge wrck or negedge wrst_n) begin
        if (!wrst_n) begin
            shift_reg <= 22'd0;
            bypass_reg <= 1'b0;
        end else if (shift_wr) begin
            {shift_reg, bypass_reg} <= {shift_reg[20:0], bypass_reg, wsir};
        end else if (capture_wr) begin
            shift_reg <= {cap_tx_done, cap_tx_out, cap_tx_busy, cap_tx_valid, cap_tx_data};
            bypass_reg <= bypass_reg;
        end
    end

    assign wsor = (mode == 2'b11) ? bypass_reg : shift_reg[21];

    // -----------------------------------------------------------------
    // Mode muxing
    // -----------------------------------------------------------------
    assign core_tx_data  = (mode == 2'b01) ? upd_tx_data  : tx_data;   // INTEST: from update FFs
    assign core_tx_valid = (mode == 2'b01) ? upd_tx_valid : tx_valid;

    assign tx_busy = (mode == 2'b10) ? upd_tx_busy : core_tx_busy;     // EXTEST: from update FFs
    assign tx_out  = (mode == 2'b10) ? upd_tx_out  : core_tx_out;
    assign tx_done = (mode == 2'b10) ? upd_tx_done : core_tx_done;

    // -----------------------------------------------------------------
    // Core instantiation
    // -----------------------------------------------------------------
    uart_tx core (
        .clk      (clk),
        .reset_n  (rst_n),
        .data     (core_tx_data),
        .send     (core_tx_valid),
        .busy     (core_tx_busy),
        .tx       (core_tx_out),
        .done     (core_tx_done)
    );

endmodule
