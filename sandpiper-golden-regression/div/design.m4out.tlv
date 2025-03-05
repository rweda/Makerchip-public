\TLV_version [\source run/gen/div/design.tlv] 1d: tl-x.org
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

// This design computes the quotient Q = A / B, where A and B are 1-digit hexadecimal
// numbers that form a proper fraction (A < B). Q is computed to four fractional digits
// using long division, computing one digit of Q every two cycles. Calculations
// Utilize the pipeline on alternate cycles and are permitted to interleave.
//
//         A R1 R2 R3
//       / B  B  B  B
//        -- -- -- --
//      . Q1 Q2 Q3 Q4
//   ---------------
// B ) A. 0  0  0  0
//   - Q1*B
//    -----
//       R1  0
//      - Q2*B
//       -----
//          R2  0
//         - Q3*B
//

/* verilator lint_off UNOPTFLAT */
module div(input logic clk, input logic reset, input logic [15:0] cyc_cnt, output logic passed, output logic failed);    /* verilator lint_save */ /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_restore */
\source run/gen/div/design.tlv 53

\TLV

   // Stimulus
   |calc
      @-1
!        $reset = *reset;
      @0
         // Choose random A / B, valid if A < B (and the pipeline's not busy or in reset).
         $rand_a[3:0] = *RW_rand_vect[(0 + (0)) % 257 +: 4];
         $rand_b[3:0] = *RW_rand_vect[(124 + (0)) % 257 +: 4];
         // $in_valid pulses for the first iteration of the calculation.
         $in_valid = ($rand_a < $rand_b) && (! >>2$calc_valid || >>2$last_iter) && !$reset;
         $odd = $reset ? 1'b0 : ! >>1$odd;
         ?$calc_valid
            $aa_in[3:0] = $in_valid ? $rand_a : $RETAIN;
            $bb_in[3:0] = $in_valid ? $rand_b : $RETAIN;

   // DUT
   |calc
      @0
         // Valid iteration for this pipeline.
         $calc_valid = $reset ? 1'b0
                              : $in_valid || (>>2$calc_valid && (>>2$iteration != 2'b11));
         // Track which iteration we're processing, 0-3.
         $iteration[1:0] = >>2$calc_valid ? (>>2$iteration + 2'b01) : 2'b0;

      // Main calculation.  Computes next hex digit (four bits) of the quotient (Q).
      ?$calc_valid
         @0
            // Carry A and B from previous iteration.
            $aa[3:0] = $in_valid ? $aa_in : >>2$aa;
            $bb[3:0] = $in_valid ? $bb_in : >>2$bb;
         @1
            // Remainder for this iteration, so, A, R1, R2, R3.
            $remainder[3:0] = $in_valid ? $aa : >>2$next_remainder[3:0];
            // The digit of the quotient, computed in this iteration (top 4 bits should be 0).
            $quotient_digit[7:0] = {$remainder[3:0], 4'b0} / {4'b0, $bb};
         @2
            // The next value of $remainder, so R1, R2, R3, R4.
            $next_remainder[7:0] = {$remainder[3:0], 4'b0} -
                                   ({4'b0, $quotient_digit[3:0]} * {4'b0, $bb[3:0]});
         @3
            // Accumulate $quotient_digit by shifting into $Quotient.
            // Need to accumulate two results since we can perform two interleaved computations.
            /result[1:0]
               $quotient[15:0] =
                  |calc$calc_valid && (#result == |calc$odd) ? {>>1$quotient[11:0], |calc$quotient_digit[3:0]}
                                                             : $RETAIN;
            $quotient[15:0] = /result[$odd]$quotient;



   // Checking/Output
   |calc
      @-1
         // Free-running cycle count.
         $CycCnt[15:0] <= $reset ? 16'b0 : $CycCnt + 16'b1;
      // Checking
      @0
         $last_iter = $iteration == 2'b11;
      @1
         ?$calc_valid
            $Error1 <= $remainder[3:0] >= $bb[3:0];
            $Error2 <= $quotient_digit[7:4] != 4'b0;
         // Full division, for comparison.
         $orig_aa[3:0] = >>6$aa;
         $orig_bb[3:0] = >>6$bb;
         ?$last_iter
            $full_quotient[19:0] = {$orig_aa, 16'b0} / {16'b0, $orig_bb};
      @3
         // Comparison.
         ?$last_iter
            $Error3 <= $full_quotient != {4'b0, $quotient};
      @3
         // Print
         \SV_plus
            always_ff @(posedge clk) begin
               if ($last_iter) begin
                  \$display("Cyc: \%d, \%d / \%d = b0.\%4h (0.\%4h)", $CycCnt, $orig_aa, $orig_bb, $quotient, $full_quotient[15:0]);
               end
            end
      @4

         // Pass the test on cycle 40; fail on error conditions.
!        *passed = $CycCnt > 16'd40;
!        *failed = $Error1 || $Error2 || $Error3;

      \source run/gen/div/design.tlv 53   // Instantiated from run/gen/div/design.tlv, 142 as: m4+foo()
      \end_source
           
 
\SV
endmodule
;

\source foo.tlv 2
          
