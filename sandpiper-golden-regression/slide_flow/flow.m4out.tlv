\TLV_version [\source run/gen/slide_flow/flow.tlv] 1c: tl-x.org
\SV
/*
Copyright (c) 2018, Steve Hoover
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module top(input logic clk, input logic reset, input logic [15:0] cyc_cnt, output logic passed, output logic failed);    /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_on UNOPTFLAT */
//m4_makerchip_module()
/* verilator lint_off UNOPTFLAT */  // Probably want to make this a default in Makerchip. See what happens when uprev'ed to 1d.


parameter RING_STOPS = 4;

parameter RING_STOPS_WIDTH = 2;  //$clog2(RING_STOPS); // roundup(log2(RING_STOPS))

parameter PACKET_SIZE = 16;

\TLV

   // testbench
   >tb
      |count
         @0
            %next$CycCount[15:0] = >top|default%+1$reset ? 16'b0 :
                                                           $CycCount + 1;
            \SV_plus
               always_ff @(posedge clk) begin
                  \$display("Cycle: %0d", $CycCount);
               end
      >ring_stop[RING_STOPS-1:0]
         // STIMULUS
         |send
            @0
               $valid_in = >tb|count%+0$CycCount == 3;
               ?$valid_in
                  >gen_trans
                     $sender[RING_STOPS_WIDTH-1:0] = ring_stop;
                     //m4_rand($size, M4_PACKET_SIZE-1, 0, ring_stop) // unused
                     $dest_tmp[2-1:0] = *RW_rand_vect[(0 + (ring_stop)) % 257 +: 2];
                     /* verilator lint_off WIDTH */
                     $dest[RING_STOPS_WIDTH-1:0] = ($dest_tmp + RING_STOPS) % RING_STOPS;
                     /* verilator lint_on WIDTH */
                     //$dest[RING_STOPS_WIDTH-1:0] = ring_stop;
                     //$packet_valid = ring_stop == 0 ? 1'b1 : 1'b0; // valid for only first ring_stop - unused
               $trans_valid = $valid_in || >ring_stop|receive%+0$request;
               ?$trans_valid
                  >trans_out
                     $ANY = >ring_stop|receive%+0$request ? >ring_stop|receive>trans%+0$ANY :
                                                           |send>gen_trans%+0$ANY;
                     
                     \SV_plus
                        always_ff @(posedge clk) begin
                           \$display("\|send[%0d]", ring_stop);
                           \$display("Sender: %0d, Destination: %0d", $sender, $dest);
                        end
                     
         |receive
            @0
               $reset = >top|default%+1$reset;
               $trans_valid = >top>ring_stop>pipe2|fifo2_out%+1$trans_valid;
               $request = $trans_valid && >trans%+0$sender != ring_stop;
               $received = $trans_valid && >trans%+0$sender == ring_stop;
               %next$NumPackets[PACKET_SIZE-1:0] = $reset                      ? '0 :
                                                   >ring_stop|send%+0$valid_in ? $NumPackets + 1 :
                                                   $request                    ? $NumPackets :
                                                   $received                   ? $NumPackets - 1 :
                                                                                 $NumPackets;
               ?$trans_valid
                  >trans
                     $ANY = >top>ring_stop>pipe2|fifo2_out>trans%+1$ANY;
                     $dest[RING_STOPS_WIDTH-1:0] = |receive%+0$request ? $sender : $dest;
      |pass
         @0
            $reset = >top|default%+1$reset;
            $packets[RING_STOPS*PACKET_SIZE-1:0] = >tb>ring_stop[*]|receive%+0$NumPackets;
            *passed = !$reset && ($packets == '0) && (>tb|count%+0$CycCount > 3);
   
   // Reset as a pipesignal.
   |default
      @0
!        $reset = *reset;

   // Ring
   >ring_stop[RING_STOPS-1:0]
      |ring_in
         @0
            $reset = >top|default%+1$reset;
            // transaction available if not reset and FIFO has valid transaction
            // and packet's destination is not the same as ring_stop
            $trans_avail = ! $reset && >ring_stop>stall_pipe|fifo_out%+1$trans_valid &&
                           >ring_stop>stall_pipe|fifo_out>trans%+1$dest != ring_stop;
            $trans_valid = $trans_avail && ! $blocked;
            ?$trans_valid
               $ANY = >ring_stop>stall_pipe|fifo_out>trans%+1$ANY;
   //            (  hop,    in_pipe, in_stage, out_pipe, out_stage, reset_scope,  reset_stage, reset_sig)
   \source ./m4/1c/pipeflow_tlv.m4 995   // Instantiated from stdin, 121 as: m4+simple_ring(ring_stop, ring_in,    0,     ring_out,     0,     >top|default,      1,       $reset  )
   
      // Logic
      >ring_stop[*]
         |default
            @0
               \SV_plus
                  int prev_hop = (ring_stop + RING_STOPS - 1) % RING_STOPS;
         |ring_in
            @0
               $blocked = >ring_stop|rg%+0$passed_on;
         |rg
            @0
               $passed_on = >ring_stop[prev_hop]|rg%+1$pass_on;
               $valid = ! >top|default%+1$reset   &&
                        ($passed_on || >ring_stop|ring_in%+0$trans_avail);
               $pass_on = $valid && ! >ring_stop|ring_out%+0$trans_valid;
               $dest[RING_STOPS_WIDTH-1:0] =
                  $passed_on
                     ? >ring_stop[prev_hop]|rg%+1$dest
                     : >ring_stop|ring_in%+0$dest;
            @1
               ?$valid
                  $ANY =
                     $passed_on
                        ? >ring_stop[prev_hop]|rg%+1$ANY
                        : >ring_stop|ring_in%+0$ANY;
         |ring_out
            // Ring out
            @0
               $trans_avail = >ring_stop|rg%+0$valid && (>ring_stop|rg%+0$dest == ring_stop);
               $blocked = 1'b0;
               $trans_valid = $trans_avail && ! $blocked;
            ?$trans_valid
               @1
                  $ANY = >ring_stop|rg%+0$ANY;
   \end_source
   
   >ring_stop[*]
      // Stall Pipeline
      >stall_pipe
         |stall0
            @0
               $reset = >top|default%+1$reset;
               $trans_avail = ! $reset && >top>tb>ring_stop|send%+1$trans_valid;
               $trans_valid = $trans_avail && ! $blocked;
               ?$trans_valid
                  >trans
                     $ANY = >top>tb>ring_stop|send>trans_out%+1$ANY;
         |stall3
            @0
               $reset = >top|default%+1$reset;
      
      // The input transaction.
      >stall_pipe
         //               (   top,     name,  first_cycle, last_cycle)
         \source ./m4/1c/pipeflow_tlv.m4 328   // Instantiated from stdin, 141 as: m4+stall_pipeline(stall_pipe, stall,      0,          3     )         
            \source ./m4/1c/pipeflow_tlv.m4 270   // Instantiated from ./m4/1c/pipeflow_tlv.m4, 330 as: m4_stall_stage(...)
               |stall0
                  @0
                     $blocked = >stall_pipe|stall1%+0$blocked;
               |stall1
                  @0
                     $trans_avail = $blocked ? %prev$trans_avail : >stall_pipe|stall0%+1$trans_avail;
                     $trans_valid = $trans_avail && !$blocked;
                     ?$trans_valid
                        >trans_hold
                           $ANY = |stall1$blocked ? %prev$ANY : >stall_pipe|stall0>trans%+1$ANY;
                     ?$trans_avail
                        >trans
                           $ANY = |stall1>trans_hold$ANY;
            \end_source
            \source ./m4/1c/pipeflow_tlv.m4 270   // Instantiated from ./m4/1c/pipeflow_tlv.m4, 330 as: m4_stall_stage(...)
               |stall1
                  @0
                     $blocked = >stall_pipe|stall2%+0$blocked;
               |stall2
                  @0
                     $trans_avail = $blocked ? %prev$trans_avail : >stall_pipe|stall1%+1$trans_avail;
                     $trans_valid = $trans_avail && !$blocked;
                     ?$trans_valid
                        >trans_hold
                           $ANY = |stall2$blocked ? %prev$ANY : >stall_pipe|stall1>trans%+1$ANY;
                     ?$trans_avail
                        >trans
                           $ANY = |stall2>trans_hold$ANY;
            \end_source
            \source ./m4/1c/pipeflow_tlv.m4 270   // Instantiated from ./m4/1c/pipeflow_tlv.m4, 330 as: m4_stall_stage(...)
               |stall2
                  @0
                     $blocked = >stall_pipe|stall3%+0$blocked;
               |stall3
                  @0
                     $trans_avail = $blocked ? %prev$trans_avail : >stall_pipe|stall2%+1$trans_avail;
                     $trans_valid = $trans_avail && !$blocked;
                     ?$trans_valid
                        >trans_hold
                           $ANY = |stall3$blocked ? %prev$ANY : >stall_pipe|stall2>trans%+1$ANY;
                     ?$trans_avail
                        >trans
                           $ANY = |stall3>trans_hold$ANY;
            \end_source
         \end_source
         
         // FIFO
         //             (   top,     in_pipe, in_stage, out_pipe, out_stage, depth, trans_hier)
         \source ./m4/1c/pipeflow_tlv.m4 550   // Instantiated from stdin, 145 as: m4+flop_fifo_v2(stall_pipe, stall3,     0,     fifo_out,    0,        4,     >trans)
            //|default
            //   @0
            \SV_plus
               localparam bit [\$clog2((4)+1)-1:0] full_mark_6 = 4 - 0;
         
            // FIFO Instantiation
         
            // Hierarchy declarations
            |stall3
               >entry[(4)-1:0]
            |fifo_out
               >entry[(4)-1:0]
         
            // Hierarchy
            |stall3
               @0
                  $out_blocked = >stall_pipe|fifo_out%+0$blocked;
                  $blocked = %+1$full && $out_blocked;
                  `BOGUS_USE($blocked)   // Not required to be consumed elsewhere.
                  $would_bypass = %+1$empty;
                  $bypass = $would_bypass && ! $out_blocked;
                  $push = $trans_valid && ! $bypass;
                  $grow   =   $trans_valid &&   $out_blocked;
                  $shrink = ! $trans_avail && ! $out_blocked && ! %+1$empty;
                  $valid_count[\$clog2((4)+1)-1:0] = $reset ? '0
                                                              : %+1$valid_count + (
                                                                   $grow   ? { {(\$clog2((4)+1)-1){1'b0}}, 1'b1} :
                                                                   $shrink ? '1
                                                                           : '0
                                                                );
                  // At least 2 valid entries.
                  //$two_valid = | $ValidCount[m4_counter_width-1:1];
                  // but logic depth minimized by taking advantage of prev count >= 4.
                  $two_valid = | %+1$valid_count[\$clog2((4)+1)-1:2] || | $valid_count[2:1];
                  // These are an optimization of the commented block below to operate on vectors, rather than bits.
                  // TODO: Keep optimizing...
                  {>entry[*]$$prev_entry_was_tail} = {>entry[*]%+1$reconstructed_is_tail\[2:0], >entry[3]%+1$reconstructed_is_tail} /* circular << */;
                  {>entry[*]$$push} = {4{$push}} & >entry[*]$prev_entry_was_tail;
                  >entry[*]
                     // Replaced with optimized versions above:
                     // $prev_entry_was_tail = >entry[(entry+(m4_depth)-1)%(m4_depth)]%+1$reconstructed_is_tail;
                     // $push = |m4_in_pipe$push && $prev_entry_was_tail;
                     $valid = (%+1$reconstructed_valid && ! >stall_pipe|fifo_out>entry%+0$pop) || $push;
                     $is_tail = |stall3$trans_valid ? $prev_entry_was_tail  // shift tail
                                                        : %+1$reconstructed_is_tail;  // retain tail
                     $state = |stall3$reset ? 1'b0
                                                : $valid && ! (|stall3$two_valid && $is_tail);
               @1
                  $empty = ! $two_valid && ! $valid_count[0];
                  $full = ($valid_count == full_mark_6);  // Could optimize for power-of-two depth.
               >entry[*]
                  @1
                     $prev_entry_state = >entry[(entry+(4)-1)%(4)]$state;
                     $next_entry_state = >entry[(entry+1)%(4)]$state;
                     $reconstructed_is_tail = (  >stall_pipe|stall3$two_valid && (!$state && $prev_entry_state)) ||
                                              (! >stall_pipe|stall3$two_valid && (!$next_entry_state && $state)) ||
                                              (|stall3$empty && (entry == 0));  // need a tail when empty for push
                     $is_head = $state && ! $prev_entry_state;
                     $reconstructed_valid = $state || (>stall_pipe|stall3$two_valid && $prev_entry_state);
            // Write data
            |stall3
               @0
                  >entry[*]
                     //?$push
                     //   $aNY = |m4_in_pipe['']m4_trans_hier$ANY;
                     >trans
                        $ANY = >entry$push ? >stall_pipe|stall3>trans$ANY : %+1$ANY /* RETAIN */;
            // Read data
            |fifo_out
               @0
                  //$pop  = ! >m4_top|m4_in_pipe%m4_align(m4_in_at + 1, m4_out_at)$empty && ! $blocked;
                  >entry[*]
                     $is_head = >stall_pipe|stall3>entry%+1$is_head;
                     $pop  = $is_head && ! |fifo_out$blocked;
                     >read_masked
                        >trans
                           $ANY = >entry$is_head ? >stall_pipe|stall3>entry>trans%+1$ANY /* $aNY */ : '0;
                     >accum
                        >trans
                           $ANY = ((entry == 0) ? '0 : >entry[(entry+(4)-1)%(4)]>accum>trans$ANY) |
                                  >entry>read_masked>trans$ANY;
                  >head
                     $trans_avail = |fifo_out$trans_avail;
                     ?$trans_avail
                        >trans
                           $ANY = >stall_pipe|fifo_out>entry[(4)-1]>accum>trans$ANY;
         
            // Bypass
            |fifo_out
               @0
                  // Available output.  Sometimes it's necessary to know what would be coming to determined
                  // if it's blocked.  This can be used externally in that case.
                  >fifo_head
                     $trans_avail = |fifo_out$trans_avail;
                     ?$trans_avail
                        >trans
                           $ANY = >stall_pipe|stall3%+0$would_bypass
                                        ? >stall_pipe|stall3>trans%+0$ANY
                                        : |fifo_out>head>trans$ANY;
                  $trans_avail = ! >stall_pipe|stall3%+0$would_bypass || >stall_pipe|stall3%+0$trans_avail;
                  $trans_valid = $trans_avail && ! $blocked;
                  ?$trans_valid
                     >trans
                        $ANY = |fifo_out>fifo_head>trans$ANY;
         
         
         
            /* Alternate code for pointer indexing.  Replaces $ANY expression above.
         
            // Hierarchy
            |stall3
               >entry2[(4)-1:0]
         
            // Head/Tail ptrs.
            |stall3
               @0
                  %next$WrPtr[\$clog2(4)-1:0] =
                      $reset       ? '0 :
                      $trans_valid ? ($WrPtr == (4 - 1))
                                       ? '0
                                       : $WrPtr + {{(\$clog2(4)-1){1'b0}}, 1'b1} :
                                     $RETAIN;
            |fifo_out
               @0
                  %next$RdPtr[\$clog2(4)-1:0] =
                      >stall_pipe|stall3%+0$reset
                                   ? '0 :
                      $trans_valid ? ($RdPtr == (4 - 1))
                                       ? '0
                                       : $RdPtr + {{(\$clog2(4)-1){1'b0}}, 1'b1} :
                                     $RETAIN;
            // Write FIFO
            |stall3
               @0
                  $dummy = '0;
                  ?$trans_valid
                     // This doesn't work because SV complains for FIFOs in replicated context that
                     // there are multiple procedures that assign the signals.
                     // Array writes can be done in an SV module.
                     // The only long-term resolutions are support for module generation and use
                     // signals declared within for loops with cross-hierarchy references in SV.
                     // TODO: To make a simulation-efficient FIFO, use DesignWare.
                     {>entry2[$WrPtr]$$ANY} = $ANY;
            // Read FIFO
            |fifo_out
               @0
                  >read2
                     $trans_valid = |fifo_out$trans_valid;
                     ?$trans_valid
                        $ANY = >stall_pipe|stall3>entry2[|fifo_out$RdPtr]%+0$ANY;
                     `BOGUS_USE($dummy)
                  ?$trans_valid
                     $ANY = >read2$ANY;
            */
         \end_source
         |fifo_out
            @0
               // blocked if destination is same as ring_stop
               $blocked = 1'b0; // >fifo_head>trans$dest == ring_stop;
      
      // Free-Flow Pipeline after Ring Out
      |pipe1
         @0
            $trans_valid = >ring_stop|ring_out%+1$trans_valid;
            ?$trans_valid
               >trans
                  $ANY = >ring_stop|ring_out%+1$ANY;
      
      // Arb
      |arb_out
         @0
            // bypass if pipe1 does not have a valid transaction and FIFO does
            // and packet's destination is same as ring_stop
            $bypass = !(>ring_stop|pipe1%+1$trans_valid) &&
                      >ring_stop>stall_pipe|fifo_out%+1$trans_valid &&
                      >ring_stop>stall_pipe|fifo_out>trans%+1$dest == ring_stop;
            $trans_valid = $bypass ||
                           >ring_stop|pipe1%+1$trans_valid;
            ?$trans_valid
               >trans
                  $ANY = |arb_out$bypass ? >ring_stop>stall_pipe|fifo_out>trans%+1$ANY :
                                           >ring_stop|pipe1>trans%+1$ANY;
      
      // Free-Flow Pipeline after Arb
      >pipe2
         |pipe2
            @0
               $reset = >top|default%+1$reset;
               $trans_avail = ! $reset && >ring_stop|arb_out%+1$trans_valid;
               $trans_valid = $trans_avail && ! $blocked;
               ?$trans_valid
                  >trans
                     $ANY = >ring_stop|arb_out>trans%+1$ANY;
         
         // FIFO2
         //             ( top,  in_pipe, in_stage, out_pipe,  out_stage, depth, trans_hier)
         \source ./m4/1c/pipeflow_tlv.m4 550   // Instantiated from stdin, 187 as: m4+flop_fifo_v2(pipe2, pipe2,      0,     fifo2_out,     0,       4,     >trans)
            //|default
            //   @0
            \SV_plus
               localparam bit [\$clog2((4)+1)-1:0] full_mark_7 = 4 - 0;
         
            // FIFO Instantiation
         
            // Hierarchy declarations
            |pipe2
               >entry[(4)-1:0]
            |fifo2_out
               >entry[(4)-1:0]
         
            // Hierarchy
            |pipe2
               @0
                  $out_blocked = >pipe2|fifo2_out%+0$blocked;
                  $blocked = %+1$full && $out_blocked;
                  `BOGUS_USE($blocked)   // Not required to be consumed elsewhere.
                  $would_bypass = %+1$empty;
                  $bypass = $would_bypass && ! $out_blocked;
                  $push = $trans_valid && ! $bypass;
                  $grow   =   $trans_valid &&   $out_blocked;
                  $shrink = ! $trans_avail && ! $out_blocked && ! %+1$empty;
                  $valid_count[\$clog2((4)+1)-1:0] = $reset ? '0
                                                              : %+1$valid_count + (
                                                                   $grow   ? { {(\$clog2((4)+1)-1){1'b0}}, 1'b1} :
                                                                   $shrink ? '1
                                                                           : '0
                                                                );
                  // At least 2 valid entries.
                  //$two_valid = | $ValidCount[m4_counter_width-1:1];
                  // but logic depth minimized by taking advantage of prev count >= 4.
                  $two_valid = | %+1$valid_count[\$clog2((4)+1)-1:2] || | $valid_count[2:1];
                  // These are an optimization of the commented block below to operate on vectors, rather than bits.
                  // TODO: Keep optimizing...
                  {>entry[*]$$prev_entry_was_tail} = {>entry[*]%+1$reconstructed_is_tail\[2:0], >entry[3]%+1$reconstructed_is_tail} /* circular << */;
                  {>entry[*]$$push} = {4{$push}} & >entry[*]$prev_entry_was_tail;
                  >entry[*]
                     // Replaced with optimized versions above:
                     // $prev_entry_was_tail = >entry[(entry+(m4_depth)-1)%(m4_depth)]%+1$reconstructed_is_tail;
                     // $push = |m4_in_pipe$push && $prev_entry_was_tail;
                     $valid = (%+1$reconstructed_valid && ! >pipe2|fifo2_out>entry%+0$pop) || $push;
                     $is_tail = |pipe2$trans_valid ? $prev_entry_was_tail  // shift tail
                                                        : %+1$reconstructed_is_tail;  // retain tail
                     $state = |pipe2$reset ? 1'b0
                                                : $valid && ! (|pipe2$two_valid && $is_tail);
               @1
                  $empty = ! $two_valid && ! $valid_count[0];
                  $full = ($valid_count == full_mark_7);  // Could optimize for power-of-two depth.
               >entry[*]
                  @1
                     $prev_entry_state = >entry[(entry+(4)-1)%(4)]$state;
                     $next_entry_state = >entry[(entry+1)%(4)]$state;
                     $reconstructed_is_tail = (  >pipe2|pipe2$two_valid && (!$state && $prev_entry_state)) ||
                                              (! >pipe2|pipe2$two_valid && (!$next_entry_state && $state)) ||
                                              (|pipe2$empty && (entry == 0));  // need a tail when empty for push
                     $is_head = $state && ! $prev_entry_state;
                     $reconstructed_valid = $state || (>pipe2|pipe2$two_valid && $prev_entry_state);
            // Write data
            |pipe2
               @0
                  >entry[*]
                     //?$push
                     //   $aNY = |m4_in_pipe['']m4_trans_hier$ANY;
                     >trans
                        $ANY = >entry$push ? >pipe2|pipe2>trans$ANY : %+1$ANY /* RETAIN */;
            // Read data
            |fifo2_out
               @0
                  //$pop  = ! >m4_top|m4_in_pipe%m4_align(m4_in_at + 1, m4_out_at)$empty && ! $blocked;
                  >entry[*]
                     $is_head = >pipe2|pipe2>entry%+1$is_head;
                     $pop  = $is_head && ! |fifo2_out$blocked;
                     >read_masked
                        >trans
                           $ANY = >entry$is_head ? >pipe2|pipe2>entry>trans%+1$ANY /* $aNY */ : '0;
                     >accum
                        >trans
                           $ANY = ((entry == 0) ? '0 : >entry[(entry+(4)-1)%(4)]>accum>trans$ANY) |
                                  >entry>read_masked>trans$ANY;
                  >head
                     $trans_avail = |fifo2_out$trans_avail;
                     ?$trans_avail
                        >trans
                           $ANY = >pipe2|fifo2_out>entry[(4)-1]>accum>trans$ANY;
         
            // Bypass
            |fifo2_out
               @0
                  // Available output.  Sometimes it's necessary to know what would be coming to determined
                  // if it's blocked.  This can be used externally in that case.
                  >fifo_head
                     $trans_avail = |fifo2_out$trans_avail;
                     ?$trans_avail
                        >trans
                           $ANY = >pipe2|pipe2%+0$would_bypass
                                        ? >pipe2|pipe2>trans%+0$ANY
                                        : |fifo2_out>head>trans$ANY;
                  $trans_avail = ! >pipe2|pipe2%+0$would_bypass || >pipe2|pipe2%+0$trans_avail;
                  $trans_valid = $trans_avail && ! $blocked;
                  ?$trans_valid
                     >trans
                        $ANY = |fifo2_out>fifo_head>trans$ANY;
         
         
         
            /* Alternate code for pointer indexing.  Replaces $ANY expression above.
         
            // Hierarchy
            |pipe2
               >entry2[(4)-1:0]
         
            // Head/Tail ptrs.
            |pipe2
               @0
                  %next$WrPtr[\$clog2(4)-1:0] =
                      $reset       ? '0 :
                      $trans_valid ? ($WrPtr == (4 - 1))
                                       ? '0
                                       : $WrPtr + {{(\$clog2(4)-1){1'b0}}, 1'b1} :
                                     $RETAIN;
            |fifo2_out
               @0
                  %next$RdPtr[\$clog2(4)-1:0] =
                      >pipe2|pipe2%+0$reset
                                   ? '0 :
                      $trans_valid ? ($RdPtr == (4 - 1))
                                       ? '0
                                       : $RdPtr + {{(\$clog2(4)-1){1'b0}}, 1'b1} :
                                     $RETAIN;
            // Write FIFO
            |pipe2
               @0
                  $dummy = '0;
                  ?$trans_valid
                     // This doesn't work because SV complains for FIFOs in replicated context that
                     // there are multiple procedures that assign the signals.
                     // Array writes can be done in an SV module.
                     // The only long-term resolutions are support for module generation and use
                     // signals declared within for loops with cross-hierarchy references in SV.
                     // TODO: To make a simulation-efficient FIFO, use DesignWare.
                     {>entry2[$WrPtr]$$ANY} = $ANY;
            // Read FIFO
            |fifo2_out
               @0
                  >read2
                     $trans_valid = |fifo2_out$trans_valid;
                     ?$trans_valid
                        $ANY = >pipe2|pipe2>entry2[|fifo2_out$RdPtr]%+0$ANY;
                     `BOGUS_USE($dummy)
                  ?$trans_valid
                     $ANY = >read2$ANY;
            */
         \end_source
         |fifo2_out
            @0
               $blocked = 1'b0;
   
   // Print
   >ring_stop[*]
      >stall_pipe
         |stall0
            @0
               >trans
                  \SV_plus
                     always_ff @(posedge clk) begin
                        \$display("\|stall0[%0d]", ring_stop);
                        \$display("Destination: %0d", $dest);
                     end
         |stall1
            @0
               >trans
                  \SV_plus
                     always_ff @(posedge clk) begin
                        \$display("\|stall1[%0d]", ring_stop);
                        \$display("Destination: %0d", $dest);
                     end
         |stall2
            @0
               >trans
                  \SV_plus
                     always_ff @(posedge clk) begin
                        \$display("\|stall2[%0d]", ring_stop);
                        \$display("Destination: %0d", $dest);
                     end
         |stall3
            @0
               >trans
                  \SV_plus
                     always_ff @(posedge clk) begin
                        \$display("\|stall3[%0d]", ring_stop);
                        \$display("Destination: %0d", $dest);
                     end
         |fifo_out
            @0
               >trans
                  \SV_plus
                     always_ff @(posedge clk) begin
                        \$display("\|fifo_out[%0d]", ring_stop);
                        \$display("Destination: %0d", $dest);
                     end
      |ring_in
         @0
            \SV_plus
               always_ff @(posedge clk) begin
                  \$display("\|ring_in[%0d]", ring_stop);
                  \$display("Destination: %0d", $dest);
               end
      |ring_out
         @1
            \SV_plus
               always_ff @(posedge clk) begin
                  \$display("\|ring_out[%0d]", ring_stop);
                  \$display("Destination: %0d", $dest);
               end
      |pipe1
         @0
            >trans
               \SV_plus
                  always_ff @(posedge clk) begin
                     \$display("\|pipe1[%0d]", ring_stop);
                     \$display("Destination: %0d", $dest);
                  end
      |arb_out
         @0
            >trans
               \SV_plus
                  always_ff @(posedge clk) begin
                     \$display("\|arb_out[%0d]", ring_stop);
                     \$display("Destination: %0d", $dest);
                  end
      >pipe2
         |pipe2
            @0
               >trans
                  \SV_plus
                     always_ff @(posedge clk) begin
                        \$display("\|pipe2[%0d]", ring_stop);
                        \$display("Destination: %0d", $dest);
                     end
         |fifo2_out
            @0
               >trans
                  \SV_plus
                     always_ff @(posedge clk) begin
                        \$display("\|fifo2_out[%0d]", ring_stop);
                        \$display("Destination: %0d", $dest);
                     end

\SV
endmodule // slide_flow
