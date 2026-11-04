/*
 * occ_simple.v -- Minimal On-Chip Clock (OCC) Controller
 *
 * Generates exactly 2 at-speed pulses (launch + capture) from a PLL clock,
 * then returns to slow scan clock.  Used for transition delay fault (TDF)
 * testing in scan-based designs.
 *
 * States: IDLE -> PULSE1 -> PULSE2 -> DONE -> IDLE
 *
 * Trigger: occ_start (pulse) initiates the sequence.
 * Output:  occ_clk = pll_clk when pulsing, 1'b0 otherwise.
 *
 * NOTE: This is a teaching-quality OCC.  A production design would include:
 *   - Clock gating with latch-based enable (glitch-free)
 *   - PLL lock check before enabling
 *   - Programmable pulse count (not hardcoded 2)
 *   - Scan-based configuration interface (IJTAG)
 */
module occ_simple (
    input  wire rst_n,       // async reset (active low)
    input  wire scan_clk,    // slow tester clock (not used for clock mux here)
    input  wire pll_clk,     // fast PLL clock (at-speed frequency)
    input  wire occ_start,   // pulse to trigger launch+capture sequence
    output reg  occ_clk,     // output clock: 2 pll_clk pulses when active
    output reg  occ_done     // high when sequence complete
);

    // FSM states
    localparam IDLE   = 3'b000;
    localparam P1     = 3'b001;   // launch pulse
    localparam P1_FALL= 3'b010;   // low between pulses
    localparam P2     = 3'b011;   // capture pulse
    localparam P2_FALL= 3'b100;   // low after capture
    localparam DONE   = 3'b101;

    reg [2:0] state;

    // Synchronous FSM on pll_clk domain
    always @(posedge pll_clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            occ_clk <= 1'b0;
            occ_done<= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    occ_done <= 1'b0;
                    if (occ_start) begin
                        state   <= P1;
                        occ_clk <= 1'b1;   // launch pulse rising edge
                    end else begin
                        occ_clk <= 1'b0;
                    end
                end

                P1: begin
                    // First full pulse of pll_clk
                    state   <= P1_FALL;
                    occ_clk <= 1'b0;       // falling edge
                end

                P1_FALL: begin
                    // Low period between launch and capture
                    state   <= P2;
                    occ_clk <= 1'b1;       // capture pulse rising edge
                end

                P2: begin
                    // Second full pulse of pll_clk
                    state   <= P2_FALL;
                    occ_clk <= 1'b0;       // falling edge
                end

                P2_FALL: begin
                    // Low period after capture
                    state   <= DONE;
                    occ_clk <= 1'b0;
                end

                DONE: begin
                    state    <= IDLE;
                    occ_done <= 1'b1;      // signal completion
                    occ_clk  <= 1'b0;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
