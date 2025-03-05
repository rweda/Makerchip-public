`line 2 "design.tlv" 0

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
`line 54 "design.tlv"

`include "design_gen.sv"

   // Stimulus
   //_|calc
      //_@-1
         assign CALC_reset_n1 = reset;
      //_@0
         // Choose random A / B, valid if A < B (and the pipeline's not busy or in reset).
         assign CALC_rand_a_a0[3:0] = RW_rand_vect[(0 + (0)) % 257 +: 4];
         assign CALC_rand_b_a0[3:0] = RW_rand_vect[(124 + (0)) % 257 +: 4];
         // $in_valid pulses for the first iteration of the calculation.
         assign CALC_in_valid_a0 = (CALC_rand_a_a0 < CALC_rand_b_a0) && (! CALC_calc_valid_a2 || CALC_last_iter_a2) && !CALC_reset_a0;
         assign CALC_odd_a0 = CALC_reset_a0 ? 1'b0 : ! CALC_odd_a1;
         //_?$calc_valid
            assign CALC_aa_in_a0[3:0] = CALC_in_valid_a0 ? CALC_rand_a_a0 : CALC_aa_in_a1[3:0];
            assign CALC_bb_in_a0[3:0] = CALC_in_valid_a0 ? CALC_rand_b_a0 : CALC_bb_in_a1[3:0];

   // DUT
   //_|calc
      //_@0
         // Valid iteration for this pipeline.
         assign CALC_calc_valid_a0 = CALC_reset_a0 ? 1'b0
                              : CALC_in_valid_a0 || (CALC_calc_valid_a2 && (CALC_iteration_a2 != 2'b11));
         // Track which iteration we're processing, 0-3.
         assign CALC_iteration_a0[1:0] = CALC_calc_valid_a2 ? (CALC_iteration_a2 + 2'b01) : 2'b0;

      // Main calculation.  Computes next hex digit (four bits) of the quotient (Q).
      //_?$calc_valid
         //_@0
            // Carry A and B from previous iteration.
            assign CALC_aa_a0[3:0] = CALC_in_valid_a0 ? CALC_aa_in_a0 : CALC_aa_a2;
            assign CALC_bb_a0[3:0] = CALC_in_valid_a0 ? CALC_bb_in_a0 : CALC_bb_a2;
         //_@1
            // Remainder for this iteration, so, A, R1, R2, R3.
            assign CALC_remainder_a1[3:0] = CALC_in_valid_a1 ? CALC_aa_a1 : CALC_next_remainder_a3[3:0];
            // The digit of the quotient, computed in this iteration (top 4 bits should be 0).
            assign CALC_quotient_digit_a1[7:0] = {CALC_remainder_a1[3:0], 4'b0} / {4'b0, CALC_bb_a1};
         //_@2
            // The next value of $remainder, so R1, R2, R3, R4.
            assign CALC_next_remainder_a2[7:0] = {CALC_remainder_a2[3:0], 4'b0} -
                                   ({4'b0, CALC_quotient_digit_a2[3:0]} * {4'b0, CALC_bb_a2[3:0]});
         //_@3
            // Accumulate $quotient_digit by shifting into $Quotient.
            // Need to accumulate two results since we can perform two interleaved computations.
            for (result = 0; result <= 1; result++) begin : L1_CALC_Result //_/result
               assign CALC_Result_quotient_a3[result][15:0] =
                  CALC_calc_valid_a3 && (result == CALC_odd_a3) ? {CALC_Result_quotient_a4[result][11:0], CALC_quotient_digit_a3[3:0]}
                                                             : CALC_Result_quotient_a4[result][15:0]; end
            assign CALC_quotient_a3[15:0] = CALC_Result_quotient_a3[CALC_odd_a3];



   // Checking/Output
   //_|calc
      //_@-1
         // Free-running cycle count.
         assign CALC_CycCnt_n2[15:0] = CALC_reset_n1 ? 16'b0 : CALC_CycCnt_n1 + 16'b1;
      // Checking
      //_@0
         assign CALC_last_iter_a0 = CALC_iteration_a0 == 2'b11;
      //_@1
         //_?$calc_valid
            assign w_CALC_Error1_a0 = CALC_remainder_a1[3:0] >= CALC_bb_a1[3:0];
            assign w_CALC_Error2_a0 = CALC_quotient_digit_a1[7:4] != 4'b0;
         // Full division, for comparison.
         assign CALC_orig_aa_a1[3:0] = CALC_aa_a7;
         assign CALC_orig_bb_a1[3:0] = CALC_bb_a7;
         //_?$last_iter
            assign CALC_full_quotient_a1[19:0] = {CALC_orig_aa_a1, 16'b0} / {16'b0, CALC_orig_bb_a1};
      //_@3
         // Comparison.
         //_?$last_iter
            assign w_CALC_Error3_a2 = CALC_full_quotient_a3 != {4'b0, CALC_quotient_a3};
      //_@3
         // Print
         /*SV_plus*/
            always_ff @(posedge clk) begin
               if (CALC_last_iter_a3) begin
                  $display("Cyc: %d, %d / %d = b0.%4h (0.%4h)", CALC_CycCnt_a3, CALC_orig_aa_a3, CALC_orig_bb_a3, CALC_quotient_a3, CALC_full_quotient_a3[15:0]);
               end
            end
      //_@4

         // Pass the test on cycle 40; fail on error conditions.
         assign passed = CALC_CycCnt_a4 > 16'd40;
         assign failed = CALC_Error1_a4 || CALC_Error2_a4 || CALC_Error3_a4;

      `line 54 "design.tlv"
      //_\end_source
      `line 143 "design.tlv"
           
 
//_\SV
endmodule
;

`line 3 "foo.tlv"
          


// Undefine macros defined by SandPiper (in "design_gen.sv").
`undef BOGUS_USE
