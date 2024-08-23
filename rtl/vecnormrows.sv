// Vector norm columns

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

module vecnormrows
 #(
  parameter ROWS = 3,
  parameter COLS = 2
) (
  fixedp g, // Fixed point parameters and common ports

  input [ROWS:1][COLS:1][g.WIDTH-1:0] a,
  output logic [ROWS:1][g.WIDTH-1:0] f
  );

// Rows are already contiguous, feed each row into rootsqr

genvar row;
generate
  for (row = 1; row <= ROWS; row = row + 1)
    begin
      rootsqr #(.COLS(COLS)) i_rootsqr(.g (g), .a (a[row]), .f (f[row]));
    end
endgenerate

endmodule
