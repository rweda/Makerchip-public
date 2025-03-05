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

m4_include(['pipeflow_tlv.m4'])

// This example accumulates distance traveled in a series of hops.
// Hops are presented as $aa and $bb, a forward distance (along the line of the
// previous hop), and a sideways distance to
// the next target location.  If a new "skip-to" hop arrives next (and it must arrive
// precisely four cycles later), this hop's target is skipped and replaced by the
// destination provided in the skip-to hop (which is given relative to this target).
// The next hop (or skip-hop) is given relative to the corrected hop.

// The incoming stream of hops from the "Stimulus" code in this file are
// passed through a FIFO to be delivered into the pipeline.

m4_top_module_def(distance)

\TLV

   |reset
      @-1
         // Create pipesignal out of reset module input.
!        $reset = *reset;

   // Stimulus
   |in
      @0
         m4_rand($rand_valid, 0, 0)
         $valid = $rand_valid && !$blocked && !>top|reset$reset#+0;
         $trans_avail = $valid;
         $trans_valid = $trans_avail;
         m4_rand($rand_skip_to, 0,0)
         $skip_to = $valid && $valid#+1 && $rand_skip_to;
              // Only if last cycle generated a valid, so we know there's a hop to chase.
         ?$valid
            m4_rand($rand_aa, 14, 0)
            m4_rand($rand_bb, 14, 0)
            $aa[31:0] = {17'b0, $rand_aa};
            $bb[31:0] = {17'b0, $rand_bb};
   
   // Input FIFO
   m4+flop_fifo(top, in, 0, calc, 0, >top|reset$reset, 0, 5)

   |calc
      @0
         // Block corrections for 3 cycles.
         $blocked = ($trans_avail ? >fifo_head$skip_to : 1'b1) && ($valid#+1 || $valid#+2 || $valid#+3); 
         $valid = $trans_valid;
         $reset = >top|reset$reset#+0;
         $valid_or_reset = $valid || $reset;
      ?$valid
         // DUT
         @0
            $corrected_aa[31:0] = $skip_to ? ($aa + $cc#+4) : $aa;
         @++
            $aa_squared[31:0] = $corrected_aa * $corrected_aa;
            $bb_squared[31:0] = $bb * $bb;
         @+=1
            $cc_squared[31:0] = $aa_squared + $bb_squared;
         @3
            $cc[31:0] = \$sqrt($cc_squared);
         @4
            $tot_incr[31:0] = $TotDist#+1 + $cc;
      ?$valid_or_reset
         @4
            $TotDist[31:0] =
                  $reset                            ? 32'b0     :  // reset
                  !($valid#-4 ? $skip_to#-4 : 1'b0) ? $tot_incr :  // add $cc
                                      $RETAIN;                     // retain


         // Output.
      @5
         \SV_plus
            always_ff @(posedge clk) begin
               if ($valid) begin
                  \$display("Cyc %d:\\n  \$skip_to: %h\\n  \$aa: 0x%h\\n  \$bb: 0x%h\\n  \$cc: 0x%h\\n  \$TotDist: 0x%h\\n", $CycCnt, $skip_to, $aa, $bb, $cc, $TotDist);
               end
            end

         ?$valid
            // Checking
            // $cc cannot be less than either $corrected_aa or $bb, and
            // $cc cannot be greater than $corrected_aa + $bb.
            $too_big = $cc > ($corrected_aa + $bb);
            $too_small = ($cc < $corrected_aa) || ($cc < $bb);

!        *failed = $valid ? $too_big || $too_small : 1'b0;

      @-1
         // Free-running cycle count.
         $CycCnt[15:0] = >top|reset$reset#+0 ? 16'b0 : $CycCnt#+1 + 16'b1;

      @1
         // Pass the test on cycle 20.
!        *passed = $CycCnt > 16'd20;
\SV
endmodule
