// Pipelined unsigned divider
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

module udiv_raw
  (
  fixedp h, // Fixed point parameters and common ports

  input [h.WIDTH-1:0] dividend,
  input [h.WIDTH-1:0] divisor,
  output wire [h.WIDTH-1:0] quotient,
  output wire [h.WIDTH-1:0] remainder
  );

wire [h.WIDTH-1:0] m_work[h.WIDTH:0];
wire [h.WIDTH*2-1:0] aq_work[h.WIDTH:0];
wire [h.WIDTH-1:0] q_work[h.WIDTH:0];

assign q_work[0] = 0;
assign m_work[0] = divisor;
assign aq_work[0] = { { h.WIDTH { 1'd0 } }, dividend };

wire [h.WIDTH*2-1:0] aq_i = aq_work[h.WIDTH];
wire [h.WIDTH*2-1:0] aq_j = aq_i[h.WIDTH-1] ? aq_i + { m_work[h.WIDTH], { h.WIDTH { 1'd0 } } } : aq_i;

assign remainder = aq_j[h.WIDTH*2-1:h.WIDTH];
assign quotient = q_work[h.WIDTH];

localparam MY_WIDTH = h.WIDTH; // Workaround Verilator bug

genvar i;
generate
  //for (i = 0; i != (h.WIDTH); i = i + 1)  // This does not work in Verilator due to Verilator bug
  for (i = 0; i != MY_WIDTH; i = i + 1) // But this does
  //for (i = 0; i != (WIDTH); i = i + 1)
    begin
      udiv_step i_step(
        .h (h),
        .aq_in (aq_work[i]),
        .aq_out (aq_work[i + 1]),
        .q_in (q_work[i]),
        .q_out (q_work[i + 1]),
        .m_in (m_work[i]),
        .m_out (m_work[i + 1])
      );
    end
endgenerate

endmodule
