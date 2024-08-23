// Unsigned pipelined square root

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

module usqrt
  (
  fixedp g, // Fixed point parameters and common ports

  input [g.WIDTH-1:0] a, // Argument
  output logic [g.WIDTH-1:0] f // Result
  );

parameter LEFT = (g.WIDTH-g.SCALE); // Number of bits to left of binary point
// (it works if SCALE is equal to WIDTH, but not as accurate)
parameter STEPS = (g.WIDTH-(LEFT/2)); // Number of loops

// Pipeline connections
wire [g.WIDTH:0] b[STEPS:0];
wire [g.WIDTH:0] q[STEPS:0];
wire [g.WIDTH:0] r[STEPS:0];

`ifdef junk
always @(posedge g.clk)
  if (a[g.WIDTH-1] == 1)
    begin
      $display("%m %t Trying to usqrt a negative number!\n", $realtime);
      $finish;
    end
`endif

// Feed pipe
assign r[0] = { 1'd0, a };
assign q[0] = 0;
assign b[0] = { { g.WIDTH { 1'd0 } }, 1'd1 } << (g.WIDTH-2); // (1 << (g.WIDTH-2))

// Pick up results
wire [g.WIDTH:0] q_i = q[STEPS];
assign f = { { LEFT/2 { 1'd0 } }, q_i[g.WIDTH-1:LEFT/2] };

// Instantiate pipeline stages
genvar i;

generate
  for (i = 0; i != STEPS; i = i + 1)
    begin
      sqrt_step i_step
        (
        .g (g),
        .r_in (r[i]),
        .r (r[i+1]),
        .b_in (b[i]),
        .b (b[i+1]),
        .q_in (q[i]),
        .q (q[i+1])
        );
    end
endgenerate

endmodule

/* Original:

Computing the square root of an integer or a fixed point integer into a
fixed point integer.  A fixed point is a 32 bit value with the comma between
the bits 15 and 16, where bit 0 is the less significant bit of the value.
  
The algorithms can be easily extended to 64bit integers, or different fixed
point comma positions.  The algorithm uses the property that computing x² is
trivial compared to the sqrt.  It will thus search the biggest x so that x²
<= v, assuming we compute sqrt(v).
    
The algorithm tests each bit of x starting with the most significant toward
the less significant.  It tests if the bit must be set or not.
  
The algorithm uses the relation (x + a)² = x² + 2ax + a² to add the bit
efficiently.  Instead of computing x² it keeps track of (x + a)² - x².
  
When computing sqrt(v), r = v - x², q = 2ax, b = a² and t = 2ax + a2.  Note
that the input integers are signed and that the sign bit is used in the
computation.  To accept unsigned integer as input, unfolding the initial
loop is required to handle this particular case.  See the usenet discussion
for the proposed solution.
  
Algorithm and code Author Christophe Meessen 1993. 
Initially published in usenet comp.lang.c, Thu, 28 Jan 1993 08:35:23 GMT, 
Subject: Fixed point sqrt ; by Meessen Christophe
  
https://groups.google.com/forum/?hl=fr%05aacf5997b615c37&fromgroups#!topic/comp.lang.c/IpwKbw0MAxw/discussion

fixed sqrtF2F ( fixed x )
{
    uint32_t t, q, b, r;
    r = x;
    b = 0x40000000;
    q = 0;
    while( b > 0x40 )
    {
        t = q + b;
        if( r >= t )
        {
            r -= t;
            q = t + b; // equivalent to q += 2*b
        }
        r <<= 1;
        b >>= 1;
    }
    q >>= 8;
    return q;
}
*/

/* Parameterized as follows:

#include <stdlib.h>
#include <math.h>
#include <stdint.h>

#define SCALE 12
#define WIDTH 20
#define LEFT (WIDTH-SCALE) // Bits to left of binary point
#define N (WIDTH-(LEFT/2)) // Number of steps needed

// Empirically

unsigned int sqrtF2F (unsigned int x)
{
    int n;
    uint32_t t, q, b, r;
    r = x;
    b = (1 << (WIDTH - 2));
    q = 0;

    for (n = 0; n != N; ++n)
    {
        t = q + b;
        if( r >= t )
        {
            r -= t;
            q = t + b; // equivalent to q += 2*b
        }
        r <<= 1;
        b >>= 1;
    }

    q >>= (WIDTH - SCALE) / 2;

    return q;
}

// Verify that it works for every value in entire range:

int main(int argc, char *argv[])
{
    uint32_t x;
    for (x = 0; x != (1 << WIDTH); ++x) {
        uint32_t y = sqrtF2F(x);
        double i = (x / (double)(1 << SCALE));
        double j = sqrt(i);
        uint32_t k = j * (double)(1 << SCALE);
        if (y != k) {
            // Print any mistakes
            printf("%u -> %u (%u)\n", x, y, k);
        }
    }
}

*/
