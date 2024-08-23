// Macros

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

// By default, disable debug macros
`undef DEBUG_ENABLE


`ifndef macros
`define macros

// Macro that makes a pipeline stage for a signal
//  pipe: module name of pipeline type to use
//  decl: type of signal
//  signal: signal name
//  prev: previous stage name
//  next: next stage name: signals are declared with this suffix
`define PIPE(pipe,decl,signal,prev,next) \
  logic decl signal``_``next; \
  pipe #(.WIDTH($bits(signal``_``prev))) i_pipe_``signal``_``next(.g (g), .i (signal``_``prev), .o (signal``_``next));

`define SHOW(signal, rows, cols, stage) showmat #(.ROWS(rows), .COLS(cols), .TITLE({ `__FILE__, ":", `"`__LINE__`", ": ", `"signal``_``stage`", " =" })) i_showmat_``signal``_``stage(.g (g), .valid (valid_``stage``), .i (signal``_``stage));
`define SHOWCONST(signal, rows, cols, stage) showmat #(.ROWS(rows), .COLS(cols), .TITLE({ `__FILE__, ":", `"`__LINE__`", ": ", `"signal``_``stage`", " = (const)" })) i_showmat_``signal``_``stage(.g (g), .valid (valid_``stage``), .i (signal));
`define SHOWINT(signal, width, stage) showint #(.WIDTH(width), .TITLE({ `__FILE__, ":", `"`__LINE__`", ": ", `"signal``_``stage`", " =" })) i_showint_``signal``_``stage(.g (g), .valid (valid_``stage``), .i (signal``_``stage));

// Conditional versions of above

`define DEBUG_SHOW(a, b, c, d) \
  `ifdef DEBUG_ENABLE \
    `SHOW(a, b, c, d) \
  `endif

`define DEBUG_SHOWINT(a, b, c) \
  `ifdef DEBUG_ENABLE \
    `SHOWINT(a, b, c) \
  `endif

`define DEBUG_SHOWCONST(a, b, c, d) \
  `ifdef DEBUG_ENABLE \
    `SHOWCONST(a, b, c, d) \
  `endif


// Convert fixed point to real
`define TOFLOAT(x, scale) (real'(longint'(signed'(x))) / (real'(64'd1 << scale)))
`define TOFLOATP(x, h) `TOFLOAT((x), h.SCALE) // Get SCALE from fixedp interface given as parameter h
`define TOFLT(x) `TOFLOATP((x), g) // Get SCALE from fixedp interface called g in current scope

// Convert real to fixed point
`define TOFIXED(x, width, scale) (width'(longint'(real'(x) * (real'(64'd1 << scale)))))
`define TOFIXEDP(x, h) `TOFIXED((x), h.WIDTH, h.SCALE)
`define TOFXD(x) `TOFIXEDP((x), g)

`endif
