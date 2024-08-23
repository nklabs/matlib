// Pipelined unsigned multiplier
// This one returns the full double-width product

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

module umul_raw
  (
  fixedp g, // Fixed point parameters and common ports

  input [g.WIDTH-1:0] a,
  input [g.WIDTH-1:0] b,
  output wire [g.WIDTH*2-1:0] f
  );

reg [g.WIDTH-1:0] a_1;
reg [g.WIDTH-1:0] a_2;

reg [g.WIDTH-1:0] b_1;
reg [g.WIDTH-1:0] b_2;

reg [g.WIDTH*2-1:0] result;
reg [g.WIDTH*2-1:0] result_3;
assign f = result;

always @(posedge g.clk)
  begin
    // Two stages of input pipeline
    a_1 <= a;
    b_1 <= b;

    a_2 <= a_1;
    b_2 <= b_1;

    result_3 <= a_2 * b_2; // Multiplier is here

    // One stage of output pipeline
    result <= result_3;
  end

endmodule
