// Pipelined signed multiplier

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

module smul
  (
  fixedp g, // Fixed point parameters and common ports

  input signed [g.WIDTH-1:0] a,
  input signed [g.WIDTH-1:0] b,
  output wire [g.WIDTH-1:0] f
  );

wire [g.WIDTH*2-1:0] f_raw;

norm #(.A_WIDTH(2*g.WIDTH), .A_SCALE(2*g.SCALE), .F_WIDTH(g.WIDTH), .F_SCALE(g.SCALE)) f_normer
  (
  .a (f_raw),
  .f (f)
  );

smul_raw smul_raw
  (
  .g (g),

  .a (a),
  .b (b),
  .f (f_raw)
  );

`ifdef junk
always @(posedge g.clk)
  begin
    if (f_raw[g.WIDTH*2-1] != f[g.WIDTH-1])
      begin
        // Sign of result should not change here
        $display("%m %t: Multiply overflow!", $realtime);
        $finish;
      end
  end
`endif

endmodule
