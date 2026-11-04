/*
 * uart_tx_bsr.v -- UART transmitter with IEEE 1149.1 Boundary Scan Register
 *
 * Wraps the original uart_tx with boundary scan cells (BSC) on every I/O pin.
 * Demonstrates EXTEST (board-level interconnect test) and SAMPLE (pin state
 * capture without interfering with function).
 *
 * Modes:
 *   NORMAL  (shift_dr=0, capture_dr=0, update_dr=0):
 *       BSR transparent. uart_tx operates normally.
 *
 *   SAMPLE  (capture_dr=1, then shift):
 *       Capture functional pin states into BSC capture FFs.
 *       Then shift out through TDO for observation.
 *
 *   EXTEST  (update_dr loads BSC update FFs, then shift):
 *       BSC update FFs drive the outputs (isolating core).
 *       BSC capture FFs capture inputs.
 *       Used to test board-level wiring between chips.
 *
 * NOTE: This is a teaching-quality BSR.  Production would include:
 *   - Full TAP controller (FSM with 16 states)
 *   - Instruction register (IR) with BYPASS, IDCODE, etc.
 *   - Separate TCK domain for JTAG
 *   - Latch-based update cells (not simple FFs)
 */
module uart_tx_bsr (
    // Functional clocks / reset
    input  wire clk,
    input  wire rst_n,

    // Functional I/O (mapped through BSR)
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output wire       tx_busy,
    output wire       tx_out,
    output wire       tx_done,

    // JTAG-like boundary scan interface
    input  wire bsr_tck,        // boundary scan clock
    input  wire bsr_shift_dr,   // shift BSR chain
    input  wire bsr_capture_dr, // capture pin states
    input  wire bsr_update_dr,  // load update FFs
    input  wire bsr_si,         // serial in
    output wire bsr_so          // serial out
);

    // -----------------------------------------------------------------
    // Boundary Scan Cells (one per I/O bit)
    // Each BSC has:
    //   capture_ff: holds sampled pin value
    //   update_ff:  holds value to drive (EXTEST mode)
    // -----------------------------------------------------------------

    // Input BSCs: tx_data[7:0] (8 bits)
    reg [7:0] cap_tx_data;
    reg [7:0] upd_tx_data;

    // Input BSC: tx_valid (1 bit)
    reg cap_tx_valid;
    reg upd_tx_valid;

    // Output BSCs: tx_busy, tx_out, tx_done (3 bits)
    reg cap_tx_busy;
    reg cap_tx_out;
    reg cap_tx_done;
    reg upd_tx_busy;
    reg upd_tx_out;
    reg upd_tx_done;

    // Wires for core outputs (declared before use)
    wire core_busy, core_out, core_done;

    // -----------------------------------------------------------------
    // Capture phase: sample functional I/O on bsr_tck
    // -----------------------------------------------------------------
    always @(posedge bsr_tck) begin
        if (bsr_capture_dr) begin
            // Capture inputs (from chip pins toward core)
            cap_tx_data  <= tx_data;
            cap_tx_valid <= tx_valid;

            // Capture outputs (from core toward chip pins)
            cap_tx_busy  <= core_busy;
            cap_tx_out   <= core_out;
            cap_tx_done  <= core_done;
        end
    end

    // -----------------------------------------------------------------
    // Update phase: load update FFs (for EXTEST drive)
    // -----------------------------------------------------------------
    always @(posedge bsr_tck) begin
        if (bsr_update_dr) begin
            upd_tx_data  <= cap_tx_data;   // in real design, from shift path
            upd_tx_valid <= cap_tx_valid;
            upd_tx_busy  <= cap_tx_busy;
            upd_tx_out   <= cap_tx_out;
            upd_tx_done  <= cap_tx_done;
        end
    end

    // -----------------------------------------------------------------
    // Shift chain: serial shift register through all BSCs
    // Order (12 bits total):
    //   bsr_si -> cap_tx_data[0] -> [1] -> ... -> [7] ->
    //   cap_tx_valid -> cap_tx_busy -> cap_tx_out -> cap_tx_done -> bsr_so
    // -----------------------------------------------------------------
    reg [11:0] shift_reg;

    always @(posedge bsr_tck) begin
        if (bsr_shift_dr) begin
            shift_reg <= {shift_reg[10:0], bsr_si};
        end else if (bsr_capture_dr) begin
            // Parallel load from capture FFs
            shift_reg <= {cap_tx_done, cap_tx_out, cap_tx_busy,
                          cap_tx_valid, cap_tx_data};
        end
    end

    assign bsr_so = shift_reg[11];

    // -----------------------------------------------------------------
    // Connect captured data to update FFs when update_dr fires
    // (Simplified: in real 1149.1, update comes from shift_reg, not cap)
    // -----------------------------------------------------------------
    always @(posedge bsr_tck) begin
        if (bsr_update_dr) begin
            {upd_tx_done, upd_tx_out, upd_tx_busy,
             upd_tx_valid, upd_tx_data} <= shift_reg;
        end
    end

    // -----------------------------------------------------------------
    // Mode muxing: Normal vs. EXTEST
    // In EXTEST, update FFs drive outputs and feed inputs to core.
    // In Normal, functional pins pass straight through.
    // -----------------------------------------------------------------
    wire [7:0] core_tx_data  = bsr_update_dr ? upd_tx_data  : tx_data;
    wire       core_tx_valid = bsr_update_dr ? upd_tx_valid : tx_valid;

    assign tx_busy = bsr_update_dr ? upd_tx_busy : core_busy;
    assign tx_out  = bsr_update_dr ? upd_tx_out  : core_out;
    assign tx_done = bsr_update_dr ? upd_tx_done : core_done;

    // -----------------------------------------------------------------
    // Original uart_tx core (instantiated, not modified)
    // -----------------------------------------------------------------
    uart_tx core (
        .clk     (clk),
        .reset_n (rst_n),
        .data    (core_tx_data),
        .send    (core_tx_valid),
        .busy    (core_busy),
        .tx      (core_out),
        .done    (core_done)
    );

endmodule
