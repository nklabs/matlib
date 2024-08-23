// Element by element signed multiply by column

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

module elem_smul_by_col
 #(
  parameter ROWS = 1,
  parameter COLS = 1
) (
  fixedp g, // Fixed point parameters and common ports

  input [ROWS:1][COLS:1][g.WIDTH-1:0] a,
  input [ROWS:1][g.WIDTH-1:0] b, // One column
  output logic [ROWS:1][COLS:1][g.WIDTH-1:0] f
  );

logic [ROWS:1][COLS:1][g.WIDTH-1:0] x;

dup_cols #(.ROWS (ROWS), .COLS (COLS)) i_dup_rows (.g (g), .a (b), .f (x));

elem_smul #(.ROWS (ROWS), .COLS (COLS)) i_elem_smul (.g (g), .a (a), .b (x), .f (f));

endmodule
