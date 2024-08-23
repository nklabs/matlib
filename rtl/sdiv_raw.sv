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

module sdiv_raw
  (
  fixedp h, // Fixed point parameters and common ports

  input [h.WIDTH-1:0] dividend,
  input [h.WIDTH-1:0] divisor,
  output wire [h.WIDTH-1:0] quotient,
  output wire [h.WIDTH-1:0] remainder
  );

wire clk = h.clk;
wire reset = h.reset;

wire divisor_neg = divisor[h.WIDTH-1];
wire [h.WIDTH-1:0] divisor_pos = divisor_neg ? -divisor : divisor;

wire dividend_neg = dividend[h.WIDTH-1];
wire [h.WIDTH-1:0] dividend_pos = dividend_neg ? -dividend : dividend;

wire [h.WIDTH-1:0] quotient_pos;
wire [h.WIDTH-1:0] remainder_pos;

wire divisor_neg_d;
pipe #(.DELAY(h.WIDTH), .WIDTH(1)) divisor_neg_pipe (.g (h), .i (divisor_neg), .o (divisor_neg_d));

wire dividend_neg_d;
pipe #(.DELAY(h.WIDTH), .WIDTH(1)) dividend_neg_pipe (.g (h), .i (dividend_neg), .o (dividend_neg_d));

assign quotient = (divisor_neg_d ^ dividend_neg_d) ? -quotient_pos : quotient_pos;

// This is what C does: it makes (quotient*divisor + remainder) true.
assign remainder = dividend_neg_d ? -remainder_pos : remainder_pos;

udiv_raw 
// #(.WIDTH(h.WIDTH)) // Verilator
  udiv_raw
  (
  .h (h),

  .divisor (divisor_pos),
  .dividend (dividend_pos),
  .quotient (quotient_pos),
  .remainder (remainder_pos)
  );

endmodule
