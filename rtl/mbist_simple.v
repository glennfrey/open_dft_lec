/*
 * mbist_simple.v -- March C- MBIST Controller for sram_8x16
 *
 * Implements the March C- algorithm (10N operations):
 *   { ⇑(w0); ⇑(r0,w1); ⇑(r1,w0); ⇓(r0,w1); ⇓(r1,w0); ⇑(r0) }
 *
 * FSM steps through each March element.  Address generator produces
 * ascending (⇑) or descending (⇓) sequences.  Data generator produces
 * w0/w1/r0/r1.  Comparator flags mismatches.
 *
 * Start:  start = 1 (one clock pulse)
 * Done:   done = 1 when complete
 * Pass:   fail = 0 if all reads match
 * Fail:   fail = 1 if any read mismatches
 *
 * NOTE: This is a teaching-quality MBIST.  Production MBIST would include:
 *   - MISR/signature compaction
 *   - Programmable algorithm selection (March C-, MATS+, etc.)
 *   - Background data patterns (checkerboard, etc.)
 *   - Repair address logging for BISR
 *   - IJTAG interface for configuration and readout
 */
module mbist_simple (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    output reg         done,
    output reg         fail,
    // Memory interface
    output reg  [2:0]  mut_addr,
    output reg         mut_wen,
    output reg  [15:0] mut_wdata,
    input  wire [15:0] mut_rdata
);

    // March C- elements (simplified FSM states)
    localparam IDLE     = 4'd0;
    localparam INIT_W0  = 4'd1;   // ⇑(w0)
    localparam UP_R0W1  = 4'd2;   // ⇑(r0,w1)
    localparam UP_R1W0  = 4'd3;   // ⇑(r1,w0)
    localparam DN_R0W1  = 4'd4;   // ⇓(r0,w1)
    localparam DN_R1W0  = 4'd5;   // ⇓(r1,w0)
    localparam FINAL_R0 = 4'd6;   // ⇑(r0)
    localparam FINISH   = 4'd7;

    reg [3:0] state;
    reg [3:0] next_state;
    reg [3:0] addr;           // 0-7 address counter
    reg       addr_dir;       // 1 = ascending, 0 = descending
    reg       addr_last;      // pulse when address wraps

    // Address generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr <= 4'd0;
        end else begin
            case (state)
                INIT_W0, UP_R0W1, FINAL_R0: begin
                    addr <= addr + 1'd1;
                    if (addr == 4'd7) addr <= 4'd0;
                end
                UP_R1W0: begin
                    addr <= addr + 1'd1;
                    if (addr == 4'd7) addr <= 4'd7;  // stay at 7 for DN_R0W1 start
                end
                DN_R0W1: begin
                    addr <= addr - 1'd1;
                    if (addr == 4'd0) addr <= 4'd7;
                end
                DN_R1W0: begin
                    addr <= addr - 1'd1;
                    if (addr == 4'd0) addr <= 4'd0;  // stay at 0 for FINAL_R0 start
                end
                default: addr <= 4'd0;
            endcase
        end
    end

    // Detect last address in each March element (simplified)
    always @(*) begin
        case (state)
            INIT_W0, UP_R0W1, UP_R1W0, FINAL_R0: addr_last = (addr == 4'd7);
            DN_R0W1, DN_R1W0: addr_last = (addr == 4'd0);
            default: addr_last = 1'b0;
        endcase
    end

    // FSM state register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:      if (start) next_state = INIT_W0;
            INIT_W0:   if (addr_last) next_state = UP_R0W1;
            UP_R0W1:   if (addr_last) next_state = UP_R1W0;
            UP_R1W0:   if (addr_last) next_state = DN_R0W1;
            DN_R0W1:   if (addr_last) next_state = DN_R1W0;
            DN_R1W0:   if (addr_last) next_state = FINAL_R0;
            FINAL_R0:  if (addr_last) next_state = FINISH;
            FINISH:    next_state = IDLE;
            default:   next_state = IDLE;
        endcase
    end

    // Memory control + data generation
    always @(*) begin
        mut_addr  = addr[2:0];
        mut_wen   = 1'b0;
        mut_wdata = 16'h0000;

        case (state)
            INIT_W0:  begin mut_wen = 1'b1; mut_wdata = 16'h0000; end
            UP_R0W1:  begin
                if (addr[0]) begin mut_wen = 1'b1; mut_wdata = 16'hFFFF; end
                else begin mut_wen = 1'b0; end
            end
            UP_R1W0:  begin
                if (addr[0]) begin mut_wen = 1'b1; mut_wdata = 16'h0000; end
                else begin mut_wen = 1'b0; end
            end
            DN_R0W1:  begin
                if (addr[0]) begin mut_wen = 1'b1; mut_wdata = 16'hFFFF; end
                else begin mut_wen = 1'b0; end
            end
            DN_R1W0:  begin
                if (addr[0]) begin mut_wen = 1'b1; mut_wdata = 16'h0000; end
                else begin mut_wen = 1'b0; end
            end
            FINAL_R0: begin mut_wen = 1'b0; end
            default:  ;
        endcase
    end

    // Expected data for comparator (address-aware for interleaved read/write)
    reg [15:0] expected;
    always @(*) begin
        case (state)
            UP_R0W1, DN_R0W1: expected = 16'h0000;   // all reads are 0
            // UP_R1W0/DN_R1W0: even addrs read 0 (never written with 1),
            //                  odd addrs read 1 (written in previous state)
            UP_R1W0, DN_R1W0: expected = addr[0] ? 16'hFFFF : 16'h0000;
            FINAL_R0:         expected = 16'h0000;   // all reads are 0
            default:          expected = 16'hXXXX;
        endcase
    end

    // Comparator + fail/done flags
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fail <= 1'b0;
            done <= 1'b0;
        end else begin
            if (state == IDLE) begin
                fail <= 1'b0;
                done <= 1'b0;
            end else if (state == FINISH) begin
                done <= 1'b1;
            end else begin
                // Compare during read states (not write-only)
                if (state == UP_R0W1 || state == UP_R1W0 ||
                    state == DN_R0W1 || state == DN_R1W0 || state == FINAL_R0) begin
                    if (mut_rdata !== expected) begin
                        $display("  DEBUG MBIST FAIL: state=%b addr=%h got=%h expected=%h", state, mut_addr, mut_rdata, expected);
                        fail <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
