# nkMatlib

nkMatlib is a SystemVerilog library for pipelined fixed-point matrix, vector
and scalar operations.  It was designed to help convert MATLAB code to
SystemVerilog while preserving some kind of direct correspondence between
the source code of both languages.

## Representation

### Packed Arrays

We represent a matrix made up of, for example, 16 bit numbers as a
SystemVerilog packed array.

Unfortunately we immediately run into a big-endian / little-endian type
of problem.  For nkMatlib, we chose little endian, but both possibilities
are explained below.

A 2x3 matrix (a matrix with two rows and three columns) called A could be
defined two ways:

~~~verilog
// Little endian (nkMatlib)
logic [2:1][3:1][17:0] A; // Matrix
logic [2:1][3:1][17:0] B; // Matrix
logic [3:1][17:0] C; // Vector

// Big endian
/* verilator lint_off ASCRANGE */
logic [1:2][1:3][17:0] A; // Matrix
logic [1:2][1:3][17:0] B; // Matrix
logic [1:3][17:0] C; // Vector
logic [17:0] z; // Scalar
~~~

Notice that the matrix dimension ranges begin with 1 instead of 0.  This
makes indexing compatible with standard mathematical notation.

Notice that dimension indices are ascending instead of the normal
descending for big-endian.  This allows us to use Verilog concatenation to
construct matrices in standard mathematical notation, see below.

For big-endian, notice that if you use Verilator for linting or simulation,
the warning for use of ascending ranges should be suppressed.

Either way (big-endian or little-endian), an element of the matrix can be
accessed like this:

~~~verilog
 z = A[2][3]; // Read element from row 2, column 3.
 z = A[row][column];
~~~

An entire matrix can be constructed by using the Verilog concatenation
operator as follows:

~~~verilog

//// Big-endian:

// Copy B to A

//      Col 1    Col 2    Col 3
 A = { B[1][1], B[1][2], B[1][3],   // Row 1
       B[2][1], B[2][2], B[2][3] }; // Row 2

