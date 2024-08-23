// Use RAM for a large pipeline delay

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

module piperam
 #(
  parameter DELAY = 1,
  parameter WIDTH = 16
) (
  input clk,
  input reset,
  input [WIDTH-1:0] i,
  output logic [WIDTH-1:0] o
  );

parameter ADDRWIDTH = $clog2(DELAY);

logic [ADDRWIDTH-1:0] wr_addr;
logic [ADDRWIDTH-1:0] rd_addr;
logic wr_valid;

ram_blk_dp #(.DATAWIDTH(WIDTH), .ADDRWIDTH(ADDRWIDTH)) pipe_ram // Latency is 2
  (
  .clk (clk),
  .wr_data (i),
  .wr_addr (wr_addr),
  .we (wr_valid),
  .rd_addr (rd_addr),
  .rd_data (o)
  );

always @(posedge clk)
  if (reset)
    begin
      wr_addr <= ADDRWIDTH'(DELAY) - 1;
      wr_valid <= 0;
      rd_addr <= 0;
    end
  else
    begin
      wr_addr <= wr_addr + 1'd1;
      rd_addr <= rd_addr + 1'd1;
      wr_valid <= 1;
    end

endmodule
