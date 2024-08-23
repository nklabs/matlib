// All fixed-point math modules need these parameters and ports

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

interface fixedp
#(
  parameter WIDTH=16, // How many bits in the number
  parameter SCALE=10 // How many bits to the right of the binary point
) (
  input clk,
  input reset
);

// Derived

parameter LEFT = WIDTH-SCALE; // Number of bits to the left of the binary point

// Fixed point representation of common numbers

parameter ZERO = { WIDTH { 1'd0 } };

parameter ONE = { { (LEFT - 2) { 1'd0 } }, 2'd1, { SCALE { 1'd0 } } };
parameter TWO = { { (LEFT - 2) { 1'd0 } }, 2'd2, { SCALE { 1'd0 } } };
parameter THREE = { { (LEFT - 2) { 1'd0 } }, 2'd3, { SCALE { 1'd0 } } };

parameter ONE_HALF = { { LEFT { 1'd0 } }, 1'd1, { (SCALE - 1) { 1'd0 } } };

// Warning: these only work if SCALE is a multiple of two!
parameter ONE_THIRD = { { LEFT { 1'd0 } }, { (SCALE / 2) { 2'b01 } } };
parameter TWO_THIRDS = { { LEFT { 1'd0 } }, { (SCALE / 2) { 2'b10 } } };

// Latencies

parameter MUL_LAT = 4; // Multiplication
//parameter DIV_LAT = WIDTH; // Division
parameter DIV_LAT = (WIDTH + SCALE);
parameter SQRT_LAT = WIDTH - (LEFT / 2);
parameter INV_LAT = DIV_LAT;

parameter MATMUL_LAT = MUL_LAT + 1;
parameter CROSSP_LAT = MUL_LAT + 1;
parameter SUMSQR_LAT = MUL_LAT + 1;
parameter ROOTSQR_LAT = SQRT_LAT + SUMSQR_LAT;
parameter VECNORM_LAT = ROOTSQR_LAT;

endinterface
