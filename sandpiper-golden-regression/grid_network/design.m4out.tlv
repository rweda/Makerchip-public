\TLV_version [\source run/gen/grid_network/design.tlv] 1c: tl-x.org
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



// This example implements an on-chip network, implemented as an X-Y-routed grid.
// Each network tile has five bi-directional links: four neighboring tile grid-links
// and its own endpoint link.  These are named: (X-1)-link, (X+1)-link, (Y-1)-link,
// (Y+1)-link, and E-link, each with an i (input) and o (output) direction
// (eg: (X-1)-olink is the outbound link to the X-1 tile; E-olink is out of network).
//
// Packets contain multiple flits, where a flit occupies a single-cycle on a
// link.  Idle flits may be injected at any time, between or within packets.
// They will disappear
// when queued, but will otherwise occupy slots when routed.  Packets should
// generally be injected contiguously, with idles only in exceptional circumstances.
// Packet size is determined only by a tail flit; there is no 'size' field in the
// packet header.  Packets are routed contiguously and can block other traffic,
// so large packets can introduce undesireable network characteristics.
// Packetization can be done at a higher level to address this.
//
// Network buffering is minimal.  However, when packets are blocked, the E-link can
// be used to alleviate the congestion if the packet is "unordered" and if the
// intermediate tile is able to absorb the packet (size needed?) and reinject it.
//
// Virtual channels/lanes/networks are supported for protocol deadlock
// avoidance, prioritization, and independence.  Each VC has a static
// priority assigned.
//
// Priority of traffic is as follows, highest to lowest.
// On an outgoing network(X/Y)-olink:
//   - The next flit following the previous one (non-tail, including idle).
//   - Among queued non-head flits of the highest queued-traffic priority, or if
//     none, head flits of the highest queued head flit priority, or if none,
//     heads arriving this cycle:
//     - Traffic continuing in a straight path.
//     - Traffic taking a turn (Y-links only because of X-Y routing).
//     - Traffic entering from the E-link.
// On an E-ilink:
//   - The next flit following the previous one (including idle).
//   - The flit selected based on last cycle's head info using round-robin
//     among heads waiting for this endpoint.  The head flit is dropped,
//     so no cycle is lost.
//   - 
// At each link 

module grid_network(input logic clk, input logic reset, input logic [15:0] cyc_cnt, output logic passed, output logic failed);    /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_on UNOPTFLAT */







\TLV
   |reset
      @-1
         // Create pipesignal out of reset module input.
