/* mini_cells.v -- behavioral models for mini.lib (simulation only) */
module NOTX1   (input A, output Y);          assign Y = ~A;            endmodule
module AND2X1  (input A, B, output Y);       assign Y = A & B;         endmodule
module OR2X1   (input A, B, output Y);       assign Y = A | B;         endmodule
module NAND2X1 (input A, B, output Y);       assign Y = ~(A & B);      endmodule
module NOR2X1  (input A, B, output Y);       assign Y = ~(A | B);      endmodule
module XOR2X1  (input A, B, output Y);       assign Y = A ^ B;         endmodule
module MUX2X1  (input A, B, S, output Y);    assign Y = S ? B : A;     endmodule
module DFFPOSX1(input D, CLK, output reg Q);
  always @(posedge CLK) Q <= D;
endmodule
module DFFRPOSX1(input D, CLK, RSTn, output reg Q);
  always @(posedge CLK or negedge RSTn)
    if (!RSTn) Q <= 1'b0; else Q <= D;
endmodule
module DFFSPOSX1(input D, CLK, SETn, output reg Q);
  always @(posedge CLK or negedge SETn)
    if (!SETn) Q <= 1'b1; else Q <= D;
endmodule
module DFFREPOSX1(input D, CLK, RSTn, EN, output reg Q);
  always @(posedge CLK or negedge RSTn)
    if (!RSTn) Q <= 1'b0; else if (EN) Q <= D;
endmodule
module DFFSEPOSX1(input D, CLK, SETn, EN, output reg Q);
  always @(posedge CLK or negedge SETn)
    if (!SETn) Q <= 1'b1; else if (EN) Q <= D;
endmodule
