// Sum of squared elements

// Copyright 2023 NK Labs, LLC

// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
// OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
// THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module sumsqr
 #(
  parameter COLS = 3
) (
  fixedp g, // Fixed point parameters and common ports

  input [COLS:1][g.WIDTH-1:0] a,
  output logic [g.WIDTH-1:0] f
  );

wire clk = g.clk;
wire reset = g.reset;

logic [COLS:1][g.WIDTH-1:0] u;

genvar i;
generate
  for (i = 1; i <= COLS; i = i + 1)
    begin
      ssqr i_ssqr (.g (g), .a (a[i]), .f (u[i]));
    end
endgenerate

logic [g.WIDTH-1:0] z;

/* verilator lint_off BLKSEQ */
integer j;
always @(posedge clk)
  begin
    z = 0;
    for (j = 1; j <= COLS; j = j + 1)
      z = z + u[j];
    f <= z;
  end
/* verilator lint_on BLKSEQ */

endmodule