!        $reset = *reset;

   // Stimulus
   //
   >yy[1:0]
      >xx[1:0]
         |tb_gen
            // Generate stimulus feeding the E-Link input FIFO.
            @1
               $reset = >top|reset%+0$reset;
               $head_tail_rand[2:0] = *RW_rand_vect[(0 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 3];
               $head = ! $MidPacket &&              // can be head
                       (& $head_tail_rand) &&       // 1/8 probability
                       ! $reset &&                  // after reset
                       (>top|tb_gen$CycCnt < 100);  // until max cycle
               $tail = ! $reset &&
                       ($head || $MidPacket) &&   // can be tail
                       ((& $head_tail_rand) ||    // 1/8 probability
                        ($PktCnt >= 15));  // force tail on max length
               // $MidPacket = after head through tail.
               %next$MidPacket = ! $reset && (($head && ! $trans_valid) || $MidPacket) && ! ($tail && ! $trans_valid);
               
               // Packet and flit-within-packet counts.
               $reset_or_head = $reset || $head;
               ?$reset_or_head
                  %next$PktCnt[7:0] = $reset ? 0 : $PktCnt + 1;
               $reset_or_trans_valid = $reset | $trans_valid;
               ?$reset_or_trans_valid
                  %next$FlitCnt[3:0] = ($reset || $tail) ? 0 : $FlitCnt + 1;
               
               $vc_rand[2-1:0] = *RW_rand_vect[(124 + ((yy * xx) ^ ((3 * yy) + yy))) % 257 +: 2];
               $vc[2-1:0] = ($vc_rand > 3)        // out of range?
                           ? {1'b0, $vc_rand[2-2:0]}      // drop the max bit
                           : $vc_rand;
               $rand_valid[2:0] = *RW_rand_vect[(248 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 3];
               $trans_valid = ($head || $MidPacket) && (| $rand_valid) && ! >xx>vc[$vc]|tb_gen$blocked;   // 1/8 probability of idle
               ?$trans_valid
                  >flit
                     // Generate a random flit.
                     // Random values from which to generate flit:
                     $dest_x_rand[1-1:0] = *RW_rand_vect[(115 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 1];
                     $dest_y_rand[1-1:0] = *RW_rand_vect[(239 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 1];
                     // Flit:
                     $vc[2-1:0] = |tb_gen$vc;
                     $head = |tb_gen$head;
                     $tail = |tb_gen$tail;
                     $pkt_cnt[7:0] = |tb_gen$PktCnt;
                     $flit_cnt[3:0] = |tb_gen$FlitCnt;
                     $src_x[1-1:0] = xx;
                     $src_y[1-1:0] = yy;
                     $dest_x[1-1:0] = ($dest_x_rand > 1) // out of range?
                                  ? {1'b0, $dest_x_rand[1-2:0]}  // drop the max bit
                                  : $dest_x_rand;                          // in range
                     $dest_y[1-1:0] = ($dest_y_rand > 1) // out of range?
                                  ? {1'b0, $dest_y_rand[1-2:0]}  // drop the max bit
                                  : $dest_y_rand;                          // in range
                     $data[7:0] = *RW_rand_vect[(106 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 8];
                     
                     
   //
   // Design
   //
   
   >yy[*]
      >xx[*]
         
         // E-Link
         //
         // Into Network

         >vc[3:0]
            |tb_gen
               @1
                  $vc_trans_valid = >xx|tb_gen$trans_valid && (>xx|tb_gen>flit$vc == #vc);
            |netwk_inject
               @0
                  %next$Prio = vc;  // Prioritize based on VC.
         \source ./m4/1c/pipeflow_tlv.m4 841   // Instantiated from stdin, 162 as: m4+vc_flop_fifo_v2(xx, tb_gen, 1, netwk_inject, 1, 6, >flit, 3:0, 1:0)
            >vc[3:0]
               |tb_gen
                  @1
                     // Apply inputs to the right VC FIFO.
                     //
         
                     $reset = >xx|tb_gen$reset;
                     $trans_valid = $vc_trans_valid && ! >vc|netwk_inject%+0$bypassed_fifos_for_this_vc;
                     $trans_avail = $trans_valid;
                     ?$trans_valid
                        >flit
                           $ANY = >xx|tb_gen>flit$ANY;
               // Instantiate FIFO.  Output to stage (m4_out_at - 1) because bypass is m4_out_at.
               \source ./m4/1c/pipeflow_tlv.m4 550   // Instantiated from ./m4/1c/pipeflow_tlv.m4, 855 as: m4_flop_fifo_v2(...)
                  //|default
                  //   @0
                  \SV_plus
                     localparam bit [\$clog2((6)+1)-1:0] full_mark_2 = 6 - 0;
               
                  // FIFO Instantiation
               
                  // Hierarchy declarations
                  |tb_gen
                     >entry[(6)-1:0]
                  |netwk_inject
                     >entry[(6)-1:0]
               
                  // Hierarchy
                  |tb_gen
                     @1
                        $out_blocked = >vc|netwk_inject%-1$blocked;
                        $blocked = %+1$full && $out_blocked;
                        `BOGUS_USE($blocked)   // Not required to be consumed elsewhere.
                        $would_bypass = %+1$empty;
                        $bypass = $would_bypass && ! $out_blocked;
                        $push = $trans_valid && ! $bypass;
                        $grow   =   $trans_valid &&   $out_blocked;
                        $shrink = ! $trans_avail && ! $out_blocked && ! %+1$empty;
                        $valid_count[\$clog2((6)+1)-1:0] = $reset ? '0
                                                                    : %+1$valid_count + (
                                                                         $grow   ? { {(\$clog2((6)+1)-1){1'b0}}, 1'b1} :
                                                                         $shrink ? '1
                                                                                 : '0
                                                                      );
                        // At least 2 valid entries.
                        //$two_valid = | $ValidCount[m4_counter_width-1:1];
                        // but logic depth minimized by taking advantage of prev count >= 4.
                        $two_valid = | %+1$valid_count[\$clog2((6)+1)-1:2] || | $valid_count[2:1];
                        // These are an optimization of the commented block below to operate on vectors, rather than bits.
                        // TODO: Keep optimizing...
                        {>entry[*]$$prev_entry_was_tail} = {>entry[*]%+1$reconstructed_is_tail\[4:0], >entry[5]%+1$reconstructed_is_tail} /* circular << */;
                        {>entry[*]$$push} = {6{$push}} & >entry[*]$prev_entry_was_tail;
                        >entry[*]
                           // Replaced with optimized versions above:
                           // $prev_entry_was_tail = >entry[(entry+(m4_depth)-1)%(m4_depth)]%+1$reconstructed_is_tail;
                           // $push = |m4_in_pipe$push && $prev_entry_was_tail;
                           $valid = (%+1$reconstructed_valid && ! >vc|netwk_inject>entry%-1$pop) || $push;
                           $is_tail = |tb_gen$trans_valid ? $prev_entry_was_tail  // shift tail
                                                              : %+1$reconstructed_is_tail;  // retain tail
                           $state = |tb_gen$reset ? 1'b0
                                                      : $valid && ! (|tb_gen$two_valid && $is_tail);
                     @2
                        $empty = ! $two_valid && ! $valid_count[0];
                        $full = ($valid_count == full_mark_2);  // Could optimize for power-of-two depth.
                     >entry[*]
                        @2
                           $prev_entry_state = >entry[(entry+(6)-1)%(6)]$state;
                           $next_entry_state = >entry[(entry+1)%(6)]$state;
                           $reconstructed_is_tail = (  >vc|tb_gen$two_valid && (!$state && $prev_entry_state)) ||
                                                    (! >vc|tb_gen$two_valid && (!$next_entry_state && $state)) ||
                                                    (|tb_gen$empty && (entry == 0));  // need a tail when empty for push
                           $is_head = $state && ! $prev_entry_state;
                           $reconstructed_valid = $state || (>vc|tb_gen$two_valid && $prev_entry_state);
                  // Write data
                  |tb_gen
                     @1
                        >entry[*]
                           //?$push
                           //   $aNY = |m4_in_pipe['']m4_trans_hier$ANY;
                           >flit
                              $ANY = >entry$push ? >vc|tb_gen>flit$ANY : %+1$ANY /* RETAIN */;
                  // Read data
                  |netwk_inject
                     @0
                        //$pop  = ! >m4_top|m4_in_pipe%m4_align(m4_in_at + 1, m4_out_at)$empty && ! $blocked;
                        >entry[*]
                           $is_head = >vc|tb_gen>entry%+2$is_head;
                           $pop  = $is_head && ! |netwk_inject$blocked;
                           >read_masked
                              >flit
                                 $ANY = >entry$is_head ? >vc|tb_gen>entry>flit%+2$ANY /* $aNY */ : '0;
                           >accum
                              >flit
                                 $ANY = ((entry == 0) ? '0 : >entry[(entry+(6)-1)%(6)]>accum>flit$ANY) |
                                        >entry>read_masked>flit$ANY;
                        >head
                           $trans_avail = |netwk_inject$trans_avail;
                           ?$trans_avail
                              >flit
                                 $ANY = >vc|netwk_inject>entry[(6)-1]>accum>flit$ANY;
               
                  // Bypass
                  |netwk_inject
                     @0
                        // Available output.  Sometimes it's necessary to know what would be coming to determined
                        // if it's blocked.  This can be used externally in that case.
                        >fifo_head
                           $trans_avail = |netwk_inject$trans_avail;
                           ?$trans_avail
                              >flit
                                 $ANY = >vc|tb_gen%+1$would_bypass
                                              ? >vc|tb_gen>flit%+1$ANY
                                              : |netwk_inject>head>flit$ANY;
                        $trans_avail = ! >vc|tb_gen%+1$would_bypass || >vc|tb_gen%+1$trans_avail;
                        $trans_valid = $trans_avail && ! $blocked;
                        ?$trans_valid
                           >flit
                              $ANY = |netwk_inject>fifo_head>flit$ANY;
               
               
               
                  /* Alternate code for pointer indexing.  Replaces $ANY expression above.
               
                  // Hierarchy
                  |tb_gen
                     >entry2[(6)-1:0]
               
                  // Head/Tail ptrs.
                  |tb_gen
                     @1
                        %next$WrPtr[\$clog2(6)-1:0] =
                            $reset       ? '0 :
                            $trans_valid ? ($WrPtr == (6 - 1))
                                             ? '0
                                             : $WrPtr + {{(\$clog2(6)-1){1'b0}}, 1'b1} :
                                           $RETAIN;
                  |netwk_inject
                     @0
                        %next$RdPtr[\$clog2(6)-1:0] =
                            >vc|tb_gen%+1$reset
                                         ? '0 :
                            $trans_valid ? ($RdPtr == (6 - 1))
                                             ? '0
                                             : $RdPtr + {{(\$clog2(6)-1){1'b0}}, 1'b1} :
                                           $RETAIN;
                  // Write FIFO
                  |tb_gen
                     @1
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
                  |netwk_inject
                     @0
                        >read2
                           $trans_valid = |netwk_inject$trans_valid;
                           ?$trans_valid
                              $ANY = >vc|tb_gen>entry2[|netwk_inject$RdPtr]%+1$ANY;
                           `BOGUS_USE($dummy)
                        ?$trans_valid
                           $ANY = >read2$ANY;
                  */
               \end_source
         
            // FIFO select.
            //
            >vc[*]
               |netwk_inject
                  @0
                     $arbing = $trans_avail && $has_credit;
                     >prio[1:0]
                        // Decoded priority.
                        %next$Match = #prio == |netwk_inject$Prio;
                     // Mask of same-prio VCs.
                     >other_vc[3:0]
                        %next$SamePrio = |netwk_inject$Prio == >vc[#other_vc]|netwk_inject$Prio;
                        // Select among same-prio VCs.
                        $competing = $SamePrio && >vc[#other_vc]|netwk_inject$arbing;
                     // Select FIFO if selected within priority and this VC has the selected (max available) priority.
                     $fifo_sel = ((>other_vc[*]$competing & ~((1 << vc) - 1)) == (1 << vc)) && | (>prio[*]$Match & >xx>prio[*]|netwk_inject$sel);
                        // TODO: Need to replace m4_am_max with round-robin within priority.
                     $blocked = ! $fifo_sel;
                  @1
                     // Can bypass FIFOs?
                     $can_bypass_fifos_for_this_vc = >vc|tb_gen%+0$vc_trans_valid &&
                                                     >vc|tb_gen%+1$empty &&
                                                     $has_credit;
         
                     // Indicate output VC as per-VC FIFO output $trans_valid or could bypass in this VC.
                     $bypassed_fifos_for_this_vc = $can_bypass_fifos_for_this_vc && ! >xx|netwk_inject$fifo_trans_avail;
                     $vc_trans_valid = $trans_valid || $bypassed_fifos_for_this_vc;
                     `BOGUS_USE($vc_trans_valid)  // okay to not consume this
            >prio[1:0]
               |netwk_inject
                  @0
                     >vc[3:0]
                        // Trans available for this prio/VC?
                        $avail_within_prio = >xx>vc|netwk_inject$trans_avail &&
                                             >xx>vc|netwk_inject>prio$Match;
                     // Is this priority available in FIFOs.
                     $avail = | >vc[*]$avail_within_prio;
                     // Select this priority if its the max available.
                     $sel = ((>prio[*]|netwk_inject$avail & ~((1 << prio) - 1)) == (1 << prio));
         
            |netwk_inject
               @0
                  $fifo_trans_avail = | >xx>vc[*]|netwk_inject$arbing;
                  >fifos_out
                     $fifo_trans_avail = |netwk_inject$fifo_trans_avail;
                     >vc[3:0]
                     \source ./m4/1c/rw_tlv.m4 279   // Instantiated from ./m4/1c/pipeflow_tlv.m4, 903 as: m4_select(...)
                        
                        // This is a suboptimal implementation for simulation.
                        // It does AND/OR reduction.  It would be better in simulation to simply index the desired value,
                        //   but this is not currently supported in SandPiper as it is not legal across generate loops.
                        >vc[*]
                           >accum
                              \always_comb
                                 if (vc == \$low(>xx>vc[*]|netwk_inject$fifo_sel))
                                    $$ANY = >xx>vc|netwk_inject$fifo_sel ? >xx>vc|netwk_inject>flit$ANY : '0;
                                 else
                                    $ANY = >xx>vc|netwk_inject$fifo_sel ? >xx>vc|netwk_inject>flit$ANY : >vc[vc-1]>accum$ANY;
                                             
                        ?$fifo_trans_avail
                           $ANY = >vc[\$high(>xx>vc[*]|netwk_inject$fifo_sel)]>accum$ANY;
                                             /* Old way:
                        \always_comb
                           $$ANY = m4_init;
                           for (int i = m4_MIN; i <= m4_MAX; i++)
                              $ANY = $ANY | (>vc[i]m4_index_sig_match ? >vc[i]$ANY : '0);
                        */
                     \end_source
         
                  // Output transaction
                  //
         
               @1
                  // Incorporate bypass
                  // Bypass if there's no transaction from the FIFOs, and the incoming transaction is okay for output.
                  $can_bypass_fifos = | >xx>vc[*]|netwk_inject$can_bypass_fifos_for_this_vc;
                  $trans_valid = $fifo_trans_avail || $can_bypass_fifos;
                  ?$trans_valid
                     >flit
                        $ANY = |netwk_inject$fifo_trans_avail ? |netwk_inject>fifos_out$ANY : >xx|tb_gen>flit%+0$ANY;
         \end_source
         >vc[*]
            |netwk_inject
               @0
                  $has_credit = ! >vc|netwk_eject%+2$full;  // Temp loopback.  (Okay if not one-entry remaining ("full") after two-transactions previous to this (one intervening).)

         /*
         // Network X/Y +1/-1 Links
         >direction[1:0]  // 1: Y, 0: X
            >sign[1:0]  // 1: +1, 0: -1
               //
               // Connect upstream grid link.
               |grid_out
               |grid_in
                  @0
                     \SV_plus
                        // Characterize connection.
                        localparam DANGLE = ((*direction == 0) ? (*xx == ((*sign == 0) ? 1 : 0))
                                                               : (*yy == ((*sign == 0) ? 1 : 0))
                                            );  // At edge.  No link.
                        localparam UPSTREAM_X = (*direction == 1) ? *xx : ((*sign == 0) ? (*xx + 1) : (*xx - 1));
                        localparam UPSTREAM_Y = (*direction == 0) ? *yy : ((*sign == 0) ? (*yy + 1) : (*yy - 1));
                        // Connect control.
                        if (DANGLE)
                           assign $$trans_valid = '0;
                        else
                           assign $trans_valid = >yy[*UPSTREAM_Y]>xx[*UPSTREAM_X]>direction>sign|grid_out$trans_valid;
                     >flit
                        // Connect transaction.
                        \SV_plus
                           if (DANGLE)
                              assign $$ANY = '0;
                           else
                              // Connect w/ upstream tile.
                              assign $ANY = >yy[*UPSTREAM_Y]>xx[*UPSTREAM_X]>direction>sign|grid_out$ANY;
               
               // Grid FIFOs.
               >vc[3:0]
                  |grid_fifo_out
                     @0
                        %next$Prio = >xx>vc|netwk_inject%+0$Prio;
                     >prio[1:0]
               >prio[1:0]
                  |grid_fifo_out
                     >vc[3:0]
               m4 +vc_flop_fifo_v2(sign, grid_in, 1, grid_fifo_out, 1, 1, >flit, 3:0, 1:0)
               |grid_fifo_out
                  @1
                     $blocked = ...;
                     */
               
            
         // O-Link
         //
         // Out of Network
         
         >vc[3:0]
            
            //+// Credit, reflecting 
            //+m4_credit_counter(['            $1'], ']m4___file__[', ']m4___line__[', ['m4_['']credit_counter(...)'], $Credit, 1, 2, $reset, $push, >vc|m4_out_pipe%m4_bypass_align$trans_valid)

         >vc[*]
            |netwk_eject
               @1
                  $vc_trans_valid = >vc|netwk_inject%+0$vc_trans_valid; /* temp loopback */
         |netwk_eject
            @1
               $reset = >top|reset%+0$reset;
               $trans_valid = >xx|netwk_inject%+0$trans_valid; /* temp loopback */
               ?$trans_valid
                  >flit
                     $ANY = /* temp loopback */ >xx|netwk_inject>flit%+0$ANY;
         \source ./m4/1c/pipeflow_tlv.m4 841   // Instantiated from stdin, 234 as: m4+vc_flop_fifo_v2(xx, netwk_eject, 1, tb_out, 1, 6, >flit, 3:0, 1:0, 1, 1)
            >vc[3:0]
               |netwk_eject
                  @1
                     // Apply inputs to the right VC FIFO.
                     //
         
                     $reset = >xx|netwk_eject$reset;
                     $trans_valid = $vc_trans_valid && ! >vc|tb_out%+0$bypassed_fifos_for_this_vc;
                     $trans_avail = $trans_valid;
                     ?$trans_valid
                        >flit
                           $ANY = >xx|netwk_eject>flit$ANY;
               // Instantiate FIFO.  Output to stage (m4_out_at - 1) because bypass is m4_out_at.
               \source ./m4/1c/pipeflow_tlv.m4 550   // Instantiated from ./m4/1c/pipeflow_tlv.m4, 855 as: m4_flop_fifo_v2(...)
                  //|default
                  //   @0
                  \SV_plus
                     localparam bit [\$clog2((6)+1)-1:0] full_mark_5 = 6 - 1;
               
                  // FIFO Instantiation
               
                  // Hierarchy declarations
                  |netwk_eject
                     >entry[(6)-1:0]
                  |tb_out
                     >entry[(6)-1:0]
               
                  // Hierarchy
                  |netwk_eject
                     @1
                        $out_blocked = >vc|tb_out%-1$blocked;
                        $blocked = %+1$full && $out_blocked;
                        `BOGUS_USE($blocked)   // Not required to be consumed elsewhere.
                        $would_bypass = %+1$empty;
                        $bypass = $would_bypass && ! $out_blocked;
                        $push = $trans_valid && ! $bypass;
                        $grow   =   $trans_valid &&   $out_blocked;
                        $shrink = ! $trans_avail && ! $out_blocked && ! %+1$empty;
                        $valid_count[\$clog2((6)+1)-1:0] = $reset ? '0
                                                                    : %+1$valid_count + (
                                                                         $grow   ? { {(\$clog2((6)+1)-1){1'b0}}, 1'b1} :
                                                                         $shrink ? '1
                                                                                 : '0
                                                                      );
                        // At least 2 valid entries.
                        //$two_valid = | $ValidCount[m4_counter_width-1:1];
                        // but logic depth minimized by taking advantage of prev count >= 4.
                        $two_valid = | %+1$valid_count[\$clog2((6)+1)-1:2] || | $valid_count[2:1];
                        // These are an optimization of the commented block below to operate on vectors, rather than bits.
                        // TODO: Keep optimizing...
                        {>entry[*]$$prev_entry_was_tail} = {>entry[*]%+1$reconstructed_is_tail\[4:0], >entry[5]%+1$reconstructed_is_tail} /* circular << */;
                        {>entry[*]$$push} = {6{$push}} & >entry[*]$prev_entry_was_tail;
                        >entry[*]
                           // Replaced with optimized versions above:
                           // $prev_entry_was_tail = >entry[(entry+(m4_depth)-1)%(m4_depth)]%+1$reconstructed_is_tail;
                           // $push = |m4_in_pipe$push && $prev_entry_was_tail;
                           $valid = (%+1$reconstructed_valid && ! >vc|tb_out>entry%-1$pop) || $push;
                           $is_tail = |netwk_eject$trans_valid ? $prev_entry_was_tail  // shift tail
                                                              : %+1$reconstructed_is_tail;  // retain tail
                           $state = |netwk_eject$reset ? 1'b0
                                                      : $valid && ! (|netwk_eject$two_valid && $is_tail);
                     @2
                        $empty = ! $two_valid && ! $valid_count[0];
                        $full = ($valid_count == full_mark_5);  // Could optimize for power-of-two depth.
                     >entry[*]
                        @2
                           $prev_entry_state = >entry[(entry+(6)-1)%(6)]$state;
                           $next_entry_state = >entry[(entry+1)%(6)]$state;
                           $reconstructed_is_tail = (  >vc|netwk_eject$two_valid && (!$state && $prev_entry_state)) ||
                                                    (! >vc|netwk_eject$two_valid && (!$next_entry_state && $state)) ||
                                                    (|netwk_eject$empty && (entry == 0));  // need a tail when empty for push
                           $is_head = $state && ! $prev_entry_state;
                           $reconstructed_valid = $state || (>vc|netwk_eject$two_valid && $prev_entry_state);
                  // Write data
                  |netwk_eject
                     @1
                        >entry[*]
                           //?$push
                           //   $aNY = |m4_in_pipe['']m4_trans_hier$ANY;
                           >flit
                              $ANY = >entry$push ? >vc|netwk_eject>flit$ANY : %+1$ANY /* RETAIN */;
                  // Read data
                  |tb_out
                     @0
                        //$pop  = ! >m4_top|m4_in_pipe%m4_align(m4_in_at + 1, m4_out_at)$empty && ! $blocked;
                        >entry[*]
                           $is_head = >vc|netwk_eject>entry%+2$is_head;
                           $pop  = $is_head && ! |tb_out$blocked;
                           >read_masked
                              >flit
                                 $ANY = >entry$is_head ? >vc|netwk_eject>entry>flit%+2$ANY /* $aNY */ : '0;
                           >accum
                              >flit
                                 $ANY = ((entry == 0) ? '0 : >entry[(entry+(6)-1)%(6)]>accum>flit$ANY) |
                                        >entry>read_masked>flit$ANY;
                        >head
                           $trans_avail = |tb_out$trans_avail;
                           ?$trans_avail
                              >flit
                                 $ANY = >vc|tb_out>entry[(6)-1]>accum>flit$ANY;
               
                  // Bypass
                  |tb_out
                     @0
                        // Available output.  Sometimes it's necessary to know what would be coming to determined
                        // if it's blocked.  This can be used externally in that case.
                        >fifo_head
                           $trans_avail = |tb_out$trans_avail;
                           ?$trans_avail
                              >flit
                                 $ANY = >vc|netwk_eject%+1$would_bypass
                                              ? >vc|netwk_eject>flit%+1$ANY
                                              : |tb_out>head>flit$ANY;
                        $trans_avail = ! >vc|netwk_eject%+1$would_bypass || >vc|netwk_eject%+1$trans_avail;
                        $trans_valid = $trans_avail && ! $blocked;
                        ?$trans_valid
                           >flit
                              $ANY = |tb_out>fifo_head>flit$ANY;
               
               
               
                  /* Alternate code for pointer indexing.  Replaces $ANY expression above.
               
                  // Hierarchy
                  |netwk_eject
                     >entry2[(6)-1:0]
               
                  // Head/Tail ptrs.
                  |netwk_eject
                     @1
                        %next$WrPtr[\$clog2(6)-1:0] =
                            $reset       ? '0 :
                            $trans_valid ? ($WrPtr == (6 - 1))
                                             ? '0
                                             : $WrPtr + {{(\$clog2(6)-1){1'b0}}, 1'b1} :
                                           $RETAIN;
                  |tb_out
                     @0
                        %next$RdPtr[\$clog2(6)-1:0] =
                            >vc|netwk_eject%+1$reset
                                         ? '0 :
                            $trans_valid ? ($RdPtr == (6 - 1))
                                             ? '0
                                             : $RdPtr + {{(\$clog2(6)-1){1'b0}}, 1'b1} :
                                           $RETAIN;
                  // Write FIFO
                  |netwk_eject
                     @1
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
                  |tb_out
                     @0
                        >read2
                           $trans_valid = |tb_out$trans_valid;
                           ?$trans_valid
                              $ANY = >vc|netwk_eject>entry2[|tb_out$RdPtr]%+1$ANY;
                           `BOGUS_USE($dummy)
                        ?$trans_valid
                           $ANY = >read2$ANY;
                  */
               \end_source
         
            // FIFO select.
            //
            >vc[*]
               |tb_out
                  @0
                     $arbing = $trans_avail && $has_credit;
                     >prio[1:0]
                        // Decoded priority.
                        %next$Match = #prio == |tb_out$Prio;
                     // Mask of same-prio VCs.
                     >other_vc[3:0]
                        %next$SamePrio = |tb_out$Prio == >vc[#other_vc]|tb_out$Prio;
                        // Select among same-prio VCs.
                        $competing = $SamePrio && >vc[#other_vc]|tb_out$arbing;
                     // Select FIFO if selected within priority and this VC has the selected (max available) priority.
                     $fifo_sel = ((>other_vc[*]$competing & ~((1 << vc) - 1)) == (1 << vc)) && | (>prio[*]$Match & >xx>prio[*]|tb_out$sel);
                        // TODO: Need to replace m4_am_max with round-robin within priority.
                     $blocked = ! $fifo_sel;
                  @1
                     // Can bypass FIFOs?
                     $can_bypass_fifos_for_this_vc = >vc|netwk_eject%+0$vc_trans_valid &&
                                                     >vc|netwk_eject%+1$empty &&
                                                     $has_credit;
         
                     // Indicate output VC as per-VC FIFO output $trans_valid or could bypass in this VC.
                     $bypassed_fifos_for_this_vc = $can_bypass_fifos_for_this_vc && ! >xx|tb_out$fifo_trans_avail;
                     $vc_trans_valid = $trans_valid || $bypassed_fifos_for_this_vc;
                     `BOGUS_USE($vc_trans_valid)  // okay to not consume this
            >prio[1:0]
               |tb_out
                  @0
                     >vc[3:0]
                        // Trans available for this prio/VC?
                        $avail_within_prio = >xx>vc|tb_out$trans_avail &&
                                             >xx>vc|tb_out>prio$Match;
                     // Is this priority available in FIFOs.
                     $avail = | >vc[*]$avail_within_prio;
                     // Select this priority if its the max available.
                     $sel = ((>prio[*]|tb_out$avail & ~((1 << prio) - 1)) == (1 << prio));
         
            |tb_out
               @0
                  $fifo_trans_avail = | >xx>vc[*]|tb_out$arbing;
                  >fifos_out
                     $fifo_trans_avail = |tb_out$fifo_trans_avail;
                     >vc[3:0]
                     \source ./m4/1c/rw_tlv.m4 279   // Instantiated from ./m4/1c/pipeflow_tlv.m4, 903 as: m4_select(...)
                        
                        // This is a suboptimal implementation for simulation.
                        // It does AND/OR reduction.  It would be better in simulation to simply index the desired value,
                        //   but this is not currently supported in SandPiper as it is not legal across generate loops.
                        >vc[*]
                           >accum
                              \always_comb
                                 if (vc == \$low(>xx>vc[*]|tb_out$fifo_sel))
                                    $$ANY = >xx>vc|tb_out$fifo_sel ? >xx>vc|tb_out>flit$ANY : '0;
                                 else
                                    $ANY = >xx>vc|tb_out$fifo_sel ? >xx>vc|tb_out>flit$ANY : >vc[vc-1]>accum$ANY;
                                             
                        ?$fifo_trans_avail
                           $ANY = >vc[\$high(>xx>vc[*]|tb_out$fifo_sel)]>accum$ANY;
                                             /* Old way:
                        \always_comb
                           $$ANY = m4_init;
                           for (int i = m4_MIN; i <= m4_MAX; i++)
                              $ANY = $ANY | (>vc[i]m4_index_sig_match ? >vc[i]$ANY : '0);
                        */
                     \end_source
         
                  // Output transaction
                  //
         
               @1
                  // Incorporate bypass
                  // Bypass if there's no transaction from the FIFOs, and the incoming transaction is okay for output.
                  $can_bypass_fifos = | >xx>vc[*]|tb_out$can_bypass_fifos_for_this_vc;
                  $trans_valid = $fifo_trans_avail || $can_bypass_fifos;
                  ?$trans_valid
                     >flit
                        $ANY = |tb_out$fifo_trans_avail ? |tb_out>fifos_out$ANY : >xx|netwk_eject>flit%+0$ANY;
         \end_source
         >vc[*]
            |tb_out
               @0
                  %next$Prio = >vc|netwk_inject%+0$Prio;
                  $has_credit[0:0] = *RW_rand_vect[(230 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 1];
         |tb_out
            @1
               ?$trans_valid
                  >flit
                     `BOGUS_USE($head $tail $data)
               
   //==========
   // Testbench
   //
   |tb_gen
      
      @-1
         // Free-running cycle count.
         %next$CycCnt[15:0] = >top|reset%+0$reset ? 16'b0 : $CycCnt + 16'b1;
      
      @1
         >yy[1:0]
            >xx[1:0]
               // Keep track of how many flits were injected.
               $inj_cnt[1-1:0] = >top>yy>xx|tb_gen$trans_valid ? 1 : 0;
            \source ./m4/1c/rw_tlv.m4 206   // Instantiated from stdin, 260 as: m4+redux($inj_row_sum[(1 + 1)-1:0], >xx, 1, 0, $inj_cnt, '0, +)
               \always_comb
                  $$inj_row_sum[(1 + 1)-1:0] = '0;
                  for (int i = 0; i <= 1; i++)
                     $inj_row_sum[(1 + 1)-1:0] = $inj_row_sum[(1 + 1)-1:0] + >xx[i]$inj_cnt;
            \end_source
         \source ./m4/1c/rw_tlv.m4 206   // Instantiated from stdin, 261 as: m4+redux($inj_sum[(1 + 1)-1:0], >yy, 1, 0, $inj_row_sum, '0, +)
            \always_comb
               $$inj_sum[(1 + 1)-1:0] = '0;
               for (int i = 0; i <= 1; i++)
                  $inj_sum[(1 + 1)-1:0] = $inj_sum[(1 + 1)-1:0] + >yy[i]$inj_row_sum;
         \end_source
      @1
         $inj_cnt[(1 + 1)-1:0] = >top|reset%+0$reset ? '0 : $inj_sum;
      
   |tb_out
        // Alignment below with |tb_gen.

      @1
         $reset = >top|reset%+0$reset;
      @2
         >yy[1:0]
            >xx[1:0]
               // Keep track of how many flits came out.
               $eject_cnt[1-1:0] = >top>yy>xx|tb_out$trans_valid ? 1 : 0;
            \source ./m4/1c/rw_tlv.m4 206   // Instantiated from stdin, 275 as: m4+redux($eject_row_sum[(1 + 1)-1:0], >xx, 1, 0, $eject_cnt, '0, +)
               \always_comb
                  $$eject_row_sum[(1 + 1)-1:0] = '0;
                  for (int i = 0; i <= 1; i++)
                     $eject_row_sum[(1 + 1)-1:0] = $eject_row_sum[(1 + 1)-1:0] + >xx[i]$eject_cnt;
            \end_source
         \source ./m4/1c/rw_tlv.m4 206   // Instantiated from stdin, 276 as: m4+redux($eject_sum[(1 + 1)-1:0], >yy, 1, 0, $eject_row_sum, '0, +)
            \always_comb
               $$eject_sum[(1 + 1)-1:0] = '0;
               for (int i = 0; i <= 1; i++)
                  $eject_sum[(1 + 1)-1:0] = $eject_sum[(1 + 1)-1:0] + >yy[i]$eject_row_sum;
         \end_source
         $eject_cnt[(1 + 1)-1:0] = $reset ? '0 : $eject_sum;
         %next$FlitsInFlight[31:0] = $reset ? '0 : $FlitsInFlight + >top|tb_gen%+0$inj_cnt - $eject_cnt;
         
        // Refers to flit in tb_gen scope.
        // Refers to flit in tb_out scope.
      @2
         \SV_plus
            always_ff @(posedge clk) begin
               if (! $reset) begin
                  \$display("-In-        -Out-      (Cycle: \%d, Inflight: \%d)", >top|tb_gen%+0$CycCnt, $FlitsInFlight);
                  \$display("/---+---\\\\   /---+---\\\\");
                  for(int y = 0; y <= 1; y++) begin
                     \$display("\|\%1h\%1h\%1h\|\%1h\%1h\%1h\|   \|\%1h\%1h\%1h\|\%1h\%1h\%1h\|", >top>yy[y]>xx[0]|tb_gen>flit%+0$dest_x, >top>yy[y]>xx[0]|tb_gen>flit%+0$dest_y, >top>yy[y]>xx[0]|tb_gen>flit%+0$vc, >top>yy[y]>xx[1]|tb_gen>flit%+0$dest_x, >top>yy[y]>xx[1]|tb_gen>flit%+0$dest_y, >top>yy[y]>xx[1]|tb_gen>flit%+0$vc, >top>yy[y]>xx[0]|tb_out>flit$dest_x, >top>yy[y]>xx[0]|tb_out>flit$dest_y, >top>yy[y]>xx[0]|tb_out>flit$vc, >top>yy[y]>xx[1]|tb_out>flit$dest_x, >top>yy[y]>xx[1]|tb_out>flit$dest_y, >top>yy[y]>xx[1]|tb_out>flit$vc);
                     \$display("\|\%1h\%1h\%1h\|\%1h\%1h\%1h\|   \|\%1h\%1h\%1h\|\%1h\%1h\%1h\|", >top>yy[y]>xx[0]|tb_gen>flit%+0$src_x, >top>yy[y]>xx[0]|tb_gen>flit%+0$src_y, >top>yy[y]>xx[0]|tb_gen>flit%+0$vc, >top>yy[y]>xx[1]|tb_gen>flit%+0$src_x, >top>yy[y]>xx[1]|tb_gen>flit%+0$src_y, >top>yy[y]>xx[1]|tb_gen>flit%+0$vc, >top>yy[y]>xx[0]|tb_out>flit$src_x, >top>yy[y]>xx[0]|tb_out>flit$src_y, >top>yy[y]>xx[0]|tb_out>flit$vc, >top>yy[y]>xx[1]|tb_out>flit$src_x, >top>yy[y]>xx[1]|tb_out>flit$src_y, >top>yy[y]>xx[1]|tb_out>flit$vc);
                     \$display("\|%2h\%1h\|%2h\%1h\|   \|\%2h\%1h\|\%2h\%1h\|", >top>yy[y]>xx[0]|tb_gen>flit%+0$pkt_cnt, >top>yy[y]>xx[0]|tb_gen>flit%+0$flit_cnt, >top>yy[y]>xx[1]|tb_gen>flit%+0$pkt_cnt, >top>yy[y]>xx[1]|tb_gen>flit%+0$flit_cnt, >top>yy[y]>xx[0]|tb_out>flit$pkt_cnt, >top>yy[y]>xx[0]|tb_out>flit$flit_cnt, >top>yy[y]>xx[1]|tb_out>flit$pkt_cnt, >top>yy[y]>xx[1]|tb_out>flit$flit_cnt);
                     if (y < 1) begin
                        \$display("+---+---+   +---+---+");
                     end
                  end
                  \$display("\\\\---+---/   \\\\---+---/");
               end
            end
      @2
         // Pass the test on cycle 20.
!        *failed = (>top|tb_gen%+0$CycCnt > 16'd200);
!        *passed = (>top|tb_gen%+0$CycCnt > 16'd20) && ($FlitsInFlight == '0);
\SV
endmodule
