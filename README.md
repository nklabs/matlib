# nkMatlib

nkMatlib is a SystemVerilog library for pipelined fixed-point matrix, vector
and scalar operations.  It was designed to help convert MATLAB code to
SystemVerilog while preserving some kind of direct correspondence between
the source code of both languages.

## Basic idea

We represent a matrix made up of, for example, 18 bit numbers as a
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

 C = { 18'd1,   // Row 1
       18'd2,   // Row 2
       18'd3 }; // Row 3

//// Little-endian:

// Copy B to A

//      Col 3    Col 2    Col 1
 A = { B[2][3], B[2][2], B[2][1],   // Row 2
       B[1][3], B[1][2], B[1][1] }; // Row 1

// Assign vector C

 C = { 18'd3,   // Row 3
       18'd2,   // Row 2
       18'd1 }; // Row 1
~~~

As you can see, big-endian more closely matches mathematical notation.

Packed arrays can be directly assigned to bit vectors without any kind of
casting:

~~~verilog
logic [107:0] A_bits;
logic [$bits(A)-1:0] A_bits; // Note that you can use $bits() instead of a constant to copy the size

A_bits = A;
~~~

This is very convenient since it allows you to pass matrices through generic
library modules such as FIFOs.

The elements of a matrix are ordered like this in such a bit-vector:

~~~
// Big-endian:

  |107 ... 90|89 ... 72|71 ... 54|53 ... 36|35 ... 18|17 ...  0|
     A[1][1]   A[1][2]   A[1][3]   A[2][1]   A[2][2]   A[2][3]

// Little-endian:

  |107 ... 90|89 ... 72|71 ... 54|53 ... 36|35 ... 18|17 ...  0|
     A[2][3]   A[2][2]   A[2][1]   A[1][3]   A[1][2]   A[1][1]
~~~

So for big-endian: the least significant bit of element A[2][3] is indexed
as A_bits[0] and the most significant bit of element A[1][1] is indexed as
A_bits[107].

And for little-endian: the least significant bit of element A[1][1] is indexed
as A_bits[0] and the most significant bit of element A[2][3] is indexed as
A_bits[107].

Big-endian is better for using concatenation for construction within
Verilog.  But little-endian is better if matrices are going to be written
unmodified to a memory which is accessible by an external CPU.

From software on a CPU, you probably want to index matrices in the normal C
zero-based row-major order, like this:

~~~
     int A[ROWS*COLS];
     int z;
     z = A[row * ROWS + col]
~~~

or

~~~
    int A[ROWS][COLS];
    int z;
    z = A[row][col];
~~~

If we use big-endian in SystemVerilog, then C would have to look like this:

~~~
   int A[ROWS*COLS];
   int z;
   z = A[((ROWS - 1) - row)*ROWS + ((COLS - 1) - col)];
~~~

or

~~~
    int A[ROWS][COLS];
    int z;
    z = A[(ROWS - 1) - row][(COLS - 1) - col];
~~~

Notice that the matrices are stored in row-major order in either case, it's
just that both the row index values and column index values are mirrored.
