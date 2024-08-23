# nkMatlib

nkMatlib is a SystemVerilog library and set of associated conventions for
pipelined real-valued fixed-point matrix, vector and scalar operations.  It
was designed to help convert MATLAB expressions to SystemVerilog while
preserving some kind of direct correspondence between the source code of
both languages.

nkMatlib is pipelined so that its throughput is one result per clock cycle. 
You may feed one entire independent problem into the pipeline each cycle. 
The latency of the calculation (the number of clocks needed to compute the
problem) depends on the number and type of operations that make it up.

## Example

Here is a simple example module that computes: A*B+C.  Multply a 3x2 matrix
A by a 2x3 matrix B and then add a 3x3 matrix C to the product.

~~~verilog

`include "macros.svh"

module example
  (
  fixedp g,

  input valid_0,
  input [3:1][2:1][g.WIDTH-1:0] A_0,
  input [2:1][3:1][g.WIDTH-1:0] B_0,
  input [3:1][3:1][g.WIDTH-1:0] C_0,

  output valid_N,
  output [3:1][3:1][g.WIDTH-1:0] result_N
  );

/// Perform: result = A*B+C

// Stage 1, prod = A*B

logic [3:1][3:1][g.WIDTH-1:0] prod_1;

matmul #(.A_ROWS(3), .A_COLS_B_ROWS(2), .B_COLS(3)) i_matmul_prod_1
  (
    .g (g), .a (A_0), .b (B_0), .f (prod_1)
  );

// Move signals along..

`PIPE(matmul_pipe, [3:1][3:1][g.WIDTH-1:0], C, 0, 1)
`PIPE(matmul_valid, , valid, 0, 1)

// Stage 2, result = prod+C

logic [3:1][3:1][g.WIDTH-1:0] result_2;

matadd #(.ROWS(3), .COLS(3)) i_matadd_result_2
  (
    .g (g), .a (prod_1), .b (C_1), .f (result_2)
  );

// Move signals along..

`PIPE(valid, , valid, 1, 2)

// Result

assign valid_N = valid_2;
assign result_N = result_2;

endmodule

~~~

By convention: All instance names are prefixed with i_ and postfixed with
_nn, where nn is the stage number.  The stage number is assigned to each
operation from inside out of the source expression.  This distinguishes
signals from instances, otherwise of the same name, and allows you to pass
signals with the same name through the stages.

By convention, module inputs are postfixed with _0 and outputs are postfixed
with _N.

All modules that use nkMatlib should include macros.svh.  Macros.svh
includes debugging and floating to fixed-point conversion macros.

All modules that use nkMatlib should have a __fixedp__ interface port. 
A convention is to call this port 'g'.

__Fixedp__ includes the clock and reset signals to be used by all logic within
the module.  It also includes parameters giving the size and precision of the
fixed-point numbers.  __Fixedp__ should be instantiated like this:

~~~verilog
fixedp #(.WIDTH(16), .SCALE(12)) g(.clk (my_clk), .reset (my_reset));
~~~

In this case, WIDTH indicates that each fixed-point number will use 16-bits. 
SCALE indicates that each fixed-point number has 12 fractional bits (12 bits
to the right of the binary point).  my_clk will be used as the clock. 
my_reset will be used as the reset signal.  nkMatlib uses synchronous reset.

There are two stages in this module, 1 and 2.

Stage 1 has the matrix multiply operator: __matmul__.  Stage 2 has the add
operator: __matadd__.  Stage 2 needs the input C, which must be delayed by a
number of clock cycles equaling the latency of __matmul__ so that C and the
__matmul__ result are ready in the same cycle.  __matmul_pipe__ provides
this matching delay.  The macro `PIPE generates the C_1 instance and the
__matmul_pipe__ instance.

A valid signal that indicates which cycles have valid data is passed through
the pipeline.  The __matmul_valid__ and __valid__ modules provide the
matching delays for this purpose.  The `PIPE macro is used to generate
valid_1, valid_2 and the __matmul_valid__ and __valid__ module instances.

Most flip flops in nkMatlib are not reset.  This allows the synthesis tool
to replace strings of flip-flops with shift registers (Xilinx SRLs).  But
flip flops for the valid signal are reset so that the valid signal is
correct right after reset.

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
logic [2:1][3:1][15:0] A; // Matrix
logic [2:1][3:1][15:0] B; // Matrix
logic [3:1][15:0] C; // Vector

