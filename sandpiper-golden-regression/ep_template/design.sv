`line 2 "design.m4out.tlv" 0

/*
Copyright (c) 2015, Steven F. Hoover

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * The name of Steven F. Hoover
      may not be used to endorse or promote products derived from this software
      without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

module dut(input logic clk, logic reset, output logic passed, output logic failed);    bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_vect[256:0]); assign RW_rand_vect[256+63:257] = RW_rand_vect[62:0];;
// Expands to:
// module example(
//    input logic clk, logic reset,  // Provided by default "testbench".
//    output logic passed            // Indicates success to default "testbench".
// );
// m4_use_rand(clk, reset);

// Other testbench functionality, such as synthesizable stimulus can be provided
// here using TLV to avoid transitions to SV signals if desired.

`include "design_gen.sv"

   // Some starting-point code:
   //_|default   // Pipeline
      //_@0         // Stage

         // Create pipesignal out of reset module input.
         assign DEFAULT_reset_a0 = reset;

         // Free-running cycle count.
         assign DEFAULT_CycCnt_a0[15:0] = DEFAULT_reset_a0 ? 16'b0 : DEFAULT_CycCnt_a1 + 16'b1;

         // Randomize whether there is a valid transaction this cycle.
         assign DEFAULT_valid_a0[0:0] = RW_rand_vect[0 + (0) % 257 +: 1];

         // Provide a random byte of $data on $valid transactions.
         //_?$valid
            assign w_DEFAULT_data_a0[7:0] = RW_rand_vect[124 + (0) % 257 +: 8];

      //_@1
         `BOGUS_USE(DEFAULT_data_a1)
         // Pass the test on cycle 20.
         assign passed = DEFAULT_CycCnt_a1 > 16'd20;
//_\SV
endmodule


// Undefine macros defined by SandPiper (in "design_gen.sv").
`undef BOGUS_USE
`undef WHEN
