\TLV_version [\source run/gen/slide_flow/flow_tb.tlv] 1c: tl-x.org
\SV
   // SystemVerilog
   
   // A generic macro that instantiates a "distance" module,
   // providing clock, reset, and checking.  Since the
   // SystemVerilog module instantiation is not the focus of
   // this example, it is burried in a macro.
   // Focus on "design.tlv" to the right.
   //
   // Note that simulation reports "failure" because
   // design.tlv does not declare success.
   
   
// -------------------------------------------------------------------
// Expanded from instantiation: m4_top_module_inst(m4_name, m4_max_cycles)
//

module top_top();

logic clk, reset;      // Generated in this module for DUT.
logic passed, failed;  // Returned from DUT to this module.  Passed must assert before
                       //   max cycles, without failed having asserted.  Failed can be undriven.
logic [15:0] cyc_cnt;


// Instantiate main module.
top top (.*);


// Clock
initial begin
   clk = 1'b1;
   forever #5 clk = ~clk;
end


// Run
initial begin

   //`ifdef DUMP_ON
      $dumpfile("top.vcd");
      $dumpvars;
      $dumpon;
   //`endif

   reset = 1'b1;
   #55;
   reset = 1'b0;

   // Run

   cyc_cnt = '0;
   for (int cyc = 0; cyc < 100; cyc++) begin
      // Failed
      if (failed === 1'b1) begin
         FAILED: assert(1'b1) begin
            $display("Failed!!!  Error condition asserted.");
            $finish;
         end
      end

      // Success
      if (passed) begin
         SUCCESS: assert(1'b1) begin
            $display("Success!!!");
            $finish;
         end
      end

      #10;

      cyc_cnt++;
   end

   // Fail
   DIE: assert (1'b1) begin
      $error("Failed!!!  Test did not complete within m4_max_cycles time.");
      $finish;
   end

end

endmodule  // life_tb

// -------------------------------------------------------------------


