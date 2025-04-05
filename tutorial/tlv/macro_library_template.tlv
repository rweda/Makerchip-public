\m5_TLV_version 1d: tl-x.org
\SV
   /*
   <Your permissive open-source license here>
   */

\m5
   / A starting template/example for developing a TL-Verilog library file
   / for use in the Makerchip IDE.
   /
   / This file contains:
   /   o a description of its use from a Verilog/SystemVerilog project
   /   o fib(): A tiny example macro definition
   /   o a dirt-simple example Makerchip-based testbench for that macro
   /
   / Makerchip can be used for rapid path-clearing of the macro logic.
   /
   / The macro defined in this library can be used outside of Makerchip in a file of a (System)Verilog project by
   / updating the (System)Verilog files as illustrated below to include TL-Verilog file structure, including:
   /   o the first five lines below identifying language and library versions to use/include
   /   o instantiating the macro from within in a "\TLV" region and wiring it to (System)Verilog signals.
   /
   / ------------------------------------
   / \m5_TLV_version 1d: tl-x.org       // Identifies the file format with required link to docs, enabling graceful upgrades.
   / \m5                                // A region for M5 macro preprocessor definitions.
   /    use(m5-1.0)                     // Includes the main M5 library (though not actually used here), again versioned.
   / \SV                                // A region for (System)Verilog code.
   / m4_include_lib(['this_file.tlv'])  // Include this library file (using an M4 mechanism that will be replaced by an M5 mechanism).
   / 
   / // Preexisting (System)Verilog code, in this case just a module definition
   / module fib(input logic clk, input logic reset, input logic run, output logic[31:0] val);
   / // We add to the (System)Verilog the instantiation of our macro in "|TLV" context that recognizes
   / // TL-Verilog syntax, and we connect its interface signals.
   / \TLV
   /    $run = *run;       // Connect SV "run" signal to TLV "$run" macro input.
   /    $reset = *reset;   // Connect SV "reset" signal to TLV "$reset" macro input.
   /    m5+fib()           // Instantiate our library macro.
   /    *val = $val;       // Connect SV "val" signal to TLV "$val" macro input.
   / \SV
   /    endmodule
   / -------------------------------------
   /
   / This above file can be converted to Verilog using SandPiper(TM) (locally or as a free service:
   /   http://redwoodeda.com/products).



\m5
   use(m5-1.0)   // Again, not actually used here, but generally useful.

//----------------------------
// Our Library
// A TLV macro definition, in this case, a Fibonacci sequence generator.

\TLV fib()
   $val[31:0] = ($reset || ! $run) ? 1 : >>1$val + >>2$val;




//----------------------------
// Self-testing testbench for this library for use in Makerchip.

\SV
   // Declare the Verilog module interface by which Makerchip and the testbench control simulation (using macro).
   m5_makerchip_module   // Compile within Makerchip to see expanded module definition.

// The testbench to provide stimulus and checking.
\TLV
   // Stimulus (drive inputs).
   $reset = *reset;
   $run = 1'b1;
   // Instantiate the DUT
   m5+fib()
   // Check outputs.
   *passed = *cyc_cnt == 20 && $val == 32'h452f; // Test for expected output after 20 cycles.
   *failed = *cyc_cnt > 40;                      // Or fail after 40.

\SV
   endmodule
