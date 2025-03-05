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



// This example accumulates distance traveled in a series of hops.
// Hops are presented as $aa and $bb, a forward distance (along the line of the
// previous hop), and a sideways distance to
// the next target location.  If a new "skip-to" hop arrives next (and it must arrive
// precisely four cycles later), this hop's target is skipped and replaced by the
// destination provided in the skip-to hop (which is given relative to this target).
// The next hop (or skip-hop) is given relative to the corrected hop.

// The incoming stream of hops from the "Stimulus" code in this file are
// passed through a FIFO to be delivered into the pipeline.

module distance(input logic clk, logic reset, output logic passed, output logic failed);    bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_vect[256:0]); assign RW_rand_vect[256+63:257] = RW_rand_vect[62:0];

\TLV

   |reset
      @-1
         // Create pipesignal out of reset module input.
!        $reset = *reset;

   // Stimulus
   |in
      @0
         $rand_valid[0:0] = *RW_rand_vect[0 + (0) % 257 +: 1];
         $valid = $rand_valid && !$blocked && !>top|reset$reset#+0;
         $trans_avail = $valid;
         $trans_valid = $trans_avail;
         $rand_skip_to[0:0] = *RW_rand_vect[124 + (0) % 257 +: 1];
         $skip_to = $valid && $valid#+1 && $rand_skip_to;
              // Only if last cycle generated a valid, so we know there's a hop to chase.
         ?$valid
            $rand_aa[14:0] = *RW_rand_vect[248 + (0) % 257 +: 15];
            $rand_bb[14:0] = *RW_rand_vect[115 + (0) % 257 +: 15];
            $aa[31:0] = {17'b0, $rand_aa};
            $bb[31:0] = {17'b0, $rand_bb};
   
   // Input FIFO
   \source ./m4/1b/pipeflow_tlv.m4 414   // Instantiated from stdin, 69 as: m4+flop_fifo(top, in, 0, calc, 0, >top|reset$reset, 0, 5)
      //|default
      //   @0
      \SV_plus
         localparam bit [\$clog2((5)+1)-1:0] full_mark = 5;
      
      // FIFO Instantiation
      
      // Hierarchy declarations
      |in
         >entry[(5)-1:0]
      |calc
         >entry[(5)-1:0]
      
      // Hierarchy
      |in
         @0
            $reset = >top|reset$reset#+0;
            $out_blocked = >top|calc$blocked#+0;
            $blocked = $full#+1 && $out_blocked;
            `BOGUS_USE($blocked)   // Not required to be consumed elsewhere.
            $would_bypass = $empty#+1;
            $bypass = $would_bypass && ! $out_blocked;
            $push = $trans_valid && ! $bypass;
            $grow   =   $trans_valid &&   $out_blocked;
            $shrink = ! $empty#+1 && ! $trans_avail && ! $out_blocked;
            $valid_count[\$clog2((5)+1)-1:0] = $reset ? '0
                                                        : $valid_count#+1 + (
                                                             $grow   ? { {(\$clog2((5)+1)-1){1'b0}}, 1'b1} :
                                                             $shrink ? '1
                                                                     : '0
                                                          );
            // At least 2 valid entries.
            //$two_valid = | $ValidCount[m4_counter_width-1:1];
            // but logic depth minimized by taking advantage of prev count >= 4.
            $two_valid = | $valid_count#+1[\$clog2((5)+1)-1:2] || | $valid_count[2:1];
            // These are an optimization of the commented block below to operate on vectors, rather than bits.
            // TODO: Keep optimizing...
            {>entry[*]$$prev_entry_was_tail} = {>entry[*]$reconstructed_is_tail#+1\[3:0], >entry[4]$reconstructed_is_tail#+1} /* circular << */;
            {>entry[*]$$push} = {5{$push}} & >entry[*]$prev_entry_was_tail;
            >entry[*]
               // Replaced with optimized versions above:
               // $prev_entry_was_tail = >entry[(entry+(m4_depth)-1)%(m4_depth)]$reconstructed_is_tail#+1;
               // $push = |m4_in_pipe$push && $prev_entry_was_tail;
               $valid = ($reconstructed_valid#+1 && ! >top|calc>entry$pop#+0) || $push;
               $is_tail = |in$trans_valid ? $prev_entry_was_tail  // shift tail
                                                  : $reconstructed_is_tail#+1;  // retain tail
               $State = |in$reset ? 1'b0
                                          : $valid && ! (|in$two_valid && $is_tail);
         @1
            $empty = ! $two_valid && ! $valid_count[0];
            $full = ($valid_count == full_mark);  // Could optimize for power-of-two depth.
         >entry[*]
            @1
               $prev_entry_state = >entry[(entry+(5)-1)%(5)]$State;
               $next_entry_state = >entry[(entry+1)%(5)]$State;
               $reconstructed_is_tail = (  >top|in$two_valid && (!$State && $prev_entry_state)) ||
                                        (! >top|in$two_valid && (!$next_entry_state && $State)) ||
                                        (|in$empty && (entry == 0));  // need a tail when empty for push
               $is_head = $State && ! $prev_entry_state;
               $reconstructed_valid = $State || (>top|in$two_valid && $prev_entry_state);
      // Write data
      |in
         @0
            >entry[*]
               //?$push
               //   $aNY = |m4_in_pipe['']m4_trans_hier$ANY;
               $ANY = $push ? >top|in$ANY : $ANY#+1 /* RETAIN */;
      // Read data
      |calc
         @0
            //$pop  = ! >m4_top|m4_in_pipe$empty#m4_align(m4_in_at + 1, m4_out_at) && ! $blocked;
            >entry[*]
               $is_head = >top|in>entry$is_head#+1;
               $pop  = $is_head && ! |calc$blocked;
               >read_masked
                  $ANY = >entry$is_head ? >top|in>entry$ANY#+1 /* $aNY */ : '0;
               >accum
                  $ANY = ((entry == 0) ? '0 : >entry[(entry+(5)-1)%(5)]>accum$ANY) |
                             >entry>read_masked$ANY;
            >head
               $trans_avail = |calc$trans_avail;
               ?$trans_avail
                  $ANY = >top|calc>entry[(5)-1]>accum$ANY;
      
      // Bypass
      |calc
         @0
            // Available output.  Sometimes it's necessary to know what would be coming to determined
            // if it's blocked.  This can be used externally in that case.
            >fifo_head
               $trans_avail = |calc$trans_avail;
               ?$trans_avail
                  
                  $ANY = >top|in$would_bypass#+0
                               ? >top|in$ANY#+0
                               : |calc>head$ANY;
            $trans_avail = ! >top|in$would_bypass#+0 || >top|in$trans_avail#+0;
            $trans_valid = $trans_avail && ! $blocked;
            ?$trans_valid
               $ANY = >fifo_head$ANY;
                            
                            
                            
      /* Alternate code for pointer indexing.  Replaces $ANY expression above.
      
      // Hierarchy
      |in
         >entry2[(5)-1:0]
      
      // Head/Tail ptrs.
      |in
         @0
            $NextWrPtr[\$clog2(5)-1:0] =
                $reset       ? '0 :
                $trans_valid ? ($NextWrPtr#+1 == (5 - 1))
                                 ? '0
                                 : $NextWrPtr#+1 + {{(\$clog2(5)-1){1'b0}}, 1'b1} :
                               $RETAIN;
      |calc
         @0
            $NextRdPtr[\$clog2(5)-1:0] =
                >top|in$reset#+0
                             ? '0 :
                $trans_valid ? ($NextRdPtr#+1 == (5 - 1))
                                 ? '0
                                 : $NextRdPtr#+1 + {{(\$clog2(5)-1){1'b0}}, 1'b1} :
                               $RETAIN;
      // Write FIFO
      |in
         @0
            $dummy = '0;
            ?$trans_valid
               // This doesn't work because SV complains for FIFOs in replicated context that
               // there are multiple procedures that assign the signals.
               // Array writes can be done in an SV module.
               // The only long-term resolutions are support for module generation and use
               // signals declared within for loops with cross-hierarchy references in SV.
               // TODO: To make a simulation-efficient FIFO, use DesignWare.
               {>entry2[$NextWrPtr#+1]$$ANY} = $ANY;
      // Read FIFO
      |calc
         @0
            >read2
               $trans_valid = |calc$trans_valid;
               ?$trans_valid
                  $ANY = >top|in>entry2[|calc$NextRdPtr#+1]$ANY#+0;
               `BOGUS_USE($dummy)
            ?$trans_valid
               $ANY = >read2$ANY;
      */
   \end_source

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
