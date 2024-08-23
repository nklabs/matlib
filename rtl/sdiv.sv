// Pipelined signed divider
// Number of pipeline stages is WIDTH

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

module sdiv
  (
  fixedp g, // Fixed point parameters and common ports

  input [g.WIDTH-1:0] a,
  input [g.WIDTH-1:0] b,
  output wire [g.WIDTH-1:0] f
  );

wire clk = g.clk;
wire reset = g.reset;

// Size we need divider to be for given WIDTH and SCALE
parameter DIVIDEND_SCALE = (2*g.SCALE);
parameter DIV_WIDTH = DIVIDEND_SCALE + g.WIDTH - g.SCALE;

wire [DIV_WIDTH-1:0] a_norm;
wire [DIV_WIDTH-1:0] b_norm;
wire [DIV_WIDTH-1:0] f_norm;

norm #(.A_WIDTH(g.WIDTH), .A_SCALE(g.SCALE), .F_WIDTH(DIV_WIDTH), .F_SCALE(DIVIDEND_SCALE)) a_normer
  (
  .a (a),
  .f (a_norm)
  );

norm #(.A_WIDTH(g.WIDTH), .A_SCALE(g.SCALE), .F_WIDTH(DIV_WIDTH), .F_SCALE(g.SCALE)) b_normer
  (
  .a (b),
  .f (b_norm)
  );

norm #(.A_WIDTH(DIV_WIDTH), .A_SCALE(g.SCALE), .F_WIDTH(g.WIDTH), .F_SCALE(g.SCALE)) f_normer
  (
  .a (f_norm),
  .f (f)
  );

fixedp #(.WIDTH(DIV_WIDTH), .SCALE(DIVIDEND_SCALE)) h
  (
  .clk (clk),
  .reset (reset)
  );

sdiv_raw sdiv_raw
  (
  .h (h),

  .dividend (a_norm),
  .divisor (b_norm),
  .quotient (f_norm),
  .remainder ()
  );

endmodule
