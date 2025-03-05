module top(input wire clk, input wire reset, input wire [31:0] cyc_cnt, output wire passed, output wire failed);

   // Your Verilog code here.

   assign passed = cyc_cnt > 40;
   assign failed = 1'b0;

endmodule