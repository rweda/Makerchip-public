\m4_TLV_version 1b: tl-x.org
\SV
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

m4_top_module_def(dut);
// Expands to:
// module example(
//    input logic clk, logic reset,  // Provided by default "testbench".
//    output logic passed            // Indicates success to default "testbench".
// );
// m4_use_rand(clk, reset);

// Other testbench functionality, such as synthesizable stimulus can be provided
// here using TLV to avoid transitions to SV signals if desired.

\TLV

   // Some starting-point code:
   |default   // Pipeline
      @0         // Stage

         // Create pipesignal out of reset module input.
!        $reset = *reset;

         // Free-running cycle count.
         $CycCnt[15:0] = $reset ? 16'b0 : $CycCnt#+1 + 16'b1;

         // Randomize whether there is a valid transaction this cycle.
         m4_rand($valid, 0, 0)

         // Provide a random byte of $data on $valid transactions.
         ?$valid
            m4_rand($data, 7, 0)

      @1
         `BOGUS_USE($data)
         // Pass the test on cycle 20.
!        *passed = $CycCnt > 16'd20;
\SV
endmodule
