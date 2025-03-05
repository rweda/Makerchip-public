\TLV_version 1b: tl-x.org
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

// This design computes a running average of a steady stream of incoming numbers.
// The most recent numbers are weighted most heavily.  It approximates a scheme
// where the new average is computed as:
//
//   avg = new_value * weight + avg#+1 * (1 - weight)
//
// This has the effect of "softening" jumps the incoming stream.
//
// The calculation is performed over three cycles,but must feedback to the
// next calculation within a cycle if implemented as above, so the scheme above
// is approximated with the following formula (performed each cycle, where old):
//
//   avg = (new_value + prev_new_value) * weight +
//         avg#+2                       * (1 - weight)
//
// Or, in a form that is friendlier to rounding error:
//
//   avg = (new_value + prev_new_value) * weight +
//         avg#+2 -
//         avg#+2 * weight
//
// We use fixed-point math, where weights are in 1/256ths (henceforth referred
// to as "parts").  We use hardcoded weights of:
//   weight = 72



/* verilator lint_off UNOPTFLAT */

module top(input logic clk, logic reset, output logic passed, output logic failed);    bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_vect[256:0]); assign RW_rand_vect[256+63:257] = RW_rand_vect[62:0];

\TLV

   // Stimulus
   |calc
      @-1
!        $reset = *reset;
      @0
         // Random input value.
         $rand_val[7:0] = *RW_rand_vect[0 + (0) % 257 +: 8];
         $val[7:0] = $reset ? 8'h80 : $rand_val;

   // DUT
   |calc
      @1
         // Sum previous three values:
         $sum[15:0] = {8'b0, $val} +
                      {8'b0, $val#+1};
      @2
         // Apply weights (in parts), to generate weighted terms (in parts).
         $weighted_sum[7:-8] = $sum[15:0]           * (16'd72 >> 1);  // >> 1 makes the sum an average.
         $weighted_avg[7:-16] = {8'b0, $avg#+2} * 16'd72;
      @3
         // Compute new average (in parts).
         $avg[7:-8] = $reset ? 16'h8000 :
                      $weighted_sum +
                      $avg#+2 -
                      $weighted_avg[7:-8];


   // Checking/Output
   |calc
      @0
         // Free-running cycle count.
         $CycCnt[15:0] = $reset ? 16'b0 : $CycCnt#+1 + 16'b1;
      @3
         // Print
         \SV_plus
            always_ff @(posedge clk) begin
               if (!$reset) begin
                  \$display("In: 0x%2h, Avg: 0x%2h.%2h", $val, $avg[7:0], $avg[-1:-8]);
               end
            end

         // Pass the test on cycle 40; fail on error conditions.
!        *passed = !$reset && $CycCnt > 16'd20;
         // Average should not become extreme.
!        *failed = !$reset && ($avg[7:6] != 2'b10) && ($avg[7:6] != 2'b01);

\SV
endmodule
