# matlib

Matlib is a SystemVerilog library for pipelined fixed-point matrix, vector
and scalar operations.  It was designed to help convert MATLAB code to
SystemVerilog while preserving a direct correspondence between the source
code of both languages. 

## Basic idea

We represent a matrix made up of, for example, 18 bit numbers as a
SystemVerilog packed array.  For example, a 2x3 matrix (a matrix with two
rows and three columns) called A is defined like this:

~~~verilog
logic [2:1][3:1][17:0] A; // Matrix
logic [2:1][3:1][17:0] B; // Matrix
logic [17:0] z; // Scalar
~~~

Note that indices are 1 based instead of 0 based for compatibility with
standard mathematical notation.

An element of the matrix can be accessed like this:

~~~verilog
 z = A[2][3]; // Read element from row 2, column 3.
 z = A[row][column];
~~~

An entire matrix can be constructed by using the Verilog concatenation
operator as follows:

~~~verilog

// Copy B to A...

//      Col 3    Col 2    Col 1
 A = { B[2][3], B[2][2], B[2][1],   // Row 2
       B[1][3], B[1][2], B[1][1] }; // Row 1
~~~

Unfortunately, both the rows and the columns are mirrored compared with
standard mathematical notation.