// Assign vector C

 C = { 16'd1,   // Row 1
       16'd2,   // Row 2
       16'd3 }; // Row 3

//// Little-endian:

// Copy B to A

//      Col 3    Col 2    Col 1
 A = { B[2][3], B[2][2], B[2][1],   // Row 2
       B[1][3], B[1][2], B[1][1] }; // Row 1

// Assign vector C

 C = { 16'd3,   // Row 3
       16'd2,   // Row 2
       16'd1 }; // Row 1
~~~

As you can see, big-endian more closely matches mathematical notation.

Packed arrays can be directly assigned to bit vectors without any kind of
casting:

~~~verilog
logic [95:0] A_bits;
logic [$bits(A)-1:0] A_bits; // Note that you can use $bits() instead of a constant to copy the size

A_bits = A;
~~~

This is very convenient since it allows you to pass matrices through generic
library modules such as FIFOs.

The elements of a matrix are ordered like this in such a bit-vector:

~~~
// Big-endian:

  |95 ... 80|79 ... 64|63 ... 48|47 ... 32|31 ... 16|15 ...  0|
    A[1][1]   A[1][2]   A[1][3]   A[2][1]   A[2][2]   A[2][3]

// Little-endian:

  |95 ... 80|79 ... 64|63 ... 48|47 ... 32|31 ... 16|15 ...  0|
    A[2][3]   A[2][2]   A[2][1]   A[1][3]   A[1][2]   A[1][1]
~~~

So for big-endian: the least significant bit of element A[2][3] is indexed
as A_bits[0] and the most significant bit of element A[1][1] is indexed as
A_bits[95].

And for little-endian: the least significant bit of element A[1][1] is indexed
as A_bits[0] and the most significant bit of element A[2][3] is indexed as
A_bits[95].

Big-endian is better for using concatenation for construction within
Verilog.  But little-endian is better if matrices are going to be written
unmodified to a memory which is accessible by an external little-endian CPU.

From software on a CPU, you probably want to index matrices in the normal C
zero-based row-major order, like this:

~~~
     int16_t A[ROWS*COLS];
     int16_t z;
     z = A[row * ROWS + col]
~~~

or

~~~
    int16_t A[ROWS][COLS];
    int16_t z;
    z = A[row][col];
~~~

If we use big-endian in SystemVerilog, then C would have to look like this:

~~~
   int16_t A[ROWS*COLS];
   int16_t z;
   z = A[((ROWS - 1) - row)*ROWS + ((COLS - 1) - col)];
~~~

or

~~~
    int16_t A[ROWS][COLS];
    int16_t z;
    z = A[(ROWS - 1) - row][(COLS - 1) - col];
~~~

Notice that the matrices are stored in row-major order in either case, it's
just that both the row index values and column index values are mirrored.

### Fixed-point arithmetic

The library generally uses signed or unsigned 2's complement fixed-point
arithmetic.  Each number is specified by two parameters: it's WIDTH and its
SCALE.  WIDTH indicates the the total number of bits including the sign. 
SCALE is the number of fractional bits.

The parameters are encapsulated in a SystemVerilog interface called
__fixedp__ along with other common parameters and the clock (clk) and reset
signals.

__macros.svh__ is an include file which includes fixed point to floating
point conversion macros.  This example module illustrates the use of these
macros, and shows the typical boilerplate needed for any module using
nkMatlib:

~~~verilog
// All flies should include macros.svh
`include "macros.svh"

module mymodule
  (
  input clk,
  input reset,
  );

// Instantiate fixedp interface, specifying WIDTH and SCALE.
// Note that instance is called 'g', which is expected by some
// of the macros.

fixedp #(.WIDTH(16), .SCALE(12)) g(.clk (clk), .reset (reset));

// Some numbers

logic [2:1][3:1][g.WIDTH-1:0] A; // Matrix
logic [3:1][g.WIDTH-1:0] C; // Vector
logic [g.WIDTH-1:0] z; // Scalar

always @(posedge clk)
  if (reset)
    begin
      A <= '0;
      C <= '0;
      z <= '0;
    end
  else
    begin

      // Convert Verilog floating point constant to fixed point,
      // these all produce the same result:

      z <= `TOFIXED(-1.2, 16, 12); // Specify WIDTH and SCALE

      z <= `TOFIXEDP(-1.2, g); // Get parameters from specific interface

      z <= `TOFXD(-1.2); // Get parameter from default interface 'g'

      // Matrix
      //                                First col
      A <= { `TOFXD(2.2), `TOFXD(2.1), `TOFXD(2.0),   // Second row
             `TOFXD(1.2), `TOFXD(1.1), `TOFXD(1.0) }; // First row

      // Convert fixed point to floating point for $display,
      // these all produce the same result:

      $display("z = %f", `TOFLOAT(z, 16, 12)); // Specify WIDTH and SCALE

      $display("z = %f", `TOFLOATP(z, g)); // Get parameters from specific interface

      $display("z = %f", `TOFLT(z)); // Get parameter from default interface 'g'
    end


endmodule
~~~

#### Signed vs. Unsigned

Signed numbers are generally assumed, but some modules support unsigned. 'u'
is used to indicate unsigned and 's' is used to indicate signed in module
names:

	umul    Unsigned multiply
	smul    Signed multiply

Most operations will be indicated by module instantiation, but usualy not
comparisons.  It's a good idea to be explicit when performing comparisons:

~~~verilog
  if ($signed(z) > $signed(n))
    $display("z is more positive than n");
~~~

## Pipelining

All operator modules are pipelined.  This means that they have a throughput
of one result (or input) per clock cycle, but the latency depends on the
number of flip-flop stages that make up the operation.

If the overall latency of an operation composed of many operator modules is
100 cycles, then you may have 100 different threads in flight, but feedback
from a thread back to itself requires 100 cycles.

## Matching delays

As a thread flows through a pipeline, it is often necessary to pass
per-thread data in parallel with it.  It is usually not necessary to reset
the flip-flops that make up this delay.  The advantage of not resetting
these flip-flops is that synthesis will merge the flip flops into SRLs
(shift register memories).

On the other hand, it is often necessary to have at least a valid signal (a
signal which is high for each cycle with valid data) which is properly
reset.

We call these valid delays.

A typical operation stage looks like this:

~~~verilog

/// Perform: result = A*B+C

// Input: stage 0

logic [3:1][3:1][g.WIDTH-1:0] A_0;
logic [3:1][3:1][g.WIDTH-1:0] B_0;
logic [3:1][3:1][g.WIDTH-1:0] C_0;
logic valid_0;

// Stage 1, multiply

logic [3:1][3:1][g.WIDTH-1:0] prod_1;
logic [3:1][3:1][g.WIDTH-1:0] C_1;
logic valid_1;

matmul #(.A_ROWS(3), .A_COLS_B_ROWS(3), .B_COLS(3)) i_matmul_prod_1
  (
    .g (g), .a (A_0), .b (B_0), .f (prod_1)
  );

matmul_pipe #(.WIDTH($bits(C_0)) i_C_pipe_1
  (
    .g (g), .i (C_0), .o (C_1)
  );

matmul_valid i_valid_1
  (
    .g (g), .i (valid_0), .o (valid_1)
  );

// Stage 2, add

logic [3:1][3:1][g.WIDTH-1:0] result_2;
logic valid_2;

matadd #(.ROWS(3), .COLS(3)) i_matadd_result_2
  (
    .g (g), .a (prod_1), .b (C_1), .f (result_2)
  );

valid i_valid_2
  (
    .g (g), .i (valid_0), .o (valid_1)
  );

~~~

Note that this illustrates a good way to organize the signals between
stages: postfix the names with the stage number, so we have C_0, C_1 and
C_2.

## Modules
