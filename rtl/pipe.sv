// Matching pipeline delay

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

module pipe
 #(
  parameter DELAY = 1,
  parameter WIDTH = 16
) (
  fixedp g,
  input [WIDTH-1:0] i,
  output logic [WIDTH-1:0] o
  );

wire clk = g.clk;
wire reset = g.reset;

logic [WIDTH-1:0] stage[DELAY:0];

assign stage[0] = i;

genvar x;
generate
  if (DELAY > 32)
    begin : gen_a
      piperam #(.WIDTH(WIDTH), .DELAY(DELAY)) u0 (.clk (clk), .reset (reset), .i (stage[0]), .o (stage[DELAY]));
    end
  else
    begin : gen_b
      for (x = 0; x != DELAY; x = x + 1)
        pipeone #(.WIDTH(WIDTH)) u0 (.clk (clk), .i (stage[x]), .o (stage[x + 1]));
    end
endgenerate

assign o = stage[DELAY];

endmodule