// Big endian
/* verilator lint_off ASCRANGE */
logic [1:2][1:3][15:0] A; // Matrix
logic [1:2][1:3][15:0] B; // Matrix
logic [1:3][15:0] C; // Vector

logic [15:0] z; // Scalar
~~~

Notice that the matrix dimension ranges begin with 1 instead of 0.  This
makes indexing compatible with standard mathematical notation and MATLAB.

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

// Note that you can use $bits() instead of a constant
// to copy the size of A
logic [$bits(A)-1:0] A_bits; 

A_bits = A;
~~~

This is very convenient since it allows you to pass matrices through generic
library modules which typically accept bit vectors such as FIFOs.

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
arithmetic.  Each number is specified by two parameters: its WIDTH and its
SCALE.  WIDTH indicates the the total number of bits including the sign. 
SCALE is the number of fractional bits (number of bits to the right of the
binary point).

The parameters are encapsulated in a SystemVerilog interface called
__fixedp__ along with other common parameters and the clock (clk) and reset
signals.  __fixedp__ provides many other parameters dependent on WIDTH and
SCALE.  One of these is LEFT: the number of bits to the left of the binary
point, which is defined as (WIDTH - SCALE).

__macros.svh__ is an include file which includes fixed point to floating
point conversion macros.  This example module illustrates the use of these
macros, and shows the typical boilerplate needed for any module using
nkMatlib:

~~~verilog
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

Signed numbers are generally assumed, but some modules support unsigned.  A
'u' prefix on the operator name is used to indicate unsigned and 's' is used
to indicate signed:

	umul    Unsigned multiply
	smul    Signed multiply

Whether arguments are signed or not will generally be indicated by the
module instantiation, but this is not the case for directly synthesized
comparisons.  It's a good idea to be explicit when performing comparisons:

~~~verilog
reg q_3; // True if z_2 > n_2

always @(posedge g.clk)
  begin
    if ($signed(z_2) > $signed(n_2))
      begin
        if (valid_2)
          $display("z is more positive than n");
        q_3 <= 1;
      end
    else
      begin
        q_3 <= 0;
      end
  end
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

## Available Modules

### Utility functions and macros

#### showmat

Display a matrix when valid signal is high for debugging.

~~~verilog
showmat #(.ROWS(2), .COLS(3), .TITLE("Matrix A:")) i_showmat
  (
  .g (g), .valid (valid_7), .i (A_7)
  );
~~~

Prints:

    Matrix A:
     1 2 3
     4 5 6

#### showint

Display an integer when valid signal is high for debugging.  This is in the
same format as showmat for convenience.

~~~verilog
showint #(.TITLE("num:"), .WIDTH(8)) i_showmat
  (
  .g (g), .valid (valid_7), .i (num_7)
  );
~~~

Prints:

    num:
     12

#### \`SHOW, \`SHOWCONST, \`SHOWINT

Macros for printing values in pipeline stages.  These use showmat and
showint.  The title includes the signal name and the source file name and
line number.

~~~verilog
`SHOW(fred, 2, 3, 7)      // Print 2x3 matrix fred_7 when valid_7 is high
`SHOWCONST(fred, 2, 3, 7) // Print 2x3 matrix fred when valid_7 is high
`SHOWINT(fred, 8, 7)      // Print 8-bit number fred when valid_7 is high
~~~

#### \`DEBUG_SHOW, \`DEBUG_SHOWINT, \`DEBUG_SHOWCONST

Same as above, but they are active only if a macro DEBUG_ENABLE is defined.

#### \`PIPE

Macro that generates code that pulls signals from one stage to another.

~~~verilog
`PIPE(pipe, [2:1][3:1][g.WIDTH-1:0], fred, 6, 7)
~~~

The above generates the following code:

~~~verilog
logic [2:1][3:1][g.WIDTH-1:0] fred_7;

pipe #(.WIDTH($bits(fred_6))) i_pipe_fred_7
  (
  .g (g), .i (fred_6), .o (fred_7)
  );
~~~

This generates very common code which in this case pulls signal 'fred' from
stage 6 to stage 7 using matching pipeline module 'pipe'.  `PIPE can also be
used for the valid signal as follows:

~~~verilog
`PIPE(valid, , valid, 6, 7)
~~~

