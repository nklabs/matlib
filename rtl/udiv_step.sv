// Division step

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

// This is the standard non-restoring division algorithm except:
//   Keep quotient separated from remainder / aq: the synthesis tool finds more to optimize this way
//   Use controlled negation instead of a mux between add and subtract: halves the LUTs

module udiv_step
  (
  fixedp h, // Fixed point parameters and common ports

  input [h.WIDTH*2-1:0] aq_in,
  output reg [h.WIDTH*2-1:0] aq_out,

  input [h.WIDTH-1:0] q_in,
  output reg [h.WIDTH-1:0] q_out,

  input [h.WIDTH-1:0] m_in,
  output reg [h.WIDTH-1:0] m_out
  );

// Shifted AQ
wire [h.WIDTH*2-1:0] shift = { aq_in[h.WIDTH*2-2:0], 1'd0 };

// Compute next AQ
wire [h.WIDTH*2-1:0] next_aq;

// Low half is just passed on
assign next_aq[h.WIDTH-1:0] = shift[h.WIDTH-1:0];

// m_in is added or subtracted from upper half depending on sign
assign next_aq[h.WIDTH*2-1:h.WIDTH] = shift[h.WIDTH*2-1:h.WIDTH] + (aq_in[h.WIDTH*2-1] ? m_in : ~m_in) + { { h.WIDTH - 1 { 1'd0 } }, ~aq_in[h.WIDTH*2-1] };

// Pipeline stage: no reset, maybe it will combine stages into SRLs
always @(posedge h.clk)
  begin
    m_out <= m_in;
    aq_out <= next_aq;
    q_out <= { q_in[h.WIDTH-2:0], ~next_aq[h.WIDTH*2-1] };
  end

endmodule
