// Matrix multiply

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

module matmul
 #(
  parameter A_ROWS = 1,
  parameter A_COLS_B_ROWS = 1,
  parameter B_COLS = 1
) (
  fixedp g, // Fixed point parameters and common ports

  input [A_ROWS:1][A_COLS_B_ROWS:1][g.WIDTH-1:0] a,
  input [A_COLS_B_ROWS:1][B_COLS:1][g.WIDTH-1:0] b,
  output logic [A_ROWS:1][B_COLS:1][g.WIDTH-1:0] f
  );

wire clk = g.clk;
wire reset = g.reset;

logic [A_ROWS:1][B_COLS:1][A_COLS_B_ROWS:1][g.WIDTH-1:0] t;

genvar row, col, i;
generate
  for (row = 1; row <= A_ROWS; row = row + 1)
    for (col = 1; col <= B_COLS; col = col + 1)
      for (i = 1; i <= A_COLS_B_ROWS; i = i + 1)
        smul u0(.g (g), .a (a[row][i]), .b (b[i][col]), .f (t[row][col][i]));
endgenerate

integer m, n, o;
logic [g.WIDTH-1:0] z;

/* verilator lint_off BLKSEQ */
always @(posedge clk)
  begin
    for (m = 1; m <= A_ROWS; m = m + 1)
      for (n = 1; n <= B_COLS; n = n + 1)
        begin
          z = g.ZERO;
          for (o = 1; o <= A_COLS_B_ROWS; o = o + 1)
            z = z + t[m][n][o];
          f[m][n] <= z;
        end
  end
/* verilator lint_on BLKSEQ */

endmodule