### Element by element operations

Each of these operators performs an element-by-element operation (the same
operation is performed on each corresponding element).

They all take two parameters: ROWS and COLS.  These specify the shape of the
matrix arguments.  The default for ROWS and COLS is 1.

These operators may be used for matrices, vectors or scalars:

  ROW=COL=1: argument is a scalar.

  ROW=1 or COLS=1: argument is a vector.

Note that row vectors and a column vectors of the same size have the same
packed array layout.  The two formats can be interchanged without any
conversion.

#### Convert between signed fixed point formats

elem_snorm provides the correct shifting, sign or zero extension and
truncation necessary to convert elements of a matrix from one fixed point
format into another.  Note that elem_snorm uses simple truncation: it rounds
numbers towards 0 when losing precision.

~~~verilog
elem_snorm #(.ROWS(2), .COLS(3)) i_elem_snorm_foo_6
  (
  .g (g), // Input format
  .h (h), // Output format
  .a (foo_6), // Input
  .f (foocvt_6) // Output
  );
~~~

Latency of elem_snorm is 0.

#### Element by element absolute value

Similar to MATLAB abs(A)

~~~verilog
elem_abs #(.ROWS(1), .COLS(1)) i_elem_abs
  (
  .g (g), .a (input), .f (result)
  );
~~~

elem_abs latency = 1.  Use __pipe__ and __valid__ for matching delays.

#### Element by element negate

Similar to MATLAB -A.

~~~verilog
elem_neg #(.ROWS(1), .COLS(1)) i_elem_abs
  (
  .g (g), .a (input), .f (result)
  );
~~~

elem_neg latency = 1.  Use __pipe__ and __valid__ for matching delays.

#### Element by element unsigned right-shift

Right shift each element by a specified number of bits.

~~~verilog
elem_rshift #(.ROWS(1), .COLS(1)) i_elem_rshift
  (
  .g (g), .a (input), .b (shift), .f (result)
  );
~~~

ele_rshift latency = 1.  Use __pipe__ and __valid__ for matching delays.

#### Create a matrix where all elements have the same scalar

Similar to MATLAB ones(rows, cols) and zeros(rows, cols)

~~~verilog
elem_same #(.ROWS(1), .COLS(1)) i_elem_same_ones
  (
  .g (g), .a (g.ONES), .f (my_ones)
  );
~~~

elem_same latency = 0.

Note that the parameters g.ZERO, g.ONE, g.TWO, g.THREE, g.ONE_HALF,
g.ONE_THIRD and g.TWO_THIRDS exist in __fixedp__ and may be used as inputs
to __elem_same__.

#### Element by element signed division

Similar to MATLAB Matrix ./ Matrix

~~~verilog
elem_sdiv #(.ROWS(1), .COLS(1)) i_elem_sdiv
  (
  .g (g), .a (dividend), .b (divisor), .f (quotient)
  );
~~~

elem_sdiv latency = g.DIV_LAT = g.WIDTH + g.SCALE.  Use __div_pipe__ and __div_valid__ for matching delays.

#### Signed division of each element of each matrix row by each element of a row vector

Similar to MATLAB Matrix ./ RowVector

~~~verilog
elem_sdiv_by_row #(.ROWS(1), .COLS(1)) i_elem_sdiv_by_row
  (
  .g (g), .a (dividend), .b (divisor_row), .f (quotient)
  );
~~~

The quotient has the same matrix shape as the dividend.

elem_sdiv latency = g.DIV_LAT = g.WIDTH + g.SCALE.  Use __div_pipe__ and __div_valid__ for matching delays.

#### Element by element signed inverse

Similar to MATLAB A.^-1

~~~verilog
elem_sinv #(.ROWS(1), .COLS(1)) i_elem_sinv
  (
  .g (g), .a (input), .f (result)
  );
~~~

elem_sinv latency = g.DIV_LAT = g.WIDTH + g.SCALE.  Use __div_pipe__ and __div_valid__ for matching delays.

#### Element by element signed maximum between two matrices

For two 2x2 matricies A and B, this computes a matrix C such that:

    C[1,1] = max(A[1,1], B[1,1])
    C[1,2] = max(A[1,2], B[1,2])
    C[2,1] = max(A[2,1], B[2,1])
    C[2,2] = max(A[2,2], B[2,2])

