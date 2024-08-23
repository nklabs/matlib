// Normalize a signed fixed-point number
//  Change width
//  Change binary point location
//  Latency = 0
//  Preserves sign

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

module norm
#(parameter A_WIDTH = 32,
  parameter A_SCALE = 12,
  parameter F_WIDTH = 32,
  parameter F_SCALE = 12,
  parameter VALIDWIDTH = 1,
  parameter PASSWIDTH = 1
) (
  input [A_WIDTH-1:0] a,
  output wire [F_WIDTH-1:0] f
  );

parameter T_WIDTH = A_WIDTH + F_SCALE - A_SCALE;

generate
  if (F_SCALE >= A_SCALE)
    begin : gen_a
      wire [T_WIDTH-1:0] tmp = { a, { F_SCALE - A_SCALE { 1'd0 } } };
      if (T_WIDTH >= F_WIDTH)
        begin : gen_a1
          assign f = tmp[F_WIDTH-1:0];
        end
      else
        begin : gen_a2
          assign f = { { F_WIDTH - T_WIDTH { tmp[T_WIDTH-1] } }, tmp };
        end
    end
  else
    begin : gen_b
      wire [T_WIDTH-1:0] tmp = a[A_WIDTH-1:A_SCALE-F_SCALE];
      if (T_WIDTH >= F_WIDTH)
        begin : gen_b1
          assign f = tmp[F_WIDTH-1:0];
        end
      else
        begin : gen_b2
          assign f = { { F_WIDTH - T_WIDTH { tmp[T_WIDTH-1] } }, tmp };
        end
    end
endgenerate

endmodule
