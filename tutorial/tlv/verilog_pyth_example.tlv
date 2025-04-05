// Pythagora's Theorem in SystemVerilog.

// This is just an example to show that you can code Verilog/SystemVerilog in the IDE.
// Note that "NavTLV" and "Diagram" panes represent TL-Verilog, and will display "X" for a pure Verilog design.

// This code is essentially the SystemVerilog that SandPiper(TM) generates for the
// three-stage Pythagorean Theorem example that can be found elsewhere.


`include "sqrt32.v";


module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);    /* verilator lint_save */ /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_restore */  /* verilator lint_off WIDTH */ /* verilator lint_off UNOPTFLAT */

   // Signal declarations
   logic [3:0] a_a1,
               a_a2,
               a_a3;
   logic [7:0] a_sq_a1,
               a_sq_a2;
   logic [3:0] b_a1,
               b_a2,
               b_a3;
   logic [7:0] b_sq_a1,
               b_sq_a2;
   logic [4:0] c_a3;
   logic [8:0] c_sq_a2,
               c_sq_a3;
   logic [31:0] r_a_a0,
                r_a_a1;
   logic [31:0] r_b_a0,
                r_b_a1;

   // Assign inputs (a/b) to a random value.
   // Verilog supports 32-bit randoms, and updates each time the statement is executed, so
   // we update on the clock edge then capture the 32-bit random through a flop, then downsize.
   // verilator lint_save
   // verilator lint_off WIDTH
   assign a_a1[3:0] = r_a_a1;
   assign b_a1[3:0] = r_b_a1;
   // verilator lint_restore
   assign r_a_a0[31:0] = $random() ^ {31'b0, clk};  // Assign on each clock edge.
   always_ff @(posedge clk) r_a_a1[31:0] <= r_a_a0[31:0];
   assign r_b_a0[31:0] = $random() ^ {31'b0, clk};
   always_ff @(posedge clk) r_b_a1[31:0] <= r_b_a0[31:0];



   // Pythagora's Theorem Pipeline Logic
   // Stage 1
   assign a_sq_a1[7:0] = a_a1[3:0] ** 2;
   assign b_sq_a1[7:0] = b_a1[3:0] ** 2;
   // Flop Stage 1 -> Stage 2
   always_ff @(posedge clk) a_sq_a2[7:0] <= a_sq_a1[7:0];
   always_ff @(posedge clk) b_sq_a2[7:0] <= b_sq_a1[7:0];
   // Stage 2
   assign c_sq_a2[8:0] = a_sq_a2 + b_sq_a2;
   // Flop Stage 2 -> Stage 3
   always_ff @(posedge clk) c_sq_a3[8:0] <= c_sq_a2[8:0];
   // Stage 3
   assign c_a3[4:0] = sqrt(c_sq_a3);


   // Flop to Stage 3 for printing
   always_ff @(posedge clk) a_a2[3:0] <= a_a1[3:0];
   always_ff @(posedge clk) a_a3[3:0] <= a_a2[3:0];
   always_ff @(posedge clk) b_a2[3:0] <= b_a1[3:0];
   always_ff @(posedge clk) b_a3[3:0] <= b_a2[3:0];
   // Print
   always_ff @(posedge clk) begin
      $display("sqrt((%2d ^ 2) + (%2d ^ 2)) = %2d", a_a3, b_a3, c_a3);
   end

   // Stop simulation.
   assign passed = cyc_cnt > 40;
endmodule