~~~verilog
elem_smax #(.ROWS(1), .COLS(1)) i_elem_smax
  (
  .g (g), .a (input_a), .b (input_b), .f (result)
  );
~~~

elem_smax latency = 1.  Use __pipe__ and __valid__ for matching delays.

#### Element by element signed minimum between two matrices

~~~verilog
elem_smin #(.ROWS(1), .COLS(1)) i_elem_smin
  (
  .g (g), .a (input_a), .b (input_b), .f (result)
  );
~~~

elem_smin latency = 1.  Use __pipe__ and __valid__ for matching delays.

#### Element by element signed multiplication between two matrices

Similar to MATLAB A.*B

~~~verilog
elem_smul #(.ROWS(1), .COLS(1)) i_elem_smul
  (
  .g (g), .a (a_input), .b (b_input), .f (result)
  );
~~~

elem_smul latency = g.MUL_LAT = 4.  Use __mul_pipe__ and __mul_valid__ for matching delays.

#### Signed multiplication of each element of each matrix column by each element of a column vector

~~~verilog
elem_smul_by_col #(.ROWS(1), .COLS(1)) i_elem_smul_by_col
  (
  .g (g), .a (a), .b (b_col), .f (result)
  );
~~~

Result has same matrix shape as a.

elem_smul_by_col latency = g.MUL_LAT = 4.  Use __mul_pipe__ and __mul_valid__ for matching delays.

#### Element by element signed square

Similar to MATLAB A.^2

Square each element of a matrix.

~~~verilog
elem_ssqr #(.ROWS(1), COLS(1)) i_elem_ssqr
  (
  .g (g), .a (a), .f (result)
  );
~~~

elem_ssqr latency = g.MUL_LAT = 4.  Use __mul_pipe__ and __mul_valid__ for matching delays.

#### Element by element square root

Similar to MATLAB sqrt(A)

Find square root of each element of a matrix.

~~~verilog
elem_usqrt #(.ROWS(1), .COLS(1)) i_elem_usqrt
  (
  .g (g), .a (a), .f (result)
  );
~~~

elem_usqrt latency = g.SQRT_LAT = g.WIDTH - (g.LEFT / 2).  Use __sqrt_pipe__ and __sqrt_valid__ for matching delays.

### Standard Matrix Operators

## Matrix addition

Similar to MATLAB A + B.  Add two matrices.

~~~verilog
matadd #(.ROWS(1), .COLS(1)) i_matadd
  (
  .g (g), .a (a), .b (b), .f (result)
  );
~~~

elem_matadd latency = 1.  Use __pipe__ and __valid__ for matching delays.

## Matrix subtraction

Similar to MATLAB A - B.  Subtract matrix B from matrix A.

~~~
matsub #(.ROWS(1), .COLS(1)) i_matsub
  (
  .g (g), .a (a), .b (b), .f (result)
  );
~~~

elem_matsub latency = 1.  Use __pipe__ and __valid__ for matching delays.

## Matrix addition of three arguments

Similar to MATLAB A + B + C.

~~~verilog
matadd3 #(.ROWS(1), .COLS(1)) i_matadd3
  (
  .g (g), .a (a), .b (b), .c (c), .f (result)
  );
~~~

elem_matadd3 latency = 1.  Use __pipe__ and __valid__ for matching delays.

## Matrix addition of three arguments, one negated

Similar to MATLAB A + B - C.

~~~verilog
matadd3b1 #(.ROWS(1), .COLS(1)) i_matadd3b1
  (
  .g (g), .a (a), .b (b), .c (c), .f (result)
  );
~~~

elem_matadd3b1 latency = 1.  Use __pipe__ and __valid__ for matching delays.

## Matrix addition of three arguments, two negated

Similar to MATLAB A - B - C.

~~~verilog
matadd3b2 #(.ROWS(1), .COLS(1)) i_matadd3b2
  (
  .g (g), .a (a), .b (b), .c (c), .f (result)
  );
~~~

elem_matadd3b2 latency = 1.  Use __pipe__ and __valid__ for matching delays.

## Matrix multiplication

Similar to MATLAB A*B.

~~~verilog
matmul #(.ROWS(1), .COLS(1)) i_matmul
  (
  .g (g), .a (a), .b (b), .g (result)
  );
~~~

matmul latency = g.MATMUL_LAT = g.MUL_LAT + 1 = 5.  Use __matmul_pipe__ and __matmul_valid__ for matching delays.

