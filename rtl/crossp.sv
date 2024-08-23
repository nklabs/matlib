// Vector cross product
//  Latency is 5

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

module crossp
 #(
  parameter COLS = 3
) (
  fixedp g, // Fixed point parameters and common ports

  input [COLS:1][g.WIDTH-1:0] a,
  input [COLS:1][g.WIDTH-1:0] b,
  output logic [COLS:1][g.WIDTH-1:0] f
  );

wire clk = g.clk;
wire reset = g.reset;

logic [COLS:1][g.WIDTH-1:0] u;
logic [COLS:1][g.WIDTH-1:0] v;

genvar i;
generate
  for (i = 1; i <= COLS; i = i + 1)
    begin
      smul u_smul (.g (g), .a (a[(i + 1 > COLS) ? (i + 1 - COLS) : (i + 1)]), .b (b[(i + 2 > COLS) ? (i + 2 - COLS) : (i + 2)]), .f (u[i]));
      smul v_smul (.g (g), .a (a[(i + 2 > COLS) ? (i + 2 - COLS) : (i + 2)]), .b (b[(i + 1 > COLS) ? (i + 1 - COLS) : (i + 1)]), .f (v[i]));
    end
endgenerate

integer j;
always @(posedge clk)
  begin
    for (j = 1; j <= COLS; j = j + 1)
      f[j] <= u[j] - v[j];
  end

endmodule
