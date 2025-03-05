\TLV_version 1b --stats: tl-x.org
\SV
/*
Copyright (c) 2014, Intel Corporation

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Intel Corporation nor the names of its contributors
      may be used to endorse or promote products derived from this software
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

`include "ring.vh"



module ring (
   // Primary inputs
   input logic clk,
   input logic reset,

   input logic [7:0] data_in [RING_STOPS],
   input logic [RING_STOPS_WIDTH-1:0] dest_in [RING_STOPS],
   input logic valid_in [RING_STOPS],

   // Primary outputs
   output logic accepted [RING_STOPS],
   output logic [7:0] data_out [RING_STOPS],
   output logic valid_out [RING_STOPS]
);

\TLV
   // Hierarchy
   >stop[RING_STOPS-1:0]
   
   // Reset
   |reset
      @0
         $reset = *reset;

   // FIFOs
   >stop[*]
      // Inputs
      |inpipe
         @0
            $data[7:0] = data_in[stop];
            $parity = 1'b0;
            $dest[RING_STOPS_WIDTH-1:0] = dest_in[stop];
            $trans_avail = !>top|reset$reset#+2 && valid_in[stop];
         @1
            $trans_valid = $trans_avail && ! $blocked;

      // FIFOs
      \source ./m4/1b/pipeflow_tlv.m4 414   // Instantiated from stdin, 71 as: m4+flop_fifo(stop, inpipe, 1, fo, 0, >top|reset$reset, 1, 6)
         //|default
         //   @0
         \SV_plus
            localparam bit [\$clog2((6)+1)-1:0] full_mark = 6;
         
         // FIFO Instantiation
         
         // Hierarchy declarations
         |inpipe
            >entry[(6)-1:0]
         |fo
            >entry[(6)-1:0]
         
         // Hierarchy
         |inpipe
            @1
               $reset = >top|reset$reset#+0;
               $out_blocked = >stop|fo$blocked#-1;
               $blocked = $full#+1 && $out_blocked;
               `BOGUS_USE($blocked)   // Not required to be consumed elsewhere.
               $would_bypass = $empty#+1;
               $bypass = $would_bypass && ! $out_blocked;
               $push = $trans_valid && ! $bypass;
               $grow   =   $trans_valid &&   $out_blocked;
               $shrink = ! $empty#+1 && ! $trans_avail && ! $out_blocked;
               $valid_count[\$clog2((6)+1)-1:0] = $reset ? '0
                                                           : $valid_count#+1 + (
                                                                $grow   ? { {(\$clog2((6)+1)-1){1'b0}}, 1'b1} :
                                                                $shrink ? '1
                                                                        : '0
                                                             );
               // At least 2 valid entries.
               //$two_valid = | $ValidCount[m4_counter_width-1:1];
               // but logic depth minimized by taking advantage of prev count >= 4.
               $two_valid = | $valid_count#+1[\$clog2((6)+1)-1:2] || | $valid_count[2:1];
               // These are an optimization of the commented block below to operate on vectors, rather than bits.
               // TODO: Keep optimizing...
               {>entry[*]$$prev_entry_was_tail} = {>entry[*]$reconstructed_is_tail#+1\[4:0], >entry[5]$reconstructed_is_tail#+1} /* circular << */;
               {>entry[*]$$push} = {6{$push}} & >entry[*]$prev_entry_was_tail;
               >entry[*]
                  // Replaced with optimized versions above:
                  // $prev_entry_was_tail = >entry[(entry+(m4_depth)-1)%(m4_depth)]$reconstructed_is_tail#+1;
                  // $push = |m4_in_pipe$push && $prev_entry_was_tail;
                  $valid = ($reconstructed_valid#+1 && ! >stop|fo>entry$pop#-1) || $push;
                  $is_tail = |inpipe$trans_valid ? $prev_entry_was_tail  // shift tail
                                                     : $reconstructed_is_tail#+1;  // retain tail
                  $State = |inpipe$reset ? 1'b0
                                             : $valid && ! (|inpipe$two_valid && $is_tail);
            @2
               $empty = ! $two_valid && ! $valid_count[0];
               $full = ($valid_count == full_mark);  // Could optimize for power-of-two depth.
            >entry[*]
               @2
                  $prev_entry_state = >entry[(entry+(6)-1)%(6)]$State;
                  $next_entry_state = >entry[(entry+1)%(6)]$State;
                  $reconstructed_is_tail = (  >stop|inpipe$two_valid && (!$State && $prev_entry_state)) ||
                                           (! >stop|inpipe$two_valid && (!$next_entry_state && $State)) ||
                                           (|inpipe$empty && (entry == 0));  // need a tail when empty for push
                  $is_head = $State && ! $prev_entry_state;
                  $reconstructed_valid = $State || (>stop|inpipe$two_valid && $prev_entry_state);
         // Write data
         |inpipe
            @1
               >entry[*]
                  //?$push
                  //   $aNY = |m4_in_pipe['']m4_trans_hier$ANY;
                  $ANY = $push ? >stop|inpipe$ANY : $ANY#+1 /* RETAIN */;
         // Read data
         |fo
            @0
               //$pop  = ! >m4_top|m4_in_pipe$empty#m4_align(m4_in_at + 1, m4_out_at) && ! $blocked;
               >entry[*]
                  $is_head = >stop|inpipe>entry$is_head#+2;
                  $pop  = $is_head && ! |fo$blocked;
                  >read_masked
                     $ANY = >entry$is_head ? >stop|inpipe>entry$ANY#+2 /* $aNY */ : '0;
                  >accum
                     $ANY = ((entry == 0) ? '0 : >entry[(entry+(6)-1)%(6)]>accum$ANY) |
                                >entry>read_masked$ANY;
               >head
                  $trans_avail = |fo$trans_avail;
                  ?$trans_avail
                     $ANY = >stop|fo>entry[(6)-1]>accum$ANY;
         
         // Bypass
         |fo
            @0
               // Available output.  Sometimes it's necessary to know what would be coming to determined
               // if it's blocked.  This can be used externally in that case.
               >fifo_head
                  $trans_avail = |fo$trans_avail;
                  ?$trans_avail
                     
                     $ANY = >stop|inpipe$would_bypass#+1
                                  ? >stop|inpipe$ANY#+1
                                  : |fo>head$ANY;
               $trans_avail = ! >stop|inpipe$would_bypass#+1 || >stop|inpipe$trans_avail#+1;
               $trans_valid = $trans_avail && ! $blocked;
               ?$trans_valid
                  $ANY = >fifo_head$ANY;
                               
                               
                               
         /* Alternate code for pointer indexing.  Replaces $ANY expression above.
         
         // Hierarchy
         |inpipe
            >entry2[(6)-1:0]
         
         // Head/Tail ptrs.
         |inpipe
            @1
               $NextWrPtr[\$clog2(6)-1:0] =
                   $reset       ? '0 :
                   $trans_valid ? ($NextWrPtr#+1 == (6 - 1))
                                    ? '0
                                    : $NextWrPtr#+1 + {{(\$clog2(6)-1){1'b0}}, 1'b1} :
                                  $RETAIN;
         |fo
            @0
               $NextRdPtr[\$clog2(6)-1:0] =
                   >stop|inpipe$reset#+1
                                ? '0 :
                   $trans_valid ? ($NextRdPtr#+1 == (6 - 1))
                                    ? '0
                                    : $NextRdPtr#+1 + {{(\$clog2(6)-1){1'b0}}, 1'b1} :
                                  $RETAIN;
         // Write FIFO
         |inpipe
            @1
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
         |fo
            @0
               >read2
                  $trans_valid = |fo$trans_valid;
                  ?$trans_valid
                     $ANY = >stop|inpipe>entry2[|fo$NextRdPtr#+1]$ANY#+1;
                  `BOGUS_USE($dummy)
               ?$trans_valid
                  $ANY = >read2$ANY;
         */
      \end_source

      // Outputs
      |inpipe
         @1
            *accepted[stop] = $trans_valid;
      |outpipe
         @2
            *data_out[stop] = $data;
            `BOGUS_USE($parity)
            *valid_out[stop] = $trans_valid;

   // Instantiate the ring.
   \source ./m4/1b/pipeflow_tlv.m4 642   // Instantiated from stdin, 84 as: m4+simple_ring(stop, fo, 0, outpipe, 0, >top|reset$reset, 1)
      
      // Logic
      >stop[*]
         //|default
         //   @0
         \SV_plus
            int prev_hop = (stop + RING_STOPS - 1) % RING_STOPS;
         |fo
            @0
               $blocked = >stop|rg$passed_on#+0;
         |rg
            @0
               $passed_on = >stop[prev_hop]|rg$pass_on#+1;
               $valid = ! >top|reset$reset#+1 &&
                        ($passed_on || >stop|fo$trans_avail#+0);
               $pass_on = $valid && ! >stop|outpipe$trans_valid#+0;
               $dest[RING_STOPS_WIDTH-1:0] =
                  $passed_on
                     ? >stop[prev_hop]|rg$dest#+1
                     : >stop|fo$dest#+0;
            @1
               ?$valid
                  $ANY =
                     $passed_on
                        ? >stop[prev_hop]|rg$ANY#+1
                        : >stop|fo$ANY#+0;
         |outpipe
            // Ring out
            @0
               $trans_avail = >stop|rg$valid#+0 && (>stop|rg$dest#+0 == stop);
               $blocked = 1'b0;
               $trans_valid = $trans_avail && ! $blocked;
            ?$trans_valid
               @1
                  $ANY = >stop|rg$ANY#+0;
   \end_source

\SV

endmodule