## Multiply a matrix by a scalar

Similar to MATLAB a*B, where a is a scalar.

~~~verilog
matscale #(.ROWS(1), .COLS(1)) i_matscale
  (
  .g (g), .a (a), .b (b_scalar), .g (result)
  );
~~~

matscale latency = g.MUL_LAT = 4.  Use __mul_pipe__ and __mul_valid__ for matching delays.

## Matrix division by a scalar

Similar to MATLAB A/b, where b is a scalar.

~~~verilog
matunscale #(.ROWS(1), .COLS(1)) i_matunscale
  (
  .g (g), .a (a), .b (b_scalar), .g (result)
  );
~~~

elem_sdiv latency = g.DIV_LAT = g.WIDTH + g.SCALE.  Use __div_pipe__ and __div_valid__ for matching delays.

## Select columns of a matrix

This is similar to the MATLAB syntax A(:,2:3)

~~~verilog
selcols #(.ROWS(1), .COLS(1), .FIRST(1), .LAST(1)) i_selcols
  (
  .g (g), .a (a_input), .f (result)
  );
~~~

selcols latency is 0.

## Select rows of a matrix

This is similar to the MATLAB syntax A(2:3,:)

~~~verilog
selrows #(.ROWS(1), .COLS(1), .FIRST(1), .LAST(1)) i_selrows
  (
  .g (g), .a (a_input), .f (result)
  );
~~~

selrows latency is 0.

## Transpose a matrix

Similar to the MATLAB syntax A.'

~~~verilog
transp #(.ROWS(1), .COLS(1)) i_transp
  (
  .g (g), .a (a), .f (f)
  );
~~~

transp latency is 0.

## Select maximum signed element of a vector

~~~verilog
vecmax #(.COLS(1)) i_vecmax
  (
  .g (g), .a (input_vector), .f (result_scalar)
  );
~~~

vecmax latency = 1.  Use __pipe__ and __valid__ for matching delays.

## Select minimum signed element of a vector

~~~verilog
vecmax #(.COLS(1)) i_vecmin
  (
  .g (g), .a (input_vector), .f (result_scalar)
  );
~~~

vecmin latency = 1.  Use __pipe__ and __valid__ for matching delays.

## Vector norm columns

Similar to MATLAB vecnorm(A,2,1)

Find the square root of the sum of the squares of the elements of each column.

~~~verilog
vecnormcols #(.ROWS(1), .COLS(1)) i_vecnormcols
  (
  .g (g), .a (a), .f (result)
  );
~~~

Result is a row vector with same number of columns as a.

## Vector norm rows

Similar to MATLAB vecnorm(A,2,2)

Find the square root of the sum of the squares of the elements of each row.

~~~verilog
vecnormrows #(.ROWS(1), .COLS(1)) i_vecnormrows
  (
  .g (g), .a (a), .f (result)
  );
~~~

Result is a column vector with same number of rows as a.

## Sumsqr

Sum the squares of the elements of A, resulting in a scalar.

Similar to MATLAB sumsqr(A).

~~~verilog
sumsqr #(.COLS(1)) i_sumsqr
  (
  .g (g), .a (input_vector), .f (result_scalar)
  );
~~~

sumsqr latency = g.SUMSQR_LAT = g.MUL_LAT + 1 = 5.  Use __sumsqr_pipe__ and __sumsqr_valid__
for matching delays.

## Rootsqr

Compute sqrt(sum of squares of elements of A), resulting in a scalar.

Similar to MATLAB norm(A).

~~~verilog
rootsqr #(.COLS(1)) i_rootsqr
  (
  .g (g), .a (input_vector), .f (result_scalar)
  );
~~~

rootsqr latency = g.ROOTSQR_LAT = g.SQRT_LAT + g.SUMSQR_LAT.  Use __rootsqr_pipe__ and
__rootsqr_valid__ for matching delays.

## Vector cross-product

Similar to MATLAB cross(A,B)

~~~verilog
crossp #(.COLS(1)) i_crossp
  (
  .g (g), .a (a_vector), .b (v_vector), .f (result_vector)
  );
~~~

crossp latency = g.CROSSP_LAT = g.MUL_LAT + 1 = 5.  Use __crossp_pipe__ and
__crossp_valid__ for matching delays.
