/*
 * sram_8x16.v -- Simple single-port SRAM (8 words x 16 bits)
 *
 * Used as the Memory Under Test (MUT) for the MBIST controller demo.
 * No scan chain inside the array — MBIST tests it functionally.
 */
module sram_8x16 (
    input  wire        clk,
    input  wire        wen,      // write enable (active high)
    input  wire [2:0]  addr,     // 8 addresses
    input  wire [15:0] wdata,    // write data
    output reg  [15:0] rdata,    // read data (combinational for MBIST simplicity)
    input  wire        fault_inject // OR bit 0 when high (for MBIST demo)
);
    reg [15:0] mem [0:7];

    always @(posedge clk) begin
        if (wen)
            mem[addr] <= wdata;
    end

    always @(*)
        if (fault_inject)
            rdata = mem[addr] ^ 16'hFFFF;  // Invert all bits (very obvious fault)
        else
            rdata = mem[addr];

endmodule
