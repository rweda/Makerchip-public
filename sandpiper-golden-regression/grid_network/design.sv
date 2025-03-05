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







`include "design_gen.sv"
   //_|reset
      //_@-1
         // Create pipesignal out of reset module input.
         assign RESET_reset_n1 = reset;

   // Stimulus
   //
   for (yy = 0; yy <= 1; yy++) begin : Yy logic [1:0] Xx_TB_GEN_MidPacket_a0; logic [1:0] Xx_TB_GEN_MidPacket_a1; logic [1:0] Xx_TB_GEN_head_a1; logic [1:0] Xx_TB_GEN_reset_a1; logic [1:0] Xx_TB_GEN_reset_or_head_a1; logic [1:0] Xx_TB_GEN_reset_or_trans_valid_a1; logic [1:0] Xx_TB_GEN_tail_a1; logic [1:0] Xx_TB_GEN_trans_valid_a1; logic [1:0] w_Xx_TB_GEN_Flit_head_a1; logic [1:0] Xx_TB_GEN_Flit_head_a1; logic [1:0] w_Xx_TB_GEN_Flit_tail_a1; logic [1:0] Xx_TB_GEN_Flit_tail_a1; //_>yy
      for (xx = 0; xx <= 1; xx++) begin : Xx logic [3:0] w_TB_GEN_FlitCnt_a0; logic [3:0] TB_GEN_FlitCnt_a1; logic [7:0] w_TB_GEN_PktCnt_a0; logic [7:0] TB_GEN_PktCnt_a1; logic [2:0] TB_GEN_head_tail_rand_a1; logic [2:0] TB_GEN_rand_valid_a1; logic [2-1:0] TB_GEN_vc_a1; logic [2-1:0] TB_GEN_vc_rand_a1; logic [7:0] w_TB_GEN_Flit_data_a1; logic [7:0] TB_GEN_Flit_data_a1; logic [1-1:0] w_TB_GEN_Flit_dest_x_rand_a1; logic [1-1:0] TB_GEN_Flit_dest_x_rand_a1; logic [1-1:0] w_TB_GEN_Flit_dest_y_rand_a1; logic [1-1:0] TB_GEN_Flit_dest_y_rand_a1; //_>xx
         //_|tb_gen
            // Generate stimulus feeding the E-Link input FIFO.
            //_@1
               assign Xx_TB_GEN_reset_a1[xx] = RESET_reset_a1;
               assign TB_GEN_head_tail_rand_a1[2:0] = RW_rand_vect[(0 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 3];
               assign Xx_TB_GEN_head_a1[xx] = ! Xx_TB_GEN_MidPacket_a1[xx] &&              // can be head
                       (& TB_GEN_head_tail_rand_a1) &&       // 1/8 probability
                       ! Xx_TB_GEN_reset_a1[xx] &&                  // after reset
                       (TB_GEN_CycCnt_a1 < 100);  // until max cycle
               assign Xx_TB_GEN_tail_a1[xx] = ! Xx_TB_GEN_reset_a1[xx] &&
                       (Xx_TB_GEN_head_a1[xx] || Xx_TB_GEN_MidPacket_a1[xx]) &&   // can be tail
                       ((& TB_GEN_head_tail_rand_a1) ||    // 1/8 probability
                        (TB_GEN_PktCnt_a1 >= 15));  // force tail on max length
               // $MidPacket = after head through tail.
               assign Xx_TB_GEN_MidPacket_a0[xx] = ! Xx_TB_GEN_reset_a1[xx] && ((Xx_TB_GEN_head_a1[xx] && ! Xx_TB_GEN_trans_valid_a1[xx]) || Xx_TB_GEN_MidPacket_a1[xx]) && ! (Xx_TB_GEN_tail_a1[xx] && ! Xx_TB_GEN_trans_valid_a1[xx]);
               
               // Packet and flit-within-packet counts.
               assign Xx_TB_GEN_reset_or_head_a1[xx] = Xx_TB_GEN_reset_a1[xx] || Xx_TB_GEN_head_a1[xx];
               //_?$reset_or_head
                  assign w_TB_GEN_PktCnt_a0[7:0] = Xx_TB_GEN_reset_a1[xx] ? 0 : TB_GEN_PktCnt_a1 + 1;
               assign Xx_TB_GEN_reset_or_trans_valid_a1[xx] = Xx_TB_GEN_reset_a1[xx] | Xx_TB_GEN_trans_valid_a1[xx];
               //_?$reset_or_trans_valid
                  assign w_TB_GEN_FlitCnt_a0[3:0] = (Xx_TB_GEN_reset_a1[xx] || Xx_TB_GEN_tail_a1[xx]) ? 0 : TB_GEN_FlitCnt_a1 + 1;
               
               assign TB_GEN_vc_rand_a1[2-1:0] = RW_rand_vect[(124 + ((yy * xx) ^ ((3 * yy) + yy))) % 257 +: 2];
               assign TB_GEN_vc_a1[2-1:0] = (TB_GEN_vc_rand_a1 > 3)        // out of range?
                           ? {1'b0, TB_GEN_vc_rand_a1[2-2:0]}      // drop the max bit
                           : TB_GEN_vc_rand_a1;
               assign TB_GEN_rand_valid_a1[2:0] = RW_rand_vect[(248 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 3];
               assign Xx_TB_GEN_trans_valid_a1[xx] = (Xx_TB_GEN_head_a1[xx] || Xx_TB_GEN_MidPacket_a1[xx]) && (| TB_GEN_rand_valid_a1) && ! b_Yy[yy].b_Xx[xx].Vc_TB_GEN_blocked_a1[TB_GEN_vc_a1];   // 1/8 probability of idle
               //_?$trans_valid
                  //_>flit
                     // Generate a random flit.
                     // Random values from which to generate flit:
                     assign w_TB_GEN_Flit_dest_x_rand_a1[1-1:0] = RW_rand_vect[(115 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 1];
                     assign w_TB_GEN_Flit_dest_y_rand_a1[1-1:0] = RW_rand_vect[(239 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 1];
                     // Flit:
                     assign w_Yy_Xx_TB_GEN_Flit_vc_a1[yy][xx][2-1:0] = TB_GEN_vc_a1;
                     assign w_Xx_TB_GEN_Flit_head_a1[xx] = Xx_TB_GEN_head_a1[xx];
                     assign w_Xx_TB_GEN_Flit_tail_a1[xx] = Xx_TB_GEN_tail_a1[xx];
                     assign w_Yy_Xx_TB_GEN_Flit_pkt_cnt_a1[yy][xx][7:0] = TB_GEN_PktCnt_a1;
                     assign w_Yy_Xx_TB_GEN_Flit_flit_cnt_a1[yy][xx][3:0] = TB_GEN_FlitCnt_a1;
                     assign w_Yy_Xx_TB_GEN_Flit_src_x_a1[yy][xx][1-1:0] = xx;
                     assign w_Yy_Xx_TB_GEN_Flit_src_y_a1[yy][xx][1-1:0] = yy;
                     assign w_Yy_Xx_TB_GEN_Flit_dest_x_a1[yy][xx][1-1:0] = (TB_GEN_Flit_dest_x_rand_a1 > 1) // out of range?
                                  ? {1'b0, TB_GEN_Flit_dest_x_rand_a1[1-2:0]}  // drop the max bit
                                  : TB_GEN_Flit_dest_x_rand_a1;                          // in range
                     assign w_Yy_Xx_TB_GEN_Flit_dest_y_a1[yy][xx][1-1:0] = (TB_GEN_Flit_dest_y_rand_a1 > 1) // out of range?
                                  ? {1'b0, TB_GEN_Flit_dest_y_rand_a1[1-2:0]}  // drop the max bit
                                  : TB_GEN_Flit_dest_y_rand_a1;                          // in range
                     assign w_TB_GEN_Flit_data_a1[7:0] = RW_rand_vect[(106 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 8]; end end
                     
                     
   //
   // Design
   //
   
   for (yy = 0; yy <= 1; yy++) begin : b_Yy logic [1:0] Xx_NETWK_EJECT_reset_a1; logic [1:0] Xx_NETWK_EJECT_trans_valid_a1; logic [1:0] w_Xx_NETWK_EJECT_Flit_head_a1; logic [1:0] Xx_NETWK_EJECT_Flit_head_a1; logic [1:0] w_Xx_NETWK_EJECT_Flit_tail_a1; logic [1:0] Xx_NETWK_EJECT_Flit_tail_a1; logic [1:0] Xx_NETWK_INJECT_can_bypass_fifos_a1; logic [1:0] Xx_NETWK_INJECT_fifo_trans_avail_a0; logic [1:0] Xx_NETWK_INJECT_fifo_trans_avail_a1; logic [1:0] Xx_NETWK_INJECT_trans_valid_a1; logic [1:0] Xx_NETWK_INJECT_FifosOut_fifo_trans_avail_a0; logic [1:0] w_Xx_NETWK_INJECT_FifosOut_head_a0; logic [1:0] Xx_NETWK_INJECT_FifosOut_head_a1; logic [1:0] w_Xx_NETWK_INJECT_FifosOut_tail_a0; logic [1:0] Xx_NETWK_INJECT_FifosOut_tail_a1; logic [1:0] w_Xx_NETWK_INJECT_Flit_head_a1; logic [1:0] Xx_NETWK_INJECT_Flit_head_a1; logic [1:0] w_Xx_NETWK_INJECT_Flit_tail_a1; logic [1:0] Xx_NETWK_INJECT_Flit_tail_a1; logic [1:0] Xx_TB_OUT_can_bypass_fifos_a1; logic [1:0] Xx_TB_OUT_fifo_trans_avail_a0; logic [1:0] Xx_TB_OUT_fifo_trans_avail_a1; logic [1:0] Xx_TB_OUT_trans_valid_a1; logic [1:0] Xx_TB_OUT_trans_valid_a2; logic [1:0] Xx_TB_OUT_FifosOut_fifo_trans_avail_a0; logic [1:0] w_Xx_TB_OUT_FifosOut_head_a0; logic [1:0] Xx_TB_OUT_FifosOut_head_a1; logic [1:0] w_Xx_TB_OUT_FifosOut_tail_a0; logic [1:0] Xx_TB_OUT_FifosOut_tail_a1; logic [1:0] w_Xx_TB_OUT_Flit_head_a1; logic [1:0] Xx_TB_OUT_Flit_head_a1; logic [1:0] w_Xx_TB_OUT_Flit_tail_a1; logic [1:0] Xx_TB_OUT_Flit_tail_a1; //_>yy
      for (xx = 0; xx <= 1; xx++) begin : b_Xx logic [1:0] Prio_NETWK_INJECT_avail_a0; logic [1:0] Prio_NETWK_INJECT_sel_a0; logic [1:0] Prio_TB_OUT_avail_a0; logic [1:0] Prio_TB_OUT_sel_a0; logic [3:0] Vc_NETWK_EJECT_blocked_a1; logic [3:0] Vc_NETWK_EJECT_bypass_a1; logic [3:0] Vc_NETWK_EJECT_empty_a2; logic [3:0] Vc_NETWK_EJECT_full_a2; logic [3:0] Vc_NETWK_EJECT_grow_a1; logic [3:0] Vc_NETWK_EJECT_out_blocked_a1; logic [3:0] Vc_NETWK_EJECT_push_a1; logic [3:0] Vc_NETWK_EJECT_reset_a1; logic [3:0] Vc_NETWK_EJECT_shrink_a1; logic [3:0] Vc_NETWK_EJECT_trans_avail_a1; logic [3:0] Vc_NETWK_EJECT_trans_valid_a1; logic [3:0] Vc_NETWK_EJECT_two_valid_a1; logic [3:0] Vc_NETWK_EJECT_two_valid_a2; logic [3:0] Vc_NETWK_EJECT_vc_trans_valid_a1; logic [3:0] Vc_NETWK_EJECT_would_bypass_a1; logic [3:0] w_Vc_NETWK_EJECT_Flit_head_a1; logic [3:0] Vc_NETWK_EJECT_Flit_head_a1; logic [3:0] w_Vc_NETWK_EJECT_Flit_tail_a1; logic [3:0] Vc_NETWK_EJECT_Flit_tail_a1; logic [3:0] Vc_NETWK_INJECT_Prio_n1; logic [3:0] Vc_NETWK_INJECT_Prio_a0; logic [3:0] Vc_NETWK_INJECT_arbing_a0; logic [3:0] Vc_NETWK_INJECT_blocked_a0; logic [3:0] Vc_NETWK_INJECT_bypassed_fifos_for_this_vc_a1; logic [3:0] Vc_NETWK_INJECT_can_bypass_fifos_for_this_vc_a1; logic [3:0] Vc_NETWK_INJECT_fifo_sel_a0; logic [3:0] Vc_NETWK_INJECT_has_credit_a0; logic [3:0] Vc_NETWK_INJECT_has_credit_a1; logic [3:0] Vc_NETWK_INJECT_trans_avail_a0; logic [3:0] Vc_NETWK_INJECT_trans_valid_a0; logic [3:0] Vc_NETWK_INJECT_trans_valid_a1; logic [3:0] Vc_NETWK_INJECT_vc_trans_valid_a1; logic [3:0] Vc_NETWK_INJECT_FifoHead_trans_avail_a0; logic [3:0] w_Vc_NETWK_INJECT_FifoHead_Flit_head_a0; logic [3:0] Vc_NETWK_INJECT_FifoHead_Flit_head_a0; logic [3:0] w_Vc_NETWK_INJECT_FifoHead_Flit_tail_a0; logic [3:0] Vc_NETWK_INJECT_FifoHead_Flit_tail_a0; logic [3:0] w_Vc_NETWK_INJECT_Flit_head_a0; logic [3:0] Vc_NETWK_INJECT_Flit_head_a0; logic [3:0] w_Vc_NETWK_INJECT_Flit_tail_a0; logic [3:0] Vc_NETWK_INJECT_Flit_tail_a0; logic [3:0] Vc_NETWK_INJECT_Head_trans_avail_a0; logic [3:0] w_Vc_NETWK_INJECT_Head_Flit_head_a0; logic [3:0] Vc_NETWK_INJECT_Head_Flit_head_a0; logic [3:0] w_Vc_NETWK_INJECT_Head_Flit_tail_a0; logic [3:0] Vc_NETWK_INJECT_Head_Flit_tail_a0; logic [3:0] Vc_TB_GEN_blocked_a1; logic [3:0] Vc_TB_GEN_bypass_a1; logic [3:0] Vc_TB_GEN_empty_a2; logic [3:0] Vc_TB_GEN_full_a2; logic [3:0] Vc_TB_GEN_grow_a1; logic [3:0] Vc_TB_GEN_out_blocked_a1; logic [3:0] Vc_TB_GEN_push_a1; logic [3:0] Vc_TB_GEN_reset_a1; logic [3:0] Vc_TB_GEN_shrink_a1; logic [3:0] Vc_TB_GEN_trans_avail_a1; logic [3:0] Vc_TB_GEN_trans_valid_a1; logic [3:0] Vc_TB_GEN_two_valid_a1; logic [3:0] Vc_TB_GEN_two_valid_a2; logic [3:0] Vc_TB_GEN_vc_trans_valid_a1; logic [3:0] Vc_TB_GEN_would_bypass_a1; logic [3:0] w_Vc_TB_GEN_Flit_head_a1; logic [3:0] Vc_TB_GEN_Flit_head_a1; logic [3:0] w_Vc_TB_GEN_Flit_tail_a1; logic [3:0] Vc_TB_GEN_Flit_tail_a1; logic [3:0] Vc_TB_OUT_Prio_n1; logic [3:0] Vc_TB_OUT_Prio_a0; logic [3:0] Vc_TB_OUT_arbing_a0; logic [3:0] Vc_TB_OUT_blocked_a0; logic [3:0] Vc_TB_OUT_bypassed_fifos_for_this_vc_a1; logic [3:0] Vc_TB_OUT_can_bypass_fifos_for_this_vc_a1; logic [3:0] Vc_TB_OUT_fifo_sel_a0; logic [3:0] Vc_TB_OUT_trans_avail_a0; logic [3:0] Vc_TB_OUT_trans_valid_a0; logic [3:0] Vc_TB_OUT_trans_valid_a1; logic [3:0] Vc_TB_OUT_vc_trans_valid_a1; logic [3:0] Vc_TB_OUT_FifoHead_trans_avail_a0; logic [3:0] w_Vc_TB_OUT_FifoHead_Flit_head_a0; logic [3:0] Vc_TB_OUT_FifoHead_Flit_head_a0; logic [3:0] w_Vc_TB_OUT_FifoHead_Flit_tail_a0; logic [3:0] Vc_TB_OUT_FifoHead_Flit_tail_a0; logic [3:0] w_Vc_TB_OUT_Flit_head_a0; logic [3:0] Vc_TB_OUT_Flit_head_a0; logic [3:0] w_Vc_TB_OUT_Flit_tail_a0; logic [3:0] Vc_TB_OUT_Flit_tail_a0; logic [3:0] Vc_TB_OUT_Head_trans_avail_a0; logic [3:0] w_Vc_TB_OUT_Head_Flit_head_a0; logic [3:0] Vc_TB_OUT_Head_Flit_head_a0; logic [3:0] w_Vc_TB_OUT_Head_Flit_tail_a0; logic [3:0] Vc_TB_OUT_Head_Flit_tail_a0; logic [7:0] w_NETWK_EJECT_Flit_data_a1; logic [7:0] NETWK_EJECT_Flit_data_a1; logic [1-1:0] w_NETWK_EJECT_Flit_dest_x_a1; logic [1-1:0] NETWK_EJECT_Flit_dest_x_a1; logic [1-1:0] w_NETWK_EJECT_Flit_dest_y_a1; logic [1-1:0] NETWK_EJECT_Flit_dest_y_a1; logic [3:0] w_NETWK_EJECT_Flit_flit_cnt_a1; logic [3:0] NETWK_EJECT_Flit_flit_cnt_a1; logic [7:0] w_NETWK_EJECT_Flit_pkt_cnt_a1; logic [7:0] NETWK_EJECT_Flit_pkt_cnt_a1; logic [1-1:0] w_NETWK_EJECT_Flit_src_x_a1; logic [1-1:0] NETWK_EJECT_Flit_src_x_a1; logic [1-1:0] w_NETWK_EJECT_Flit_src_y_a1; logic [1-1:0] NETWK_EJECT_Flit_src_y_a1; logic [2-1:0] w_NETWK_EJECT_Flit_vc_a1; logic [2-1:0] NETWK_EJECT_Flit_vc_a1; logic [7:0] w_NETWK_INJECT_FifosOut_data_a0; logic [7:0] NETWK_INJECT_FifosOut_data_a1; logic [1-1:0] w_NETWK_INJECT_FifosOut_dest_x_a0; logic [1-1:0] NETWK_INJECT_FifosOut_dest_x_a1; logic [1-1:0] w_NETWK_INJECT_FifosOut_dest_y_a0; logic [1-1:0] NETWK_INJECT_FifosOut_dest_y_a1; logic [3:0] w_NETWK_INJECT_FifosOut_flit_cnt_a0; logic [3:0] NETWK_INJECT_FifosOut_flit_cnt_a1; logic [7:0] w_NETWK_INJECT_FifosOut_pkt_cnt_a0; logic [7:0] NETWK_INJECT_FifosOut_pkt_cnt_a1; logic [1-1:0] w_NETWK_INJECT_FifosOut_src_x_a0; logic [1-1:0] NETWK_INJECT_FifosOut_src_x_a1; logic [1-1:0] w_NETWK_INJECT_FifosOut_src_y_a0; logic [1-1:0] NETWK_INJECT_FifosOut_src_y_a1; logic [2-1:0] w_NETWK_INJECT_FifosOut_vc_a0; logic [2-1:0] NETWK_INJECT_FifosOut_vc_a1; logic [7:0] NETWK_INJECT_FifosOut_Vc_Accum_data_a0 [3:0]; logic [1-1:0] NETWK_INJECT_FifosOut_Vc_Accum_dest_x_a0 [3:0]; logic [1-1:0] NETWK_INJECT_FifosOut_Vc_Accum_dest_y_a0 [3:0]; logic [3:0] NETWK_INJECT_FifosOut_Vc_Accum_flit_cnt_a0 [3:0]; logic [3:0] NETWK_INJECT_FifosOut_Vc_Accum_head_a0; logic [7:0] NETWK_INJECT_FifosOut_Vc_Accum_pkt_cnt_a0 [3:0]; logic [1-1:0] NETWK_INJECT_FifosOut_Vc_Accum_src_x_a0 [3:0]; logic [1-1:0] NETWK_INJECT_FifosOut_Vc_Accum_src_y_a0 [3:0]; logic [3:0] NETWK_INJECT_FifosOut_Vc_Accum_tail_a0; logic [2-1:0] NETWK_INJECT_FifosOut_Vc_Accum_vc_a0 [3:0]; logic [7:0] w_NETWK_INJECT_Flit_data_a1; logic [7:0] NETWK_INJECT_Flit_data_a1; logic [1-1:0] w_NETWK_INJECT_Flit_dest_x_a1; logic [1-1:0] NETWK_INJECT_Flit_dest_x_a1; logic [1-1:0] w_NETWK_INJECT_Flit_dest_y_a1; logic [1-1:0] NETWK_INJECT_Flit_dest_y_a1; logic [3:0] w_NETWK_INJECT_Flit_flit_cnt_a1; logic [3:0] NETWK_INJECT_Flit_flit_cnt_a1; logic [7:0] w_NETWK_INJECT_Flit_pkt_cnt_a1; logic [7:0] NETWK_INJECT_Flit_pkt_cnt_a1; logic [1-1:0] w_NETWK_INJECT_Flit_src_x_a1; logic [1-1:0] NETWK_INJECT_Flit_src_x_a1; logic [1-1:0] w_NETWK_INJECT_Flit_src_y_a1; logic [1-1:0] NETWK_INJECT_Flit_src_y_a1; logic [2-1:0] w_NETWK_INJECT_Flit_vc_a1; logic [2-1:0] NETWK_INJECT_Flit_vc_a1; logic [7:0] w_TB_OUT_FifosOut_data_a0; logic [7:0] TB_OUT_FifosOut_data_a1; logic [1-1:0] w_TB_OUT_FifosOut_dest_x_a0; logic [1-1:0] TB_OUT_FifosOut_dest_x_a1; logic [1-1:0] w_TB_OUT_FifosOut_dest_y_a0; logic [1-1:0] TB_OUT_FifosOut_dest_y_a1; logic [3:0] w_TB_OUT_FifosOut_flit_cnt_a0; logic [3:0] TB_OUT_FifosOut_flit_cnt_a1; logic [7:0] w_TB_OUT_FifosOut_pkt_cnt_a0; logic [7:0] TB_OUT_FifosOut_pkt_cnt_a1; logic [1-1:0] w_TB_OUT_FifosOut_src_x_a0; logic [1-1:0] TB_OUT_FifosOut_src_x_a1; logic [1-1:0] w_TB_OUT_FifosOut_src_y_a0; logic [1-1:0] TB_OUT_FifosOut_src_y_a1; logic [2-1:0] w_TB_OUT_FifosOut_vc_a0; logic [2-1:0] TB_OUT_FifosOut_vc_a1; logic [7:0] TB_OUT_FifosOut_Vc_Accum_data_a0 [3:0]; logic [1-1:0] TB_OUT_FifosOut_Vc_Accum_dest_x_a0 [3:0]; logic [1-1:0] TB_OUT_FifosOut_Vc_Accum_dest_y_a0 [3:0]; logic [3:0] TB_OUT_FifosOut_Vc_Accum_flit_cnt_a0 [3:0]; logic [3:0] TB_OUT_FifosOut_Vc_Accum_head_a0; logic [7:0] TB_OUT_FifosOut_Vc_Accum_pkt_cnt_a0 [3:0]; logic [1-1:0] TB_OUT_FifosOut_Vc_Accum_src_x_a0 [3:0]; logic [1-1:0] TB_OUT_FifosOut_Vc_Accum_src_y_a0 [3:0]; logic [3:0] TB_OUT_FifosOut_Vc_Accum_tail_a0; logic [2-1:0] TB_OUT_FifosOut_Vc_Accum_vc_a0 [3:0]; logic [7:0] w_TB_OUT_Flit_data_a1; logic [7:0] TB_OUT_Flit_data_a1; //_>xx
         
         // E-Link
         //
         // Into Network

         for (vc = 0; vc <= 3; vc++) begin : Vc //_>vc
            //_|tb_gen
               //_@1
                  assign Vc_TB_GEN_vc_trans_valid_a1[vc] = Yy[yy].Xx_TB_GEN_trans_valid_a1[xx] && (Yy_Xx_TB_GEN_Flit_vc_a1[yy][xx] == vc);
            //_|netwk_inject
               //_@0
                  assign Vc_NETWK_INJECT_Prio_n1[vc] = vc; end  // Prioritize based on VC.
         `line 842 "pipeflow_tlv.m4"
            for (vc = 0; vc <= 3; vc++) begin : b_Vc logic [(6)-1:0] NETWK_INJECT_Entry_is_head_a0; logic [(6)-1:0] NETWK_INJECT_Entry_pop_a0; logic [7:0] NETWK_INJECT_Entry_Accum_Flit_data_a0 [(6)-1:0]; logic [1-1:0] NETWK_INJECT_Entry_Accum_Flit_dest_x_a0 [(6)-1:0]; logic [1-1:0] NETWK_INJECT_Entry_Accum_Flit_dest_y_a0 [(6)-1:0]; logic [3:0] NETWK_INJECT_Entry_Accum_Flit_flit_cnt_a0 [(6)-1:0]; logic [(6)-1:0] NETWK_INJECT_Entry_Accum_Flit_head_a0; logic [7:0] NETWK_INJECT_Entry_Accum_Flit_pkt_cnt_a0 [(6)-1:0]; logic [1-1:0] NETWK_INJECT_Entry_Accum_Flit_src_x_a0 [(6)-1:0]; logic [1-1:0] NETWK_INJECT_Entry_Accum_Flit_src_y_a0 [(6)-1:0]; logic [(6)-1:0] NETWK_INJECT_Entry_Accum_Flit_tail_a0; logic [2-1:0] NETWK_INJECT_Entry_Accum_Flit_vc_a0 [(6)-1:0]; logic [(6)-1:0] NETWK_INJECT_Entry_ReadMasked_Flit_head_a0; logic [(6)-1:0] NETWK_INJECT_Entry_ReadMasked_Flit_tail_a0; logic [7:0] w_NETWK_INJECT_FifoHead_Flit_data_a0; logic [7:0] NETWK_INJECT_FifoHead_Flit_data_a0; logic [1-1:0] w_NETWK_INJECT_FifoHead_Flit_dest_x_a0; logic [1-1:0] NETWK_INJECT_FifoHead_Flit_dest_x_a0; logic [1-1:0] w_NETWK_INJECT_FifoHead_Flit_dest_y_a0; logic [1-1:0] NETWK_INJECT_FifoHead_Flit_dest_y_a0; logic [3:0] w_NETWK_INJECT_FifoHead_Flit_flit_cnt_a0; logic [3:0] NETWK_INJECT_FifoHead_Flit_flit_cnt_a0; logic [7:0] w_NETWK_INJECT_FifoHead_Flit_pkt_cnt_a0; logic [7:0] NETWK_INJECT_FifoHead_Flit_pkt_cnt_a0; logic [1-1:0] w_NETWK_INJECT_FifoHead_Flit_src_x_a0; logic [1-1:0] NETWK_INJECT_FifoHead_Flit_src_x_a0; logic [1-1:0] w_NETWK_INJECT_FifoHead_Flit_src_y_a0; logic [1-1:0] NETWK_INJECT_FifoHead_Flit_src_y_a0; logic [2-1:0] w_NETWK_INJECT_FifoHead_Flit_vc_a0; logic [2-1:0] NETWK_INJECT_FifoHead_Flit_vc_a0; logic [7:0] w_NETWK_INJECT_Flit_data_a0; logic [7:0] NETWK_INJECT_Flit_data_a0; logic [1-1:0] w_NETWK_INJECT_Flit_dest_x_a0; logic [1-1:0] NETWK_INJECT_Flit_dest_x_a0; logic [1-1:0] w_NETWK_INJECT_Flit_dest_y_a0; logic [1-1:0] NETWK_INJECT_Flit_dest_y_a0; logic [3:0] w_NETWK_INJECT_Flit_flit_cnt_a0; logic [3:0] NETWK_INJECT_Flit_flit_cnt_a0; logic [7:0] w_NETWK_INJECT_Flit_pkt_cnt_a0; logic [7:0] NETWK_INJECT_Flit_pkt_cnt_a0; logic [1-1:0] w_NETWK_INJECT_Flit_src_x_a0; logic [1-1:0] NETWK_INJECT_Flit_src_x_a0; logic [1-1:0] w_NETWK_INJECT_Flit_src_y_a0; logic [1-1:0] NETWK_INJECT_Flit_src_y_a0; logic [2-1:0] w_NETWK_INJECT_Flit_vc_a0; logic [2-1:0] NETWK_INJECT_Flit_vc_a0; logic [7:0] w_NETWK_INJECT_Head_Flit_data_a0; logic [7:0] NETWK_INJECT_Head_Flit_data_a0; logic [1-1:0] w_NETWK_INJECT_Head_Flit_dest_x_a0; logic [1-1:0] NETWK_INJECT_Head_Flit_dest_x_a0; logic [1-1:0] w_NETWK_INJECT_Head_Flit_dest_y_a0; logic [1-1:0] NETWK_INJECT_Head_Flit_dest_y_a0; logic [3:0] w_NETWK_INJECT_Head_Flit_flit_cnt_a0; logic [3:0] NETWK_INJECT_Head_Flit_flit_cnt_a0; logic [7:0] w_NETWK_INJECT_Head_Flit_pkt_cnt_a0; logic [7:0] NETWK_INJECT_Head_Flit_pkt_cnt_a0; logic [1-1:0] w_NETWK_INJECT_Head_Flit_src_x_a0; logic [1-1:0] NETWK_INJECT_Head_Flit_src_x_a0; logic [1-1:0] w_NETWK_INJECT_Head_Flit_src_y_a0; logic [1-1:0] NETWK_INJECT_Head_Flit_src_y_a0; logic [2-1:0] w_NETWK_INJECT_Head_Flit_vc_a0; logic [2-1:0] NETWK_INJECT_Head_Flit_vc_a0; logic [$clog2((6)+1)-1:0] TB_GEN_valid_count_a1; logic [$clog2((6)+1)-1:0] TB_GEN_valid_count_a2; logic [(6)-1:0] TB_GEN_Entry_is_head_a2; logic [(6)-1:0] TB_GEN_Entry_is_tail_a1; logic [(6)-1:0] TB_GEN_Entry_next_entry_state_a2; logic [(6)-1:0] TB_GEN_Entry_prev_entry_state_a2; logic [(6)-1:0] TB_GEN_Entry_prev_entry_was_tail_a1; logic [(6)-1:0] TB_GEN_Entry_push_a1; logic [(6)-1:0] TB_GEN_Entry_reconstructed_is_tail_a2; logic [(6)-1:0] TB_GEN_Entry_reconstructed_valid_a2; logic [(6)-1:0] TB_GEN_Entry_state_a1; logic [(6)-1:0] TB_GEN_Entry_state_a2; logic [(6)-1:0] TB_GEN_Entry_valid_a1; logic [(6)-1:0] TB_GEN_Entry_Flit_head_a1; logic [(6)-1:0] TB_GEN_Entry_Flit_head_a2; logic [(6)-1:0] TB_GEN_Entry_Flit_tail_a1; logic [(6)-1:0] TB_GEN_Entry_Flit_tail_a2; logic [7:0] w_TB_GEN_Flit_data_a1; logic [7:0] TB_GEN_Flit_data_a1; logic [1-1:0] w_TB_GEN_Flit_dest_x_a1; logic [1-1:0] TB_GEN_Flit_dest_x_a1; logic [1-1:0] w_TB_GEN_Flit_dest_y_a1; logic [1-1:0] TB_GEN_Flit_dest_y_a1; logic [3:0] w_TB_GEN_Flit_flit_cnt_a1; logic [3:0] TB_GEN_Flit_flit_cnt_a1; logic [7:0] w_TB_GEN_Flit_pkt_cnt_a1; logic [7:0] TB_GEN_Flit_pkt_cnt_a1; logic [1-1:0] w_TB_GEN_Flit_src_x_a1; logic [1-1:0] TB_GEN_Flit_src_x_a1; logic [1-1:0] w_TB_GEN_Flit_src_y_a1; logic [1-1:0] TB_GEN_Flit_src_y_a1; logic [2-1:0] w_TB_GEN_Flit_vc_a1; logic [2-1:0] TB_GEN_Flit_vc_a1; //_>vc
               //_|tb_gen
                  //_@1
                     // Apply inputs to the right VC FIFO.
                     //
         
                     assign Vc_TB_GEN_reset_a1[vc] = Yy[yy].Xx_TB_GEN_reset_a1[xx];
                     assign Vc_TB_GEN_trans_valid_a1[vc] = Vc_TB_GEN_vc_trans_valid_a1[vc] && ! Vc_NETWK_INJECT_bypassed_fifos_for_this_vc_a1[vc];
                     assign Vc_TB_GEN_trans_avail_a1[vc] = Vc_TB_GEN_trans_valid_a1[vc];
                     //_?$trans_valid
                        //_>flit
                           assign {w_TB_GEN_Flit_data_a1[7:0], w_TB_GEN_Flit_dest_x_a1[1-1:0], w_TB_GEN_Flit_dest_y_a1[1-1:0], w_TB_GEN_Flit_flit_cnt_a1[3:0], w_Vc_TB_GEN_Flit_head_a1[vc], w_TB_GEN_Flit_pkt_cnt_a1[7:0], w_TB_GEN_Flit_src_x_a1[1-1:0], w_TB_GEN_Flit_src_y_a1[1-1:0], w_Vc_TB_GEN_Flit_tail_a1[vc], w_TB_GEN_Flit_vc_a1[2-1:0]} = {Yy[yy].Xx[xx].TB_GEN_Flit_data_a1, Yy_Xx_TB_GEN_Flit_dest_x_a1[yy][xx], Yy_Xx_TB_GEN_Flit_dest_y_a1[yy][xx], Yy_Xx_TB_GEN_Flit_flit_cnt_a1[yy][xx], Yy[yy].Xx_TB_GEN_Flit_head_a1[xx], Yy_Xx_TB_GEN_Flit_pkt_cnt_a1[yy][xx], Yy_Xx_TB_GEN_Flit_src_x_a1[yy][xx], Yy_Xx_TB_GEN_Flit_src_y_a1[yy][xx], Yy[yy].Xx_TB_GEN_Flit_tail_a1[xx], Yy_Xx_TB_GEN_Flit_vc_a1[yy][xx]};
               // Instantiate FIFO.  Output to stage (m4_out_at - 1) because bypass is m4_out_at.
               `line 551 "pipeflow_tlv.m4"
                  //|default
                  //   @0
                  /*SV_plus*/
                     localparam bit [$clog2((6)+1)-1:0] full_mark_2 = 6 - 0;
               
                  // FIFO Instantiation
               
                  // Hierarchy declarations
                  //_|tb_gen
                     //_>entry
                  //_|netwk_inject
                     //_>entry
               
                  // Hierarchy
                  //_|tb_gen
                     //_@1
                        assign Vc_TB_GEN_out_blocked_a1[vc] = Vc_NETWK_INJECT_blocked_a0[vc];
                        assign Vc_TB_GEN_blocked_a1[vc] = Vc_TB_GEN_full_a2[vc] && Vc_TB_GEN_out_blocked_a1[vc];
                        `BOGUS_USE(Vc_TB_GEN_blocked_a1[vc])   // Not required to be consumed elsewhere.
                        assign Vc_TB_GEN_would_bypass_a1[vc] = Vc_TB_GEN_empty_a2[vc];
                        assign Vc_TB_GEN_bypass_a1[vc] = Vc_TB_GEN_would_bypass_a1[vc] && ! Vc_TB_GEN_out_blocked_a1[vc];
                        assign Vc_TB_GEN_push_a1[vc] = Vc_TB_GEN_trans_valid_a1[vc] && ! Vc_TB_GEN_bypass_a1[vc];
                        assign Vc_TB_GEN_grow_a1[vc]   =   Vc_TB_GEN_trans_valid_a1[vc] &&   Vc_TB_GEN_out_blocked_a1[vc];
                        assign Vc_TB_GEN_shrink_a1[vc] = ! Vc_TB_GEN_trans_avail_a1[vc] && ! Vc_TB_GEN_out_blocked_a1[vc] && ! Vc_TB_GEN_empty_a2[vc];
                        assign TB_GEN_valid_count_a1[$clog2((6)+1)-1:0] = Vc_TB_GEN_reset_a1[vc] ? '0
                                                                    : TB_GEN_valid_count_a2 + (
                                                                         Vc_TB_GEN_grow_a1[vc]   ? { {($clog2((6)+1)-1){1'b0}}, 1'b1} :
                                                                         Vc_TB_GEN_shrink_a1[vc] ? '1
                                                                                 : '0
                                                                      );
                        // At least 2 valid entries.
                        //$two_valid = | $ValidCount[m4_counter_width-1:1];
                        // but logic depth minimized by taking advantage of prev count >= 4.
                        assign Vc_TB_GEN_two_valid_a1[vc] = | TB_GEN_valid_count_a2[$clog2((6)+1)-1:2] || | TB_GEN_valid_count_a1[2:1];
                        // These are an optimization of the commented block below to operate on vectors, rather than bits.
                        // TODO: Keep optimizing...
                        assign {TB_GEN_Entry_prev_entry_was_tail_a1} = {TB_GEN_Entry_reconstructed_is_tail_a2[4:0], TB_GEN_Entry_reconstructed_is_tail_a2[5]} /* circular << */;
                        assign {TB_GEN_Entry_push_a1} = {6{Vc_TB_GEN_push_a1[vc]}} & TB_GEN_Entry_prev_entry_was_tail_a1;
                        for (entry = 0; entry <= (6)-1; entry++) begin : L4b_TB_GEN_Entry //_>entry
                           // Replaced with optimized versions above:
                           // $prev_entry_was_tail = >entry[(entry+(m4_depth)-1)%(m4_depth)]%+1$reconstructed_is_tail;
                           // $push = |m4_in_pipe$push && $prev_entry_was_tail;
                           assign TB_GEN_Entry_valid_a1[entry] = (TB_GEN_Entry_reconstructed_valid_a2[entry] && ! NETWK_INJECT_Entry_pop_a0[entry]) || TB_GEN_Entry_push_a1[entry];
                           assign TB_GEN_Entry_is_tail_a1[entry] = Vc_TB_GEN_trans_valid_a1[vc] ? TB_GEN_Entry_prev_entry_was_tail_a1[entry]  // shift tail
                                                              : TB_GEN_Entry_reconstructed_is_tail_a2[entry];  // retain tail
                           assign TB_GEN_Entry_state_a1[entry] = Vc_TB_GEN_reset_a1[vc] ? 1'b0
                                                      : TB_GEN_Entry_valid_a1[entry] && ! (Vc_TB_GEN_two_valid_a1[vc] && TB_GEN_Entry_is_tail_a1[entry]); end
                     //_@2
                        assign Vc_TB_GEN_empty_a2[vc] = ! Vc_TB_GEN_two_valid_a2[vc] && ! TB_GEN_valid_count_a2[0];
                        assign Vc_TB_GEN_full_a2[vc] = (TB_GEN_valid_count_a2 == full_mark_2);  // Could optimize for power-of-two depth.
                     for (entry = 0; entry <= (6)-1; entry++) begin : L4c_TB_GEN_Entry //_>entry
                        //_@2
                           assign TB_GEN_Entry_prev_entry_state_a2[entry] = TB_GEN_Entry_state_a2[(entry+(6)-1)%(6)];
                           assign TB_GEN_Entry_next_entry_state_a2[entry] = TB_GEN_Entry_state_a2[(entry+1)%(6)];
                           assign TB_GEN_Entry_reconstructed_is_tail_a2[entry] = (  Vc_TB_GEN_two_valid_a2[vc] && (!TB_GEN_Entry_state_a2[entry] && TB_GEN_Entry_prev_entry_state_a2[entry])) ||
                                                    (! Vc_TB_GEN_two_valid_a2[vc] && (!TB_GEN_Entry_next_entry_state_a2[entry] && TB_GEN_Entry_state_a2[entry])) ||
                                                    (Vc_TB_GEN_empty_a2[vc] && (entry == 0));  // need a tail when empty for push
                           assign TB_GEN_Entry_is_head_a2[entry] = TB_GEN_Entry_state_a2[entry] && ! TB_GEN_Entry_prev_entry_state_a2[entry];
                           assign TB_GEN_Entry_reconstructed_valid_a2[entry] = TB_GEN_Entry_state_a2[entry] || (Vc_TB_GEN_two_valid_a2[vc] && TB_GEN_Entry_prev_entry_state_a2[entry]); end
                  // Write data
                  //_|tb_gen
                     //_@1
                        for (entry = 0; entry <= (6)-1; entry++) begin : L4d_TB_GEN_Entry logic [7:0] Flit_data_a1; logic [7:0] Flit_data_a2; logic [1-1:0] Flit_dest_x_a1; logic [1-1:0] Flit_dest_x_a2; logic [1-1:0] Flit_dest_y_a1; logic [1-1:0] Flit_dest_y_a2; logic [3:0] Flit_flit_cnt_a1; logic [3:0] Flit_flit_cnt_a2; logic [7:0] Flit_pkt_cnt_a1; logic [7:0] Flit_pkt_cnt_a2; logic [1-1:0] Flit_src_x_a1; logic [1-1:0] Flit_src_x_a2; logic [1-1:0] Flit_src_y_a1; logic [1-1:0] Flit_src_y_a2; logic [2-1:0] Flit_vc_a1; logic [2-1:0] Flit_vc_a2; //_>entry
                           //?$push
                           //   $aNY = |m4_in_pipe['']m4_trans_hier$ANY;
                           //_>flit
                              assign {Flit_data_a1[7:0], Flit_dest_x_a1[1-1:0], Flit_dest_y_a1[1-1:0], Flit_flit_cnt_a1[3:0], TB_GEN_Entry_Flit_head_a1[entry], Flit_pkt_cnt_a1[7:0], Flit_src_x_a1[1-1:0], Flit_src_y_a1[1-1:0], TB_GEN_Entry_Flit_tail_a1[entry], Flit_vc_a1[2-1:0]} = TB_GEN_Entry_push_a1[entry] ? {TB_GEN_Flit_data_a1, TB_GEN_Flit_dest_x_a1, TB_GEN_Flit_dest_y_a1, TB_GEN_Flit_flit_cnt_a1, Vc_TB_GEN_Flit_head_a1[vc], TB_GEN_Flit_pkt_cnt_a1, TB_GEN_Flit_src_x_a1, TB_GEN_Flit_src_y_a1, Vc_TB_GEN_Flit_tail_a1[vc], TB_GEN_Flit_vc_a1} : {Flit_data_a2, Flit_dest_x_a2, Flit_dest_y_a2, Flit_flit_cnt_a2, TB_GEN_Entry_Flit_head_a2[entry], Flit_pkt_cnt_a2, Flit_src_x_a2, Flit_src_y_a2, TB_GEN_Entry_Flit_tail_a2[entry], Flit_vc_a2} /* RETAIN */; end
                  // Read data
                  //_|netwk_inject
                     //_@0
                        //$pop  = ! >m4_top|m4_in_pipe%m4_align(m4_in_at + 1, m4_out_at)$empty && ! $blocked;
                        for (entry = 0; entry <= (6)-1; entry++) begin : L4b_NETWK_INJECT_Entry logic [7:0] ReadMasked_Flit_data_a0; logic [1-1:0] ReadMasked_Flit_dest_x_a0; logic [1-1:0] ReadMasked_Flit_dest_y_a0; logic [3:0] ReadMasked_Flit_flit_cnt_a0; logic [7:0] ReadMasked_Flit_pkt_cnt_a0; logic [1-1:0] ReadMasked_Flit_src_x_a0; logic [1-1:0] ReadMasked_Flit_src_y_a0; logic [2-1:0] ReadMasked_Flit_vc_a0; //_>entry
                           assign NETWK_INJECT_Entry_is_head_a0[entry] = TB_GEN_Entry_is_head_a2[entry];
                           assign NETWK_INJECT_Entry_pop_a0[entry]  = NETWK_INJECT_Entry_is_head_a0[entry] && ! Vc_NETWK_INJECT_blocked_a0[vc];
                           //_>read_masked
                              //_>flit
                                 assign {ReadMasked_Flit_data_a0[7:0], ReadMasked_Flit_dest_x_a0[1-1:0], ReadMasked_Flit_dest_y_a0[1-1:0], ReadMasked_Flit_flit_cnt_a0[3:0], NETWK_INJECT_Entry_ReadMasked_Flit_head_a0[entry], ReadMasked_Flit_pkt_cnt_a0[7:0], ReadMasked_Flit_src_x_a0[1-1:0], ReadMasked_Flit_src_y_a0[1-1:0], NETWK_INJECT_Entry_ReadMasked_Flit_tail_a0[entry], ReadMasked_Flit_vc_a0[2-1:0]} = NETWK_INJECT_Entry_is_head_a0[entry] ? {L4d_TB_GEN_Entry[entry].Flit_data_a2, L4d_TB_GEN_Entry[entry].Flit_dest_x_a2, L4d_TB_GEN_Entry[entry].Flit_dest_y_a2, L4d_TB_GEN_Entry[entry].Flit_flit_cnt_a2, TB_GEN_Entry_Flit_head_a2[entry], L4d_TB_GEN_Entry[entry].Flit_pkt_cnt_a2, L4d_TB_GEN_Entry[entry].Flit_src_x_a2, L4d_TB_GEN_Entry[entry].Flit_src_y_a2, TB_GEN_Entry_Flit_tail_a2[entry], L4d_TB_GEN_Entry[entry].Flit_vc_a2} /* $aNY */ : '0;
                           //_>accum
                              //_>flit
                                 assign {NETWK_INJECT_Entry_Accum_Flit_data_a0[entry][7:0], NETWK_INJECT_Entry_Accum_Flit_dest_x_a0[entry][1-1:0], NETWK_INJECT_Entry_Accum_Flit_dest_y_a0[entry][1-1:0], NETWK_INJECT_Entry_Accum_Flit_flit_cnt_a0[entry][3:0], NETWK_INJECT_Entry_Accum_Flit_head_a0[entry], NETWK_INJECT_Entry_Accum_Flit_pkt_cnt_a0[entry][7:0], NETWK_INJECT_Entry_Accum_Flit_src_x_a0[entry][1-1:0], NETWK_INJECT_Entry_Accum_Flit_src_y_a0[entry][1-1:0], NETWK_INJECT_Entry_Accum_Flit_tail_a0[entry], NETWK_INJECT_Entry_Accum_Flit_vc_a0[entry][2-1:0]} = ((entry == 0) ? '0 : {NETWK_INJECT_Entry_Accum_Flit_data_a0[(entry+(6)-1)%(6)], NETWK_INJECT_Entry_Accum_Flit_dest_x_a0[(entry+(6)-1)%(6)], NETWK_INJECT_Entry_Accum_Flit_dest_y_a0[(entry+(6)-1)%(6)], NETWK_INJECT_Entry_Accum_Flit_flit_cnt_a0[(entry+(6)-1)%(6)], NETWK_INJECT_Entry_Accum_Flit_head_a0[(entry+(6)-1)%(6)], NETWK_INJECT_Entry_Accum_Flit_pkt_cnt_a0[(entry+(6)-1)%(6)], NETWK_INJECT_Entry_Accum_Flit_src_x_a0[(entry+(6)-1)%(6)], NETWK_INJECT_Entry_Accum_Flit_src_y_a0[(entry+(6)-1)%(6)], NETWK_INJECT_Entry_Accum_Flit_tail_a0[(entry+(6)-1)%(6)], NETWK_INJECT_Entry_Accum_Flit_vc_a0[(entry+(6)-1)%(6)]}) |
                                        {ReadMasked_Flit_data_a0, ReadMasked_Flit_dest_x_a0, ReadMasked_Flit_dest_y_a0, ReadMasked_Flit_flit_cnt_a0, NETWK_INJECT_Entry_ReadMasked_Flit_head_a0[entry], ReadMasked_Flit_pkt_cnt_a0, ReadMasked_Flit_src_x_a0, ReadMasked_Flit_src_y_a0, NETWK_INJECT_Entry_ReadMasked_Flit_tail_a0[entry], ReadMasked_Flit_vc_a0}; end
                        //_>head
                           assign Vc_NETWK_INJECT_Head_trans_avail_a0[vc] = Vc_NETWK_INJECT_trans_avail_a0[vc];
                           //_?$trans_avail
                              //_>flit
                                 assign {w_NETWK_INJECT_Head_Flit_data_a0[7:0], w_NETWK_INJECT_Head_Flit_dest_x_a0[1-1:0], w_NETWK_INJECT_Head_Flit_dest_y_a0[1-1:0], w_NETWK_INJECT_Head_Flit_flit_cnt_a0[3:0], w_Vc_NETWK_INJECT_Head_Flit_head_a0[vc], w_NETWK_INJECT_Head_Flit_pkt_cnt_a0[7:0], w_NETWK_INJECT_Head_Flit_src_x_a0[1-1:0], w_NETWK_INJECT_Head_Flit_src_y_a0[1-1:0], w_Vc_NETWK_INJECT_Head_Flit_tail_a0[vc], w_NETWK_INJECT_Head_Flit_vc_a0[2-1:0]} = {NETWK_INJECT_Entry_Accum_Flit_data_a0[(6)-1], NETWK_INJECT_Entry_Accum_Flit_dest_x_a0[(6)-1], NETWK_INJECT_Entry_Accum_Flit_dest_y_a0[(6)-1], NETWK_INJECT_Entry_Accum_Flit_flit_cnt_a0[(6)-1], NETWK_INJECT_Entry_Accum_Flit_head_a0[(6)-1], NETWK_INJECT_Entry_Accum_Flit_pkt_cnt_a0[(6)-1], NETWK_INJECT_Entry_Accum_Flit_src_x_a0[(6)-1], NETWK_INJECT_Entry_Accum_Flit_src_y_a0[(6)-1], NETWK_INJECT_Entry_Accum_Flit_tail_a0[(6)-1], NETWK_INJECT_Entry_Accum_Flit_vc_a0[(6)-1]};
               
                  // Bypass
                  //_|netwk_inject
                     //_@0
                        // Available output.  Sometimes it's necessary to know what would be coming to determined
                        // if it's blocked.  This can be used externally in that case.
                        //_>fifo_head
                           assign Vc_NETWK_INJECT_FifoHead_trans_avail_a0[vc] = Vc_NETWK_INJECT_trans_avail_a0[vc];
                           //_?$trans_avail
                              //_>flit
                                 assign {w_NETWK_INJECT_FifoHead_Flit_data_a0[7:0], w_NETWK_INJECT_FifoHead_Flit_dest_x_a0[1-1:0], w_NETWK_INJECT_FifoHead_Flit_dest_y_a0[1-1:0], w_NETWK_INJECT_FifoHead_Flit_flit_cnt_a0[3:0], w_Vc_NETWK_INJECT_FifoHead_Flit_head_a0[vc], w_NETWK_INJECT_FifoHead_Flit_pkt_cnt_a0[7:0], w_NETWK_INJECT_FifoHead_Flit_src_x_a0[1-1:0], w_NETWK_INJECT_FifoHead_Flit_src_y_a0[1-1:0], w_Vc_NETWK_INJECT_FifoHead_Flit_tail_a0[vc], w_NETWK_INJECT_FifoHead_Flit_vc_a0[2-1:0]} = Vc_TB_GEN_would_bypass_a1[vc]
                                              ? {TB_GEN_Flit_data_a1, TB_GEN_Flit_dest_x_a1, TB_GEN_Flit_dest_y_a1, TB_GEN_Flit_flit_cnt_a1, Vc_TB_GEN_Flit_head_a1[vc], TB_GEN_Flit_pkt_cnt_a1, TB_GEN_Flit_src_x_a1, TB_GEN_Flit_src_y_a1, Vc_TB_GEN_Flit_tail_a1[vc], TB_GEN_Flit_vc_a1}
                                              : {NETWK_INJECT_Head_Flit_data_a0, NETWK_INJECT_Head_Flit_dest_x_a0, NETWK_INJECT_Head_Flit_dest_y_a0, NETWK_INJECT_Head_Flit_flit_cnt_a0, Vc_NETWK_INJECT_Head_Flit_head_a0[vc], NETWK_INJECT_Head_Flit_pkt_cnt_a0, NETWK_INJECT_Head_Flit_src_x_a0, NETWK_INJECT_Head_Flit_src_y_a0, Vc_NETWK_INJECT_Head_Flit_tail_a0[vc], NETWK_INJECT_Head_Flit_vc_a0};
                        assign Vc_NETWK_INJECT_trans_avail_a0[vc] = ! Vc_TB_GEN_would_bypass_a1[vc] || Vc_TB_GEN_trans_avail_a1[vc];
                        assign Vc_NETWK_INJECT_trans_valid_a0[vc] = Vc_NETWK_INJECT_trans_avail_a0[vc] && ! Vc_NETWK_INJECT_blocked_a0[vc];
                        //_?$trans_valid
                           //_>flit
                              assign {w_NETWK_INJECT_Flit_data_a0[7:0], w_NETWK_INJECT_Flit_dest_x_a0[1-1:0], w_NETWK_INJECT_Flit_dest_y_a0[1-1:0], w_NETWK_INJECT_Flit_flit_cnt_a0[3:0], w_Vc_NETWK_INJECT_Flit_head_a0[vc], w_NETWK_INJECT_Flit_pkt_cnt_a0[7:0], w_NETWK_INJECT_Flit_src_x_a0[1-1:0], w_NETWK_INJECT_Flit_src_y_a0[1-1:0], w_Vc_NETWK_INJECT_Flit_tail_a0[vc], w_NETWK_INJECT_Flit_vc_a0[2-1:0]} = {NETWK_INJECT_FifoHead_Flit_data_a0, NETWK_INJECT_FifoHead_Flit_dest_x_a0, NETWK_INJECT_FifoHead_Flit_dest_y_a0, NETWK_INJECT_FifoHead_Flit_flit_cnt_a0, Vc_NETWK_INJECT_FifoHead_Flit_head_a0[vc], NETWK_INJECT_FifoHead_Flit_pkt_cnt_a0, NETWK_INJECT_FifoHead_Flit_src_x_a0, NETWK_INJECT_FifoHead_Flit_src_y_a0, Vc_NETWK_INJECT_FifoHead_Flit_tail_a0[vc], NETWK_INJECT_FifoHead_Flit_vc_a0};
               
               
               
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
               end //_\end_source
               `line 856 "pipeflow_tlv.m4"
         
            // FIFO select.
            //
            for (vc = 0; vc <= 3; vc++) begin : c_Vc logic [3:0] NETWK_INJECT_OtherVc_SamePrio_n1; logic [3:0] NETWK_INJECT_OtherVc_SamePrio_a0; logic [3:0] NETWK_INJECT_OtherVc_competing_a0; logic [1:0] NETWK_INJECT_Prio_Match_n1; logic [1:0] NETWK_INJECT_Prio_Match_a0; //_>vc
               //_|netwk_inject
                  //_@0
                     assign Vc_NETWK_INJECT_arbing_a0[vc] = Vc_NETWK_INJECT_trans_avail_a0[vc] && Vc_NETWK_INJECT_has_credit_a0[vc];
                     for (prio = 0; prio <= 1; prio++) begin : L4_NETWK_INJECT_Prio //_>prio
                        // Decoded priority.
                        assign NETWK_INJECT_Prio_Match_n1[prio] = prio == Vc_NETWK_INJECT_Prio_a0[vc]; end
                     // Mask of same-prio VCs.
                     for (other_vc = 0; other_vc <= 3; other_vc++) begin : L4_NETWK_INJECT_OtherVc //_>other_vc
                        assign NETWK_INJECT_OtherVc_SamePrio_n1[other_vc] = Vc_NETWK_INJECT_Prio_a0[vc] == Vc_NETWK_INJECT_Prio_a0[other_vc];
                        // Select among same-prio VCs.
                        assign NETWK_INJECT_OtherVc_competing_a0[other_vc] = NETWK_INJECT_OtherVc_SamePrio_a0[other_vc] && Vc_NETWK_INJECT_arbing_a0[other_vc]; end
                     // Select FIFO if selected within priority and this VC has the selected (max available) priority.
                     assign Vc_NETWK_INJECT_fifo_sel_a0[vc] = ((NETWK_INJECT_OtherVc_competing_a0 & ~((1 << vc) - 1)) == (1 << vc)) && | (NETWK_INJECT_Prio_Match_a0 & Prio_NETWK_INJECT_sel_a0);
                        // TODO: Need to replace m4_am_max with round-robin within priority.
                     assign Vc_NETWK_INJECT_blocked_a0[vc] = ! Vc_NETWK_INJECT_fifo_sel_a0[vc];
                  //_@1
                     // Can bypass FIFOs?
                     assign Vc_NETWK_INJECT_can_bypass_fifos_for_this_vc_a1[vc] = Vc_TB_GEN_vc_trans_valid_a1[vc] &&
                                                     Vc_TB_GEN_empty_a2[vc] &&
                                                     Vc_NETWK_INJECT_has_credit_a1[vc];
         
                     // Indicate output VC as per-VC FIFO output $trans_valid or could bypass in this VC.
                     assign Vc_NETWK_INJECT_bypassed_fifos_for_this_vc_a1[vc] = Vc_NETWK_INJECT_can_bypass_fifos_for_this_vc_a1[vc] && ! Xx_NETWK_INJECT_fifo_trans_avail_a1[xx];
                     assign Vc_NETWK_INJECT_vc_trans_valid_a1[vc] = Vc_NETWK_INJECT_trans_valid_a1[vc] || Vc_NETWK_INJECT_bypassed_fifos_for_this_vc_a1[vc];
                     `BOGUS_USE(Vc_NETWK_INJECT_vc_trans_valid_a1[vc]) end  // okay to not consume this
            for (prio = 0; prio <= 1; prio++) begin : Prio logic [3:0] NETWK_INJECT_Vc_avail_within_prio_a0; //_>prio
               //_|netwk_inject
                  //_@0
                     for (vc = 0; vc <= 3; vc++) begin : L4_NETWK_INJECT_Vc //_>vc
                        // Trans available for this prio/VC?
                        assign NETWK_INJECT_Vc_avail_within_prio_a0[vc] = Vc_NETWK_INJECT_trans_avail_a0[vc] &&
                                             c_Vc[vc].NETWK_INJECT_Prio_Match_a0[prio]; end
                     // Is this priority available in FIFOs.
                     assign Prio_NETWK_INJECT_avail_a0[prio] = | NETWK_INJECT_Vc_avail_within_prio_a0;
                     // Select this priority if its the max available.
                     assign Prio_NETWK_INJECT_sel_a0[prio] = ((Prio_NETWK_INJECT_avail_a0 & ~((1 << prio) - 1)) == (1 << prio)); end
         
            //_|netwk_inject
               //_@0
                  assign Xx_NETWK_INJECT_fifo_trans_avail_a0[xx] = | Vc_NETWK_INJECT_arbing_a0;
                  //_>fifos_out
                     assign Xx_NETWK_INJECT_FifosOut_fifo_trans_avail_a0[xx] = Xx_NETWK_INJECT_fifo_trans_avail_a0[xx];
                     //_>vc
                     `line 280 "rw_tlv.m4"
                        
                        // This is a suboptimal implementation for simulation.
                        // It does AND/OR reduction.  It would be better in simulation to simply index the desired value,
                        //   but this is not currently supported in SandPiper as it is not legal across generate loops.
                        for (vc = 0; vc <= 3; vc++) begin : b_NETWK_INJECT_FifosOut_Vc //_>vc
                           //_>accum
                              always_comb begin
                                 if (vc == $low(Vc_NETWK_INJECT_fifo_sel_a0))
                                    {NETWK_INJECT_FifosOut_Vc_Accum_data_a0[vc][7:0], NETWK_INJECT_FifosOut_Vc_Accum_dest_x_a0[vc][1-1:0], NETWK_INJECT_FifosOut_Vc_Accum_dest_y_a0[vc][1-1:0], NETWK_INJECT_FifosOut_Vc_Accum_flit_cnt_a0[vc][3:0], NETWK_INJECT_FifosOut_Vc_Accum_head_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_pkt_cnt_a0[vc][7:0], NETWK_INJECT_FifosOut_Vc_Accum_src_x_a0[vc][1-1:0], NETWK_INJECT_FifosOut_Vc_Accum_src_y_a0[vc][1-1:0], NETWK_INJECT_FifosOut_Vc_Accum_tail_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_vc_a0[vc][2-1:0]} = Vc_NETWK_INJECT_fifo_sel_a0[vc] ? {b_Vc[vc].NETWK_INJECT_Flit_data_a0, b_Vc[vc].NETWK_INJECT_Flit_dest_x_a0, b_Vc[vc].NETWK_INJECT_Flit_dest_y_a0, b_Vc[vc].NETWK_INJECT_Flit_flit_cnt_a0, Vc_NETWK_INJECT_Flit_head_a0[vc], b_Vc[vc].NETWK_INJECT_Flit_pkt_cnt_a0, b_Vc[vc].NETWK_INJECT_Flit_src_x_a0, b_Vc[vc].NETWK_INJECT_Flit_src_y_a0, Vc_NETWK_INJECT_Flit_tail_a0[vc], b_Vc[vc].NETWK_INJECT_Flit_vc_a0} : '0;
                                 else
                                    {NETWK_INJECT_FifosOut_Vc_Accum_data_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_dest_x_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_dest_y_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_flit_cnt_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_head_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_pkt_cnt_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_src_x_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_src_y_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_tail_a0[vc], NETWK_INJECT_FifosOut_Vc_Accum_vc_a0[vc]} = Vc_NETWK_INJECT_fifo_sel_a0[vc] ? {b_Vc[vc].NETWK_INJECT_Flit_data_a0, b_Vc[vc].NETWK_INJECT_Flit_dest_x_a0, b_Vc[vc].NETWK_INJECT_Flit_dest_y_a0, b_Vc[vc].NETWK_INJECT_Flit_flit_cnt_a0, Vc_NETWK_INJECT_Flit_head_a0[vc], b_Vc[vc].NETWK_INJECT_Flit_pkt_cnt_a0, b_Vc[vc].NETWK_INJECT_Flit_src_x_a0, b_Vc[vc].NETWK_INJECT_Flit_src_y_a0, Vc_NETWK_INJECT_Flit_tail_a0[vc], b_Vc[vc].NETWK_INJECT_Flit_vc_a0} : {NETWK_INJECT_FifosOut_Vc_Accum_data_a0[vc-1], NETWK_INJECT_FifosOut_Vc_Accum_dest_x_a0[vc-1], NETWK_INJECT_FifosOut_Vc_Accum_dest_y_a0[vc-1], NETWK_INJECT_FifosOut_Vc_Accum_flit_cnt_a0[vc-1], NETWK_INJECT_FifosOut_Vc_Accum_head_a0[vc-1], NETWK_INJECT_FifosOut_Vc_Accum_pkt_cnt_a0[vc-1], NETWK_INJECT_FifosOut_Vc_Accum_src_x_a0[vc-1], NETWK_INJECT_FifosOut_Vc_Accum_src_y_a0[vc-1], NETWK_INJECT_FifosOut_Vc_Accum_tail_a0[vc-1], NETWK_INJECT_FifosOut_Vc_Accum_vc_a0[vc-1]}; end end
                                             
                        //_?$fifo_trans_avail
                           assign {w_NETWK_INJECT_FifosOut_data_a0[7:0], w_NETWK_INJECT_FifosOut_dest_x_a0[1-1:0], w_NETWK_INJECT_FifosOut_dest_y_a0[1-1:0], w_NETWK_INJECT_FifosOut_flit_cnt_a0[3:0], w_Xx_NETWK_INJECT_FifosOut_head_a0[xx], w_NETWK_INJECT_FifosOut_pkt_cnt_a0[7:0], w_NETWK_INJECT_FifosOut_src_x_a0[1-1:0], w_NETWK_INJECT_FifosOut_src_y_a0[1-1:0], w_Xx_NETWK_INJECT_FifosOut_tail_a0[xx], w_NETWK_INJECT_FifosOut_vc_a0[2-1:0]} = {NETWK_INJECT_FifosOut_Vc_Accum_data_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)], NETWK_INJECT_FifosOut_Vc_Accum_dest_x_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)], NETWK_INJECT_FifosOut_Vc_Accum_dest_y_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)], NETWK_INJECT_FifosOut_Vc_Accum_flit_cnt_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)], NETWK_INJECT_FifosOut_Vc_Accum_head_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)], NETWK_INJECT_FifosOut_Vc_Accum_pkt_cnt_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)], NETWK_INJECT_FifosOut_Vc_Accum_src_x_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)], NETWK_INJECT_FifosOut_Vc_Accum_src_y_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)], NETWK_INJECT_FifosOut_Vc_Accum_tail_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)], NETWK_INJECT_FifosOut_Vc_Accum_vc_a0[$high(Vc_NETWK_INJECT_fifo_sel_a0)]};
                                             /* Old way:
                        \always_comb
                           $$ANY = m4_init;
                           for (int i = m4_MIN; i <= m4_MAX; i++)
                              $ANY = $ANY | (>vc[i]m4_index_sig_match ? >vc[i]$ANY : '0);
                        */
                     //_\end_source
                     `line 904 "pipeflow_tlv.m4"
         
                  // Output transaction
                  //
         
               //_@1
                  // Incorporate bypass
                  // Bypass if there's no transaction from the FIFOs, and the incoming transaction is okay for output.
                  assign Xx_NETWK_INJECT_can_bypass_fifos_a1[xx] = | Vc_NETWK_INJECT_can_bypass_fifos_for_this_vc_a1;
                  assign Xx_NETWK_INJECT_trans_valid_a1[xx] = Xx_NETWK_INJECT_fifo_trans_avail_a1[xx] || Xx_NETWK_INJECT_can_bypass_fifos_a1[xx];
                  //_?$trans_valid
                     //_>flit
                        assign {w_NETWK_INJECT_Flit_data_a1[7:0], w_NETWK_INJECT_Flit_dest_x_a1[1-1:0], w_NETWK_INJECT_Flit_dest_y_a1[1-1:0], w_NETWK_INJECT_Flit_flit_cnt_a1[3:0], w_Xx_NETWK_INJECT_Flit_head_a1[xx], w_NETWK_INJECT_Flit_pkt_cnt_a1[7:0], w_NETWK_INJECT_Flit_src_x_a1[1-1:0], w_NETWK_INJECT_Flit_src_y_a1[1-1:0], w_Xx_NETWK_INJECT_Flit_tail_a1[xx], w_NETWK_INJECT_Flit_vc_a1[2-1:0]} = Xx_NETWK_INJECT_fifo_trans_avail_a1[xx] ? {NETWK_INJECT_FifosOut_data_a1, NETWK_INJECT_FifosOut_dest_x_a1, NETWK_INJECT_FifosOut_dest_y_a1, NETWK_INJECT_FifosOut_flit_cnt_a1, Xx_NETWK_INJECT_FifosOut_head_a1[xx], NETWK_INJECT_FifosOut_pkt_cnt_a1, NETWK_INJECT_FifosOut_src_x_a1, NETWK_INJECT_FifosOut_src_y_a1, Xx_NETWK_INJECT_FifosOut_tail_a1[xx], NETWK_INJECT_FifosOut_vc_a1} : {Yy[yy].Xx[xx].TB_GEN_Flit_data_a1, Yy_Xx_TB_GEN_Flit_dest_x_a1[yy][xx], Yy_Xx_TB_GEN_Flit_dest_y_a1[yy][xx], Yy_Xx_TB_GEN_Flit_flit_cnt_a1[yy][xx], Yy[yy].Xx_TB_GEN_Flit_head_a1[xx], Yy_Xx_TB_GEN_Flit_pkt_cnt_a1[yy][xx], Yy_Xx_TB_GEN_Flit_src_x_a1[yy][xx], Yy_Xx_TB_GEN_Flit_src_y_a1[yy][xx], Yy[yy].Xx_TB_GEN_Flit_tail_a1[xx], Yy_Xx_TB_GEN_Flit_vc_a1[yy][xx]};
         //_\end_source
         `line 163 "design.tlv"
         for (vc = 0; vc <= 3; vc++) begin : d_Vc //_>vc
            //_|netwk_inject
               //_@0
                  assign Vc_NETWK_INJECT_has_credit_a0[vc] = ! Vc_NETWK_EJECT_full_a2[vc]; end  // Temp loopback.  (Okay if not one-entry remaining ("full") after two-transactions previous to this (one intervening).)

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
         
         //_>vc
            
            //+// Credit, reflecting 
            //+m4_credit_counter(['            $1'], ']m4___file__[', ']m4___line__[', ['m4_['']credit_counter(...)'], $Credit, 1, 2, $reset, $push, >vc|m4_out_pipe%m4_bypass_align$trans_valid)

         for (vc = 0; vc <= 3; vc++) begin : f_Vc //_>vc
            //_|netwk_eject
               //_@1
                  assign Vc_NETWK_EJECT_vc_trans_valid_a1[vc] = Vc_NETWK_INJECT_vc_trans_valid_a1[vc]; end /* temp loopback */
         //_|netwk_eject
            //_@1
               assign Xx_NETWK_EJECT_reset_a1[xx] = RESET_reset_a1;
               assign Xx_NETWK_EJECT_trans_valid_a1[xx] = Xx_NETWK_INJECT_trans_valid_a1[xx]; /* temp loopback */
               //_?$trans_valid
                  //_>flit
                     assign {w_NETWK_EJECT_Flit_data_a1[7:0], w_NETWK_EJECT_Flit_dest_x_a1[1-1:0], w_NETWK_EJECT_Flit_dest_y_a1[1-1:0], w_NETWK_EJECT_Flit_flit_cnt_a1[3:0], w_Xx_NETWK_EJECT_Flit_head_a1[xx], w_NETWK_EJECT_Flit_pkt_cnt_a1[7:0], w_NETWK_EJECT_Flit_src_x_a1[1-1:0], w_NETWK_EJECT_Flit_src_y_a1[1-1:0], w_Xx_NETWK_EJECT_Flit_tail_a1[xx], w_NETWK_EJECT_Flit_vc_a1[2-1:0]} = /* temp loopback */ {NETWK_INJECT_Flit_data_a1, NETWK_INJECT_Flit_dest_x_a1, NETWK_INJECT_Flit_dest_y_a1, NETWK_INJECT_Flit_flit_cnt_a1, Xx_NETWK_INJECT_Flit_head_a1[xx], NETWK_INJECT_Flit_pkt_cnt_a1, NETWK_INJECT_Flit_src_x_a1, NETWK_INJECT_Flit_src_y_a1, Xx_NETWK_INJECT_Flit_tail_a1[xx], NETWK_INJECT_Flit_vc_a1};
         `line 842 "pipeflow_tlv.m4"
            for (vc = 0; vc <= 3; vc++) begin : g_Vc logic [$clog2((6)+1)-1:0] NETWK_EJECT_valid_count_a1; logic [$clog2((6)+1)-1:0] NETWK_EJECT_valid_count_a2; logic [(6)-1:0] NETWK_EJECT_Entry_is_head_a2; logic [(6)-1:0] NETWK_EJECT_Entry_is_tail_a1; logic [(6)-1:0] NETWK_EJECT_Entry_next_entry_state_a2; logic [(6)-1:0] NETWK_EJECT_Entry_prev_entry_state_a2; logic [(6)-1:0] NETWK_EJECT_Entry_prev_entry_was_tail_a1; logic [(6)-1:0] NETWK_EJECT_Entry_push_a1; logic [(6)-1:0] NETWK_EJECT_Entry_reconstructed_is_tail_a2; logic [(6)-1:0] NETWK_EJECT_Entry_reconstructed_valid_a2; logic [(6)-1:0] NETWK_EJECT_Entry_state_a1; logic [(6)-1:0] NETWK_EJECT_Entry_state_a2; logic [(6)-1:0] NETWK_EJECT_Entry_valid_a1; logic [(6)-1:0] NETWK_EJECT_Entry_Flit_head_a1; logic [(6)-1:0] NETWK_EJECT_Entry_Flit_head_a2; logic [(6)-1:0] NETWK_EJECT_Entry_Flit_tail_a1; logic [(6)-1:0] NETWK_EJECT_Entry_Flit_tail_a2; logic [7:0] w_NETWK_EJECT_Flit_data_a1; logic [7:0] NETWK_EJECT_Flit_data_a1; logic [1-1:0] w_NETWK_EJECT_Flit_dest_x_a1; logic [1-1:0] NETWK_EJECT_Flit_dest_x_a1; logic [1-1:0] w_NETWK_EJECT_Flit_dest_y_a1; logic [1-1:0] NETWK_EJECT_Flit_dest_y_a1; logic [3:0] w_NETWK_EJECT_Flit_flit_cnt_a1; logic [3:0] NETWK_EJECT_Flit_flit_cnt_a1; logic [7:0] w_NETWK_EJECT_Flit_pkt_cnt_a1; logic [7:0] NETWK_EJECT_Flit_pkt_cnt_a1; logic [1-1:0] w_NETWK_EJECT_Flit_src_x_a1; logic [1-1:0] NETWK_EJECT_Flit_src_x_a1; logic [1-1:0] w_NETWK_EJECT_Flit_src_y_a1; logic [1-1:0] NETWK_EJECT_Flit_src_y_a1; logic [2-1:0] w_NETWK_EJECT_Flit_vc_a1; logic [2-1:0] NETWK_EJECT_Flit_vc_a1; logic [(6)-1:0] TB_OUT_Entry_is_head_a0; logic [(6)-1:0] TB_OUT_Entry_pop_a0; logic [7:0] TB_OUT_Entry_Accum_Flit_data_a0 [(6)-1:0]; logic [1-1:0] TB_OUT_Entry_Accum_Flit_dest_x_a0 [(6)-1:0]; logic [1-1:0] TB_OUT_Entry_Accum_Flit_dest_y_a0 [(6)-1:0]; logic [3:0] TB_OUT_Entry_Accum_Flit_flit_cnt_a0 [(6)-1:0]; logic [(6)-1:0] TB_OUT_Entry_Accum_Flit_head_a0; logic [7:0] TB_OUT_Entry_Accum_Flit_pkt_cnt_a0 [(6)-1:0]; logic [1-1:0] TB_OUT_Entry_Accum_Flit_src_x_a0 [(6)-1:0]; logic [1-1:0] TB_OUT_Entry_Accum_Flit_src_y_a0 [(6)-1:0]; logic [(6)-1:0] TB_OUT_Entry_Accum_Flit_tail_a0; logic [2-1:0] TB_OUT_Entry_Accum_Flit_vc_a0 [(6)-1:0]; logic [(6)-1:0] TB_OUT_Entry_ReadMasked_Flit_head_a0; logic [(6)-1:0] TB_OUT_Entry_ReadMasked_Flit_tail_a0; logic [7:0] w_TB_OUT_FifoHead_Flit_data_a0; logic [7:0] TB_OUT_FifoHead_Flit_data_a0; logic [1-1:0] w_TB_OUT_FifoHead_Flit_dest_x_a0; logic [1-1:0] TB_OUT_FifoHead_Flit_dest_x_a0; logic [1-1:0] w_TB_OUT_FifoHead_Flit_dest_y_a0; logic [1-1:0] TB_OUT_FifoHead_Flit_dest_y_a0; logic [3:0] w_TB_OUT_FifoHead_Flit_flit_cnt_a0; logic [3:0] TB_OUT_FifoHead_Flit_flit_cnt_a0; logic [7:0] w_TB_OUT_FifoHead_Flit_pkt_cnt_a0; logic [7:0] TB_OUT_FifoHead_Flit_pkt_cnt_a0; logic [1-1:0] w_TB_OUT_FifoHead_Flit_src_x_a0; logic [1-1:0] TB_OUT_FifoHead_Flit_src_x_a0; logic [1-1:0] w_TB_OUT_FifoHead_Flit_src_y_a0; logic [1-1:0] TB_OUT_FifoHead_Flit_src_y_a0; logic [2-1:0] w_TB_OUT_FifoHead_Flit_vc_a0; logic [2-1:0] TB_OUT_FifoHead_Flit_vc_a0; logic [7:0] w_TB_OUT_Flit_data_a0; logic [7:0] TB_OUT_Flit_data_a0; logic [1-1:0] w_TB_OUT_Flit_dest_x_a0; logic [1-1:0] TB_OUT_Flit_dest_x_a0; logic [1-1:0] w_TB_OUT_Flit_dest_y_a0; logic [1-1:0] TB_OUT_Flit_dest_y_a0; logic [3:0] w_TB_OUT_Flit_flit_cnt_a0; logic [3:0] TB_OUT_Flit_flit_cnt_a0; logic [7:0] w_TB_OUT_Flit_pkt_cnt_a0; logic [7:0] TB_OUT_Flit_pkt_cnt_a0; logic [1-1:0] w_TB_OUT_Flit_src_x_a0; logic [1-1:0] TB_OUT_Flit_src_x_a0; logic [1-1:0] w_TB_OUT_Flit_src_y_a0; logic [1-1:0] TB_OUT_Flit_src_y_a0; logic [2-1:0] w_TB_OUT_Flit_vc_a0; logic [2-1:0] TB_OUT_Flit_vc_a0; logic [7:0] w_TB_OUT_Head_Flit_data_a0; logic [7:0] TB_OUT_Head_Flit_data_a0; logic [1-1:0] w_TB_OUT_Head_Flit_dest_x_a0; logic [1-1:0] TB_OUT_Head_Flit_dest_x_a0; logic [1-1:0] w_TB_OUT_Head_Flit_dest_y_a0; logic [1-1:0] TB_OUT_Head_Flit_dest_y_a0; logic [3:0] w_TB_OUT_Head_Flit_flit_cnt_a0; logic [3:0] TB_OUT_Head_Flit_flit_cnt_a0; logic [7:0] w_TB_OUT_Head_Flit_pkt_cnt_a0; logic [7:0] TB_OUT_Head_Flit_pkt_cnt_a0; logic [1-1:0] w_TB_OUT_Head_Flit_src_x_a0; logic [1-1:0] TB_OUT_Head_Flit_src_x_a0; logic [1-1:0] w_TB_OUT_Head_Flit_src_y_a0; logic [1-1:0] TB_OUT_Head_Flit_src_y_a0; logic [2-1:0] w_TB_OUT_Head_Flit_vc_a0; logic [2-1:0] TB_OUT_Head_Flit_vc_a0; //_>vc
               //_|netwk_eject
                  //_@1
                     // Apply inputs to the right VC FIFO.
                     //
         
                     assign Vc_NETWK_EJECT_reset_a1[vc] = Xx_NETWK_EJECT_reset_a1[xx];
                     assign Vc_NETWK_EJECT_trans_valid_a1[vc] = Vc_NETWK_EJECT_vc_trans_valid_a1[vc] && ! Vc_TB_OUT_bypassed_fifos_for_this_vc_a1[vc];
                     assign Vc_NETWK_EJECT_trans_avail_a1[vc] = Vc_NETWK_EJECT_trans_valid_a1[vc];
                     //_?$trans_valid
                        //_>flit
                           assign {w_NETWK_EJECT_Flit_data_a1[7:0], w_NETWK_EJECT_Flit_dest_x_a1[1-1:0], w_NETWK_EJECT_Flit_dest_y_a1[1-1:0], w_NETWK_EJECT_Flit_flit_cnt_a1[3:0], w_Vc_NETWK_EJECT_Flit_head_a1[vc], w_NETWK_EJECT_Flit_pkt_cnt_a1[7:0], w_NETWK_EJECT_Flit_src_x_a1[1-1:0], w_NETWK_EJECT_Flit_src_y_a1[1-1:0], w_Vc_NETWK_EJECT_Flit_tail_a1[vc], w_NETWK_EJECT_Flit_vc_a1[2-1:0]} = {NETWK_EJECT_Flit_data_a1, NETWK_EJECT_Flit_dest_x_a1, NETWK_EJECT_Flit_dest_y_a1, NETWK_EJECT_Flit_flit_cnt_a1, Xx_NETWK_EJECT_Flit_head_a1[xx], NETWK_EJECT_Flit_pkt_cnt_a1, NETWK_EJECT_Flit_src_x_a1, NETWK_EJECT_Flit_src_y_a1, Xx_NETWK_EJECT_Flit_tail_a1[xx], NETWK_EJECT_Flit_vc_a1};
               // Instantiate FIFO.  Output to stage (m4_out_at - 1) because bypass is m4_out_at.
               `line 551 "pipeflow_tlv.m4"
                  //|default
                  //   @0
                  /*SV_plus*/
                     localparam bit [$clog2((6)+1)-1:0] full_mark_5 = 6 - 1;
               
                  // FIFO Instantiation
               
                  // Hierarchy declarations
                  //_|netwk_eject
                     //_>entry
                  //_|tb_out
                     //_>entry
               
                  // Hierarchy
                  //_|netwk_eject
                     //_@1
                        assign Vc_NETWK_EJECT_out_blocked_a1[vc] = Vc_TB_OUT_blocked_a0[vc];
                        assign Vc_NETWK_EJECT_blocked_a1[vc] = Vc_NETWK_EJECT_full_a2[vc] && Vc_NETWK_EJECT_out_blocked_a1[vc];
                        `BOGUS_USE(Vc_NETWK_EJECT_blocked_a1[vc])   // Not required to be consumed elsewhere.
                        assign Vc_NETWK_EJECT_would_bypass_a1[vc] = Vc_NETWK_EJECT_empty_a2[vc];
                        assign Vc_NETWK_EJECT_bypass_a1[vc] = Vc_NETWK_EJECT_would_bypass_a1[vc] && ! Vc_NETWK_EJECT_out_blocked_a1[vc];
                        assign Vc_NETWK_EJECT_push_a1[vc] = Vc_NETWK_EJECT_trans_valid_a1[vc] && ! Vc_NETWK_EJECT_bypass_a1[vc];
                        assign Vc_NETWK_EJECT_grow_a1[vc]   =   Vc_NETWK_EJECT_trans_valid_a1[vc] &&   Vc_NETWK_EJECT_out_blocked_a1[vc];
                        assign Vc_NETWK_EJECT_shrink_a1[vc] = ! Vc_NETWK_EJECT_trans_avail_a1[vc] && ! Vc_NETWK_EJECT_out_blocked_a1[vc] && ! Vc_NETWK_EJECT_empty_a2[vc];
                        assign NETWK_EJECT_valid_count_a1[$clog2((6)+1)-1:0] = Vc_NETWK_EJECT_reset_a1[vc] ? '0
                                                                    : NETWK_EJECT_valid_count_a2 + (
                                                                         Vc_NETWK_EJECT_grow_a1[vc]   ? { {($clog2((6)+1)-1){1'b0}}, 1'b1} :
                                                                         Vc_NETWK_EJECT_shrink_a1[vc] ? '1
                                                                                 : '0
                                                                      );
                        // At least 2 valid entries.
                        //$two_valid = | $ValidCount[m4_counter_width-1:1];
                        // but logic depth minimized by taking advantage of prev count >= 4.
                        assign Vc_NETWK_EJECT_two_valid_a1[vc] = | NETWK_EJECT_valid_count_a2[$clog2((6)+1)-1:2] || | NETWK_EJECT_valid_count_a1[2:1];
                        // These are an optimization of the commented block below to operate on vectors, rather than bits.
                        // TODO: Keep optimizing...
                        assign {NETWK_EJECT_Entry_prev_entry_was_tail_a1} = {NETWK_EJECT_Entry_reconstructed_is_tail_a2[4:0], NETWK_EJECT_Entry_reconstructed_is_tail_a2[5]} /* circular << */;
                        assign {NETWK_EJECT_Entry_push_a1} = {6{Vc_NETWK_EJECT_push_a1[vc]}} & NETWK_EJECT_Entry_prev_entry_was_tail_a1;
                        for (entry = 0; entry <= (6)-1; entry++) begin : L4b_NETWK_EJECT_Entry //_>entry
                           // Replaced with optimized versions above:
                           // $prev_entry_was_tail = >entry[(entry+(m4_depth)-1)%(m4_depth)]%+1$reconstructed_is_tail;
                           // $push = |m4_in_pipe$push && $prev_entry_was_tail;
                           assign NETWK_EJECT_Entry_valid_a1[entry] = (NETWK_EJECT_Entry_reconstructed_valid_a2[entry] && ! TB_OUT_Entry_pop_a0[entry]) || NETWK_EJECT_Entry_push_a1[entry];
                           assign NETWK_EJECT_Entry_is_tail_a1[entry] = Vc_NETWK_EJECT_trans_valid_a1[vc] ? NETWK_EJECT_Entry_prev_entry_was_tail_a1[entry]  // shift tail
                                                              : NETWK_EJECT_Entry_reconstructed_is_tail_a2[entry];  // retain tail
                           assign NETWK_EJECT_Entry_state_a1[entry] = Vc_NETWK_EJECT_reset_a1[vc] ? 1'b0
                                                      : NETWK_EJECT_Entry_valid_a1[entry] && ! (Vc_NETWK_EJECT_two_valid_a1[vc] && NETWK_EJECT_Entry_is_tail_a1[entry]); end
                     //_@2
                        assign Vc_NETWK_EJECT_empty_a2[vc] = ! Vc_NETWK_EJECT_two_valid_a2[vc] && ! NETWK_EJECT_valid_count_a2[0];
                        assign Vc_NETWK_EJECT_full_a2[vc] = (NETWK_EJECT_valid_count_a2 == full_mark_5);  // Could optimize for power-of-two depth.
                     for (entry = 0; entry <= (6)-1; entry++) begin : L4c_NETWK_EJECT_Entry //_>entry
                        //_@2
                           assign NETWK_EJECT_Entry_prev_entry_state_a2[entry] = NETWK_EJECT_Entry_state_a2[(entry+(6)-1)%(6)];
                           assign NETWK_EJECT_Entry_next_entry_state_a2[entry] = NETWK_EJECT_Entry_state_a2[(entry+1)%(6)];
                           assign NETWK_EJECT_Entry_reconstructed_is_tail_a2[entry] = (  Vc_NETWK_EJECT_two_valid_a2[vc] && (!NETWK_EJECT_Entry_state_a2[entry] && NETWK_EJECT_Entry_prev_entry_state_a2[entry])) ||
                                                    (! Vc_NETWK_EJECT_two_valid_a2[vc] && (!NETWK_EJECT_Entry_next_entry_state_a2[entry] && NETWK_EJECT_Entry_state_a2[entry])) ||
                                                    (Vc_NETWK_EJECT_empty_a2[vc] && (entry == 0));  // need a tail when empty for push
                           assign NETWK_EJECT_Entry_is_head_a2[entry] = NETWK_EJECT_Entry_state_a2[entry] && ! NETWK_EJECT_Entry_prev_entry_state_a2[entry];
                           assign NETWK_EJECT_Entry_reconstructed_valid_a2[entry] = NETWK_EJECT_Entry_state_a2[entry] || (Vc_NETWK_EJECT_two_valid_a2[vc] && NETWK_EJECT_Entry_prev_entry_state_a2[entry]); end
                  // Write data
                  //_|netwk_eject
                     //_@1
                        for (entry = 0; entry <= (6)-1; entry++) begin : L4d_NETWK_EJECT_Entry logic [7:0] Flit_data_a1; logic [7:0] Flit_data_a2; logic [1-1:0] Flit_dest_x_a1; logic [1-1:0] Flit_dest_x_a2; logic [1-1:0] Flit_dest_y_a1; logic [1-1:0] Flit_dest_y_a2; logic [3:0] Flit_flit_cnt_a1; logic [3:0] Flit_flit_cnt_a2; logic [7:0] Flit_pkt_cnt_a1; logic [7:0] Flit_pkt_cnt_a2; logic [1-1:0] Flit_src_x_a1; logic [1-1:0] Flit_src_x_a2; logic [1-1:0] Flit_src_y_a1; logic [1-1:0] Flit_src_y_a2; logic [2-1:0] Flit_vc_a1; logic [2-1:0] Flit_vc_a2; //_>entry
                           //?$push
                           //   $aNY = |m4_in_pipe['']m4_trans_hier$ANY;
                           //_>flit
                              assign {Flit_data_a1[7:0], Flit_dest_x_a1[1-1:0], Flit_dest_y_a1[1-1:0], Flit_flit_cnt_a1[3:0], NETWK_EJECT_Entry_Flit_head_a1[entry], Flit_pkt_cnt_a1[7:0], Flit_src_x_a1[1-1:0], Flit_src_y_a1[1-1:0], NETWK_EJECT_Entry_Flit_tail_a1[entry], Flit_vc_a1[2-1:0]} = NETWK_EJECT_Entry_push_a1[entry] ? {NETWK_EJECT_Flit_data_a1, NETWK_EJECT_Flit_dest_x_a1, NETWK_EJECT_Flit_dest_y_a1, NETWK_EJECT_Flit_flit_cnt_a1, Vc_NETWK_EJECT_Flit_head_a1[vc], NETWK_EJECT_Flit_pkt_cnt_a1, NETWK_EJECT_Flit_src_x_a1, NETWK_EJECT_Flit_src_y_a1, Vc_NETWK_EJECT_Flit_tail_a1[vc], NETWK_EJECT_Flit_vc_a1} : {Flit_data_a2, Flit_dest_x_a2, Flit_dest_y_a2, Flit_flit_cnt_a2, NETWK_EJECT_Entry_Flit_head_a2[entry], Flit_pkt_cnt_a2, Flit_src_x_a2, Flit_src_y_a2, NETWK_EJECT_Entry_Flit_tail_a2[entry], Flit_vc_a2} /* RETAIN */; end
                  // Read data
                  //_|tb_out
                     //_@0
                        //$pop  = ! >m4_top|m4_in_pipe%m4_align(m4_in_at + 1, m4_out_at)$empty && ! $blocked;
                        for (entry = 0; entry <= (6)-1; entry++) begin : L4b_TB_OUT_Entry logic [7:0] ReadMasked_Flit_data_a0; logic [1-1:0] ReadMasked_Flit_dest_x_a0; logic [1-1:0] ReadMasked_Flit_dest_y_a0; logic [3:0] ReadMasked_Flit_flit_cnt_a0; logic [7:0] ReadMasked_Flit_pkt_cnt_a0; logic [1-1:0] ReadMasked_Flit_src_x_a0; logic [1-1:0] ReadMasked_Flit_src_y_a0; logic [2-1:0] ReadMasked_Flit_vc_a0; //_>entry
                           assign TB_OUT_Entry_is_head_a0[entry] = NETWK_EJECT_Entry_is_head_a2[entry];
                           assign TB_OUT_Entry_pop_a0[entry]  = TB_OUT_Entry_is_head_a0[entry] && ! Vc_TB_OUT_blocked_a0[vc];
                           //_>read_masked
                              //_>flit
                                 assign {ReadMasked_Flit_data_a0[7:0], ReadMasked_Flit_dest_x_a0[1-1:0], ReadMasked_Flit_dest_y_a0[1-1:0], ReadMasked_Flit_flit_cnt_a0[3:0], TB_OUT_Entry_ReadMasked_Flit_head_a0[entry], ReadMasked_Flit_pkt_cnt_a0[7:0], ReadMasked_Flit_src_x_a0[1-1:0], ReadMasked_Flit_src_y_a0[1-1:0], TB_OUT_Entry_ReadMasked_Flit_tail_a0[entry], ReadMasked_Flit_vc_a0[2-1:0]} = TB_OUT_Entry_is_head_a0[entry] ? {L4d_NETWK_EJECT_Entry[entry].Flit_data_a2, L4d_NETWK_EJECT_Entry[entry].Flit_dest_x_a2, L4d_NETWK_EJECT_Entry[entry].Flit_dest_y_a2, L4d_NETWK_EJECT_Entry[entry].Flit_flit_cnt_a2, NETWK_EJECT_Entry_Flit_head_a2[entry], L4d_NETWK_EJECT_Entry[entry].Flit_pkt_cnt_a2, L4d_NETWK_EJECT_Entry[entry].Flit_src_x_a2, L4d_NETWK_EJECT_Entry[entry].Flit_src_y_a2, NETWK_EJECT_Entry_Flit_tail_a2[entry], L4d_NETWK_EJECT_Entry[entry].Flit_vc_a2} /* $aNY */ : '0;
                           //_>accum
                              //_>flit
                                 assign {TB_OUT_Entry_Accum_Flit_data_a0[entry][7:0], TB_OUT_Entry_Accum_Flit_dest_x_a0[entry][1-1:0], TB_OUT_Entry_Accum_Flit_dest_y_a0[entry][1-1:0], TB_OUT_Entry_Accum_Flit_flit_cnt_a0[entry][3:0], TB_OUT_Entry_Accum_Flit_head_a0[entry], TB_OUT_Entry_Accum_Flit_pkt_cnt_a0[entry][7:0], TB_OUT_Entry_Accum_Flit_src_x_a0[entry][1-1:0], TB_OUT_Entry_Accum_Flit_src_y_a0[entry][1-1:0], TB_OUT_Entry_Accum_Flit_tail_a0[entry], TB_OUT_Entry_Accum_Flit_vc_a0[entry][2-1:0]} = ((entry == 0) ? '0 : {TB_OUT_Entry_Accum_Flit_data_a0[(entry+(6)-1)%(6)], TB_OUT_Entry_Accum_Flit_dest_x_a0[(entry+(6)-1)%(6)], TB_OUT_Entry_Accum_Flit_dest_y_a0[(entry+(6)-1)%(6)], TB_OUT_Entry_Accum_Flit_flit_cnt_a0[(entry+(6)-1)%(6)], TB_OUT_Entry_Accum_Flit_head_a0[(entry+(6)-1)%(6)], TB_OUT_Entry_Accum_Flit_pkt_cnt_a0[(entry+(6)-1)%(6)], TB_OUT_Entry_Accum_Flit_src_x_a0[(entry+(6)-1)%(6)], TB_OUT_Entry_Accum_Flit_src_y_a0[(entry+(6)-1)%(6)], TB_OUT_Entry_Accum_Flit_tail_a0[(entry+(6)-1)%(6)], TB_OUT_Entry_Accum_Flit_vc_a0[(entry+(6)-1)%(6)]}) |
                                        {ReadMasked_Flit_data_a0, ReadMasked_Flit_dest_x_a0, ReadMasked_Flit_dest_y_a0, ReadMasked_Flit_flit_cnt_a0, TB_OUT_Entry_ReadMasked_Flit_head_a0[entry], ReadMasked_Flit_pkt_cnt_a0, ReadMasked_Flit_src_x_a0, ReadMasked_Flit_src_y_a0, TB_OUT_Entry_ReadMasked_Flit_tail_a0[entry], ReadMasked_Flit_vc_a0}; end
                        //_>head
                           assign Vc_TB_OUT_Head_trans_avail_a0[vc] = Vc_TB_OUT_trans_avail_a0[vc];
                           //_?$trans_avail
                              //_>flit
                                 assign {w_TB_OUT_Head_Flit_data_a0[7:0], w_TB_OUT_Head_Flit_dest_x_a0[1-1:0], w_TB_OUT_Head_Flit_dest_y_a0[1-1:0], w_TB_OUT_Head_Flit_flit_cnt_a0[3:0], w_Vc_TB_OUT_Head_Flit_head_a0[vc], w_TB_OUT_Head_Flit_pkt_cnt_a0[7:0], w_TB_OUT_Head_Flit_src_x_a0[1-1:0], w_TB_OUT_Head_Flit_src_y_a0[1-1:0], w_Vc_TB_OUT_Head_Flit_tail_a0[vc], w_TB_OUT_Head_Flit_vc_a0[2-1:0]} = {TB_OUT_Entry_Accum_Flit_data_a0[(6)-1], TB_OUT_Entry_Accum_Flit_dest_x_a0[(6)-1], TB_OUT_Entry_Accum_Flit_dest_y_a0[(6)-1], TB_OUT_Entry_Accum_Flit_flit_cnt_a0[(6)-1], TB_OUT_Entry_Accum_Flit_head_a0[(6)-1], TB_OUT_Entry_Accum_Flit_pkt_cnt_a0[(6)-1], TB_OUT_Entry_Accum_Flit_src_x_a0[(6)-1], TB_OUT_Entry_Accum_Flit_src_y_a0[(6)-1], TB_OUT_Entry_Accum_Flit_tail_a0[(6)-1], TB_OUT_Entry_Accum_Flit_vc_a0[(6)-1]};
               
                  // Bypass
                  //_|tb_out
                     //_@0
                        // Available output.  Sometimes it's necessary to know what would be coming to determined
                        // if it's blocked.  This can be used externally in that case.
                        //_>fifo_head
                           assign Vc_TB_OUT_FifoHead_trans_avail_a0[vc] = Vc_TB_OUT_trans_avail_a0[vc];
                           //_?$trans_avail
                              //_>flit
                                 assign {w_TB_OUT_FifoHead_Flit_data_a0[7:0], w_TB_OUT_FifoHead_Flit_dest_x_a0[1-1:0], w_TB_OUT_FifoHead_Flit_dest_y_a0[1-1:0], w_TB_OUT_FifoHead_Flit_flit_cnt_a0[3:0], w_Vc_TB_OUT_FifoHead_Flit_head_a0[vc], w_TB_OUT_FifoHead_Flit_pkt_cnt_a0[7:0], w_TB_OUT_FifoHead_Flit_src_x_a0[1-1:0], w_TB_OUT_FifoHead_Flit_src_y_a0[1-1:0], w_Vc_TB_OUT_FifoHead_Flit_tail_a0[vc], w_TB_OUT_FifoHead_Flit_vc_a0[2-1:0]} = Vc_NETWK_EJECT_would_bypass_a1[vc]
                                              ? {NETWK_EJECT_Flit_data_a1, NETWK_EJECT_Flit_dest_x_a1, NETWK_EJECT_Flit_dest_y_a1, NETWK_EJECT_Flit_flit_cnt_a1, Vc_NETWK_EJECT_Flit_head_a1[vc], NETWK_EJECT_Flit_pkt_cnt_a1, NETWK_EJECT_Flit_src_x_a1, NETWK_EJECT_Flit_src_y_a1, Vc_NETWK_EJECT_Flit_tail_a1[vc], NETWK_EJECT_Flit_vc_a1}
                                              : {TB_OUT_Head_Flit_data_a0, TB_OUT_Head_Flit_dest_x_a0, TB_OUT_Head_Flit_dest_y_a0, TB_OUT_Head_Flit_flit_cnt_a0, Vc_TB_OUT_Head_Flit_head_a0[vc], TB_OUT_Head_Flit_pkt_cnt_a0, TB_OUT_Head_Flit_src_x_a0, TB_OUT_Head_Flit_src_y_a0, Vc_TB_OUT_Head_Flit_tail_a0[vc], TB_OUT_Head_Flit_vc_a0};
                        assign Vc_TB_OUT_trans_avail_a0[vc] = ! Vc_NETWK_EJECT_would_bypass_a1[vc] || Vc_NETWK_EJECT_trans_avail_a1[vc];
                        assign Vc_TB_OUT_trans_valid_a0[vc] = Vc_TB_OUT_trans_avail_a0[vc] && ! Vc_TB_OUT_blocked_a0[vc];
                        //_?$trans_valid
                           //_>flit
                              assign {w_TB_OUT_Flit_data_a0[7:0], w_TB_OUT_Flit_dest_x_a0[1-1:0], w_TB_OUT_Flit_dest_y_a0[1-1:0], w_TB_OUT_Flit_flit_cnt_a0[3:0], w_Vc_TB_OUT_Flit_head_a0[vc], w_TB_OUT_Flit_pkt_cnt_a0[7:0], w_TB_OUT_Flit_src_x_a0[1-1:0], w_TB_OUT_Flit_src_y_a0[1-1:0], w_Vc_TB_OUT_Flit_tail_a0[vc], w_TB_OUT_Flit_vc_a0[2-1:0]} = {TB_OUT_FifoHead_Flit_data_a0, TB_OUT_FifoHead_Flit_dest_x_a0, TB_OUT_FifoHead_Flit_dest_y_a0, TB_OUT_FifoHead_Flit_flit_cnt_a0, Vc_TB_OUT_FifoHead_Flit_head_a0[vc], TB_OUT_FifoHead_Flit_pkt_cnt_a0, TB_OUT_FifoHead_Flit_src_x_a0, TB_OUT_FifoHead_Flit_src_y_a0, Vc_TB_OUT_FifoHead_Flit_tail_a0[vc], TB_OUT_FifoHead_Flit_vc_a0};
               
               
               
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
               end //_\end_source
               `line 856 "pipeflow_tlv.m4"
         
            // FIFO select.
            //
            for (vc = 0; vc <= 3; vc++) begin : h_Vc logic [3:0] TB_OUT_OtherVc_SamePrio_n1; logic [3:0] TB_OUT_OtherVc_SamePrio_a0; logic [3:0] TB_OUT_OtherVc_competing_a0; logic [1:0] TB_OUT_Prio_Match_n1; logic [1:0] TB_OUT_Prio_Match_a0; //_>vc
               //_|tb_out
                  //_@0
                     assign Vc_TB_OUT_arbing_a0[vc] = Vc_TB_OUT_trans_avail_a0[vc] && i_Vc[vc].TB_OUT_has_credit_a0;
                     for (prio = 0; prio <= 1; prio++) begin : L4_TB_OUT_Prio //_>prio
                        // Decoded priority.
                        assign TB_OUT_Prio_Match_n1[prio] = prio == Vc_TB_OUT_Prio_a0[vc]; end
                     // Mask of same-prio VCs.
                     for (other_vc = 0; other_vc <= 3; other_vc++) begin : L4_TB_OUT_OtherVc //_>other_vc
                        assign TB_OUT_OtherVc_SamePrio_n1[other_vc] = Vc_TB_OUT_Prio_a0[vc] == Vc_TB_OUT_Prio_a0[other_vc];
                        // Select among same-prio VCs.
                        assign TB_OUT_OtherVc_competing_a0[other_vc] = TB_OUT_OtherVc_SamePrio_a0[other_vc] && Vc_TB_OUT_arbing_a0[other_vc]; end
                     // Select FIFO if selected within priority and this VC has the selected (max available) priority.
                     assign Vc_TB_OUT_fifo_sel_a0[vc] = ((TB_OUT_OtherVc_competing_a0 & ~((1 << vc) - 1)) == (1 << vc)) && | (TB_OUT_Prio_Match_a0 & Prio_TB_OUT_sel_a0);
                        // TODO: Need to replace m4_am_max with round-robin within priority.
                     assign Vc_TB_OUT_blocked_a0[vc] = ! Vc_TB_OUT_fifo_sel_a0[vc];
                  //_@1
                     // Can bypass FIFOs?
                     assign Vc_TB_OUT_can_bypass_fifos_for_this_vc_a1[vc] = Vc_NETWK_EJECT_vc_trans_valid_a1[vc] &&
                                                     Vc_NETWK_EJECT_empty_a2[vc] &&
                                                     i_Vc[vc].TB_OUT_has_credit_a1;
         
                     // Indicate output VC as per-VC FIFO output $trans_valid or could bypass in this VC.
                     assign Vc_TB_OUT_bypassed_fifos_for_this_vc_a1[vc] = Vc_TB_OUT_can_bypass_fifos_for_this_vc_a1[vc] && ! Xx_TB_OUT_fifo_trans_avail_a1[xx];
                     assign Vc_TB_OUT_vc_trans_valid_a1[vc] = Vc_TB_OUT_trans_valid_a1[vc] || Vc_TB_OUT_bypassed_fifos_for_this_vc_a1[vc];
                     `BOGUS_USE(Vc_TB_OUT_vc_trans_valid_a1[vc]) end  // okay to not consume this
            for (prio = 0; prio <= 1; prio++) begin : b_Prio logic [3:0] TB_OUT_Vc_avail_within_prio_a0; //_>prio
               //_|tb_out
                  //_@0
                     for (vc = 0; vc <= 3; vc++) begin : L4_TB_OUT_Vc //_>vc
                        // Trans available for this prio/VC?
                        assign TB_OUT_Vc_avail_within_prio_a0[vc] = Vc_TB_OUT_trans_avail_a0[vc] &&
                                             h_Vc[vc].TB_OUT_Prio_Match_a0[prio]; end
                     // Is this priority available in FIFOs.
                     assign Prio_TB_OUT_avail_a0[prio] = | TB_OUT_Vc_avail_within_prio_a0;
                     // Select this priority if its the max available.
                     assign Prio_TB_OUT_sel_a0[prio] = ((Prio_TB_OUT_avail_a0 & ~((1 << prio) - 1)) == (1 << prio)); end
         
            //_|tb_out
               //_@0
                  assign Xx_TB_OUT_fifo_trans_avail_a0[xx] = | Vc_TB_OUT_arbing_a0;
                  //_>fifos_out
                     assign Xx_TB_OUT_FifosOut_fifo_trans_avail_a0[xx] = Xx_TB_OUT_fifo_trans_avail_a0[xx];
                     //_>vc
                     `line 280 "rw_tlv.m4"
                        
                        // This is a suboptimal implementation for simulation.
                        // It does AND/OR reduction.  It would be better in simulation to simply index the desired value,
                        //   but this is not currently supported in SandPiper as it is not legal across generate loops.
                        for (vc = 0; vc <= 3; vc++) begin : L3b_TB_OUT_FifosOut_Vc //_>vc
                           //_>accum
                              always_comb begin
                                 if (vc == $low(Vc_TB_OUT_fifo_sel_a0))
                                    {TB_OUT_FifosOut_Vc_Accum_data_a0[vc][7:0], TB_OUT_FifosOut_Vc_Accum_dest_x_a0[vc][1-1:0], TB_OUT_FifosOut_Vc_Accum_dest_y_a0[vc][1-1:0], TB_OUT_FifosOut_Vc_Accum_flit_cnt_a0[vc][3:0], TB_OUT_FifosOut_Vc_Accum_head_a0[vc], TB_OUT_FifosOut_Vc_Accum_pkt_cnt_a0[vc][7:0], TB_OUT_FifosOut_Vc_Accum_src_x_a0[vc][1-1:0], TB_OUT_FifosOut_Vc_Accum_src_y_a0[vc][1-1:0], TB_OUT_FifosOut_Vc_Accum_tail_a0[vc], TB_OUT_FifosOut_Vc_Accum_vc_a0[vc][2-1:0]} = Vc_TB_OUT_fifo_sel_a0[vc] ? {g_Vc[vc].TB_OUT_Flit_data_a0, g_Vc[vc].TB_OUT_Flit_dest_x_a0, g_Vc[vc].TB_OUT_Flit_dest_y_a0, g_Vc[vc].TB_OUT_Flit_flit_cnt_a0, Vc_TB_OUT_Flit_head_a0[vc], g_Vc[vc].TB_OUT_Flit_pkt_cnt_a0, g_Vc[vc].TB_OUT_Flit_src_x_a0, g_Vc[vc].TB_OUT_Flit_src_y_a0, Vc_TB_OUT_Flit_tail_a0[vc], g_Vc[vc].TB_OUT_Flit_vc_a0} : '0;
                                 else
                                    {TB_OUT_FifosOut_Vc_Accum_data_a0[vc], TB_OUT_FifosOut_Vc_Accum_dest_x_a0[vc], TB_OUT_FifosOut_Vc_Accum_dest_y_a0[vc], TB_OUT_FifosOut_Vc_Accum_flit_cnt_a0[vc], TB_OUT_FifosOut_Vc_Accum_head_a0[vc], TB_OUT_FifosOut_Vc_Accum_pkt_cnt_a0[vc], TB_OUT_FifosOut_Vc_Accum_src_x_a0[vc], TB_OUT_FifosOut_Vc_Accum_src_y_a0[vc], TB_OUT_FifosOut_Vc_Accum_tail_a0[vc], TB_OUT_FifosOut_Vc_Accum_vc_a0[vc]} = Vc_TB_OUT_fifo_sel_a0[vc] ? {g_Vc[vc].TB_OUT_Flit_data_a0, g_Vc[vc].TB_OUT_Flit_dest_x_a0, g_Vc[vc].TB_OUT_Flit_dest_y_a0, g_Vc[vc].TB_OUT_Flit_flit_cnt_a0, Vc_TB_OUT_Flit_head_a0[vc], g_Vc[vc].TB_OUT_Flit_pkt_cnt_a0, g_Vc[vc].TB_OUT_Flit_src_x_a0, g_Vc[vc].TB_OUT_Flit_src_y_a0, Vc_TB_OUT_Flit_tail_a0[vc], g_Vc[vc].TB_OUT_Flit_vc_a0} : {TB_OUT_FifosOut_Vc_Accum_data_a0[vc-1], TB_OUT_FifosOut_Vc_Accum_dest_x_a0[vc-1], TB_OUT_FifosOut_Vc_Accum_dest_y_a0[vc-1], TB_OUT_FifosOut_Vc_Accum_flit_cnt_a0[vc-1], TB_OUT_FifosOut_Vc_Accum_head_a0[vc-1], TB_OUT_FifosOut_Vc_Accum_pkt_cnt_a0[vc-1], TB_OUT_FifosOut_Vc_Accum_src_x_a0[vc-1], TB_OUT_FifosOut_Vc_Accum_src_y_a0[vc-1], TB_OUT_FifosOut_Vc_Accum_tail_a0[vc-1], TB_OUT_FifosOut_Vc_Accum_vc_a0[vc-1]}; end end
                                             
                        //_?$fifo_trans_avail
                           assign {w_TB_OUT_FifosOut_data_a0[7:0], w_TB_OUT_FifosOut_dest_x_a0[1-1:0], w_TB_OUT_FifosOut_dest_y_a0[1-1:0], w_TB_OUT_FifosOut_flit_cnt_a0[3:0], w_Xx_TB_OUT_FifosOut_head_a0[xx], w_TB_OUT_FifosOut_pkt_cnt_a0[7:0], w_TB_OUT_FifosOut_src_x_a0[1-1:0], w_TB_OUT_FifosOut_src_y_a0[1-1:0], w_Xx_TB_OUT_FifosOut_tail_a0[xx], w_TB_OUT_FifosOut_vc_a0[2-1:0]} = {TB_OUT_FifosOut_Vc_Accum_data_a0[$high(Vc_TB_OUT_fifo_sel_a0)], TB_OUT_FifosOut_Vc_Accum_dest_x_a0[$high(Vc_TB_OUT_fifo_sel_a0)], TB_OUT_FifosOut_Vc_Accum_dest_y_a0[$high(Vc_TB_OUT_fifo_sel_a0)], TB_OUT_FifosOut_Vc_Accum_flit_cnt_a0[$high(Vc_TB_OUT_fifo_sel_a0)], TB_OUT_FifosOut_Vc_Accum_head_a0[$high(Vc_TB_OUT_fifo_sel_a0)], TB_OUT_FifosOut_Vc_Accum_pkt_cnt_a0[$high(Vc_TB_OUT_fifo_sel_a0)], TB_OUT_FifosOut_Vc_Accum_src_x_a0[$high(Vc_TB_OUT_fifo_sel_a0)], TB_OUT_FifosOut_Vc_Accum_src_y_a0[$high(Vc_TB_OUT_fifo_sel_a0)], TB_OUT_FifosOut_Vc_Accum_tail_a0[$high(Vc_TB_OUT_fifo_sel_a0)], TB_OUT_FifosOut_Vc_Accum_vc_a0[$high(Vc_TB_OUT_fifo_sel_a0)]};
                                             /* Old way:
                        \always_comb
                           $$ANY = m4_init;
                           for (int i = m4_MIN; i <= m4_MAX; i++)
                              $ANY = $ANY | (>vc[i]m4_index_sig_match ? >vc[i]$ANY : '0);
                        */
                     //_\end_source
                     `line 904 "pipeflow_tlv.m4"
         
                  // Output transaction
                  //
         
               //_@1
                  // Incorporate bypass
                  // Bypass if there's no transaction from the FIFOs, and the incoming transaction is okay for output.
                  assign Xx_TB_OUT_can_bypass_fifos_a1[xx] = | Vc_TB_OUT_can_bypass_fifos_for_this_vc_a1;
                  assign Xx_TB_OUT_trans_valid_a1[xx] = Xx_TB_OUT_fifo_trans_avail_a1[xx] || Xx_TB_OUT_can_bypass_fifos_a1[xx];
                  //_?$trans_valid
                     //_>flit
                        assign {w_TB_OUT_Flit_data_a1[7:0], w_Yy_Xx_TB_OUT_Flit_dest_x_a1[yy][xx][1-1:0], w_Yy_Xx_TB_OUT_Flit_dest_y_a1[yy][xx][1-1:0], w_Yy_Xx_TB_OUT_Flit_flit_cnt_a1[yy][xx][3:0], w_Xx_TB_OUT_Flit_head_a1[xx], w_Yy_Xx_TB_OUT_Flit_pkt_cnt_a1[yy][xx][7:0], w_Yy_Xx_TB_OUT_Flit_src_x_a1[yy][xx][1-1:0], w_Yy_Xx_TB_OUT_Flit_src_y_a1[yy][xx][1-1:0], w_Xx_TB_OUT_Flit_tail_a1[xx], w_Yy_Xx_TB_OUT_Flit_vc_a1[yy][xx][2-1:0]} = Xx_TB_OUT_fifo_trans_avail_a1[xx] ? {TB_OUT_FifosOut_data_a1, TB_OUT_FifosOut_dest_x_a1, TB_OUT_FifosOut_dest_y_a1, TB_OUT_FifosOut_flit_cnt_a1, Xx_TB_OUT_FifosOut_head_a1[xx], TB_OUT_FifosOut_pkt_cnt_a1, TB_OUT_FifosOut_src_x_a1, TB_OUT_FifosOut_src_y_a1, Xx_TB_OUT_FifosOut_tail_a1[xx], TB_OUT_FifosOut_vc_a1} : {NETWK_EJECT_Flit_data_a1, NETWK_EJECT_Flit_dest_x_a1, NETWK_EJECT_Flit_dest_y_a1, NETWK_EJECT_Flit_flit_cnt_a1, Xx_NETWK_EJECT_Flit_head_a1[xx], NETWK_EJECT_Flit_pkt_cnt_a1, NETWK_EJECT_Flit_src_x_a1, NETWK_EJECT_Flit_src_y_a1, Xx_NETWK_EJECT_Flit_tail_a1[xx], NETWK_EJECT_Flit_vc_a1};
         //_\end_source
         `line 235 "design.tlv"
         for (vc = 0; vc <= 3; vc++) begin : i_Vc logic [0:0] TB_OUT_has_credit_a0; logic [0:0] TB_OUT_has_credit_a1; //_>vc
            //_|tb_out
               //_@0
                  assign Vc_TB_OUT_Prio_n1[vc] = Vc_NETWK_INJECT_Prio_a0[vc];
                  assign TB_OUT_has_credit_a0[0:0] = RW_rand_vect[(230 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 1]; end
         //_|tb_out
            //_@1
               //_?$trans_valid
                  //_>flit
                     `BOGUS_USE(Xx_TB_OUT_Flit_head_a1[xx] Xx_TB_OUT_Flit_tail_a1[xx] TB_OUT_Flit_data_a1) end end
               
   //==========
   // Testbench
   //
   //_|tb_gen
      
      //_@-1
         // Free-running cycle count.
         assign TB_GEN_CycCnt_n2[15:0] = RESET_reset_n1 ? 16'b0 : TB_GEN_CycCnt_n1 + 16'b1;
      
      //_@1
         for (yy = 0; yy <= 1; yy++) begin : TB_GEN_Yy logic [1-1:0] L1_Xx_inj_cnt_a1 [1:0]; //_>yy
            for (xx = 0; xx <= 1; xx++) begin : Xx //_>xx
               // Keep track of how many flits were injected.
               assign L1_Xx_inj_cnt_a1[xx][1-1:0] = Yy[yy].Xx_TB_GEN_trans_valid_a1[xx] ? 1 : 0; end
            `line 207 "rw_tlv.m4"
               always_comb begin
                  TB_GEN_Yy_inj_row_sum_a1[yy][(1 + 1)-1:0] = '0;
                  for (int i = 0; i <= 1; i++)
                     TB_GEN_Yy_inj_row_sum_a1[yy][(1 + 1)-1:0] = TB_GEN_Yy_inj_row_sum_a1[yy][(1 + 1)-1:0] + L1_Xx_inj_cnt_a1[i]; end
            end //_\end_source
            `line 261 "design.tlv"
         `line 207 "rw_tlv.m4"
            always_comb begin
               TB_GEN_inj_sum_a1[(1 + 1)-1:0] = '0;
               for (int i = 0; i <= 1; i++)
                  TB_GEN_inj_sum_a1[(1 + 1)-1:0] = TB_GEN_inj_sum_a1[(1 + 1)-1:0] + TB_GEN_Yy_inj_row_sum_a1[i]; end
         //_\end_source
         `line 262 "design.tlv"
      //_@1
         assign TB_GEN_inj_cnt_a1[(1 + 1)-1:0] = RESET_reset_a1 ? '0 : TB_GEN_inj_sum_a1;
      
   //_|tb_out
        // Alignment below with |tb_gen.

      //_@1
         assign TB_OUT_reset_a1 = RESET_reset_a1;
      //_@2
         for (yy = 0; yy <= 1; yy++) begin : TB_OUT_Yy logic [1-1:0] L1_Xx_eject_cnt_a2 [1:0]; //_>yy
            for (xx = 0; xx <= 1; xx++) begin : Xx //_>xx
               // Keep track of how many flits came out.
               assign L1_Xx_eject_cnt_a2[xx][1-1:0] = b_Yy[yy].Xx_TB_OUT_trans_valid_a2[xx] ? 1 : 0; end
            `line 207 "rw_tlv.m4"
               always_comb begin
                  TB_OUT_Yy_eject_row_sum_a2[yy][(1 + 1)-1:0] = '0;
                  for (int i = 0; i <= 1; i++)
                     TB_OUT_Yy_eject_row_sum_a2[yy][(1 + 1)-1:0] = TB_OUT_Yy_eject_row_sum_a2[yy][(1 + 1)-1:0] + L1_Xx_eject_cnt_a2[i]; end
            end //_\end_source
            `line 276 "design.tlv"
         `line 207 "rw_tlv.m4"
            always_comb begin
               TB_OUT_eject_sum_a2[(1 + 1)-1:0] = '0;
               for (int i = 0; i <= 1; i++)
                  TB_OUT_eject_sum_a2[(1 + 1)-1:0] = TB_OUT_eject_sum_a2[(1 + 1)-1:0] + TB_OUT_Yy_eject_row_sum_a2[i]; end
         //_\end_source
         `line 277 "design.tlv"
         assign TB_OUT_eject_cnt_a2[(1 + 1)-1:0] = TB_OUT_reset_a2 ? '0 : TB_OUT_eject_sum_a2;
         assign TB_OUT_FlitsInFlight_a1[31:0] = TB_OUT_reset_a2 ? '0 : TB_OUT_FlitsInFlight_a2 + TB_GEN_inj_cnt_a2 - TB_OUT_eject_cnt_a2;
         
        // Refers to flit in tb_gen scope.
        // Refers to flit in tb_out scope.
      //_@2
         /*SV_plus*/
            always_ff @(posedge clk) begin
               if (! TB_OUT_reset_a2) begin
                  $display("-In-        -Out-      (Cycle: %d, Inflight: %d)", TB_GEN_CycCnt_a2, TB_OUT_FlitsInFlight_a2);
                  $display("/---+---\\   /---+---\\");
                  for(int y = 0; y <= 1; y++) begin
                     $display("|%1h%1h%1h|%1h%1h%1h|   |%1h%1h%1h|%1h%1h%1h|", Yy_Xx_TB_GEN_Flit_dest_x_a2[y][0], Yy_Xx_TB_GEN_Flit_dest_y_a2[y][0], Yy_Xx_TB_GEN_Flit_vc_a2[y][0], Yy_Xx_TB_GEN_Flit_dest_x_a2[y][1], Yy_Xx_TB_GEN_Flit_dest_y_a2[y][1], Yy_Xx_TB_GEN_Flit_vc_a2[y][1], Yy_Xx_TB_OUT_Flit_dest_x_a2[y][0], Yy_Xx_TB_OUT_Flit_dest_y_a2[y][0], Yy_Xx_TB_OUT_Flit_vc_a2[y][0], Yy_Xx_TB_OUT_Flit_dest_x_a2[y][1], Yy_Xx_TB_OUT_Flit_dest_y_a2[y][1], Yy_Xx_TB_OUT_Flit_vc_a2[y][1]);
                     $display("|%1h%1h%1h|%1h%1h%1h|   |%1h%1h%1h|%1h%1h%1h|", Yy_Xx_TB_GEN_Flit_src_x_a2[y][0], Yy_Xx_TB_GEN_Flit_src_y_a2[y][0], Yy_Xx_TB_GEN_Flit_vc_a2[y][0], Yy_Xx_TB_GEN_Flit_src_x_a2[y][1], Yy_Xx_TB_GEN_Flit_src_y_a2[y][1], Yy_Xx_TB_GEN_Flit_vc_a2[y][1], Yy_Xx_TB_OUT_Flit_src_x_a2[y][0], Yy_Xx_TB_OUT_Flit_src_y_a2[y][0], Yy_Xx_TB_OUT_Flit_vc_a2[y][0], Yy_Xx_TB_OUT_Flit_src_x_a2[y][1], Yy_Xx_TB_OUT_Flit_src_y_a2[y][1], Yy_Xx_TB_OUT_Flit_vc_a2[y][1]);
                     $display("|%2h%1h|%2h%1h|   |%2h%1h|%2h%1h|", Yy_Xx_TB_GEN_Flit_pkt_cnt_a2[y][0], Yy_Xx_TB_GEN_Flit_flit_cnt_a2[y][0], Yy_Xx_TB_GEN_Flit_pkt_cnt_a2[y][1], Yy_Xx_TB_GEN_Flit_flit_cnt_a2[y][1], Yy_Xx_TB_OUT_Flit_pkt_cnt_a2[y][0], Yy_Xx_TB_OUT_Flit_flit_cnt_a2[y][0], Yy_Xx_TB_OUT_Flit_pkt_cnt_a2[y][1], Yy_Xx_TB_OUT_Flit_flit_cnt_a2[y][1]);
                     if (y < 1) begin
                        $display("+---+---+   +---+---+");
                     end
                  end
                  $display("\\---+---/   \\---+---/");
               end
            end
      //_@2
         // Pass the test on cycle 20.
         assign failed = (TB_GEN_CycCnt_a2 > 16'd200);
         assign passed = (TB_GEN_CycCnt_a2 > 16'd20) && (TB_OUT_FlitsInFlight_a2 == '0);
//_\SV
endmodule


// Undefine macros defined by SandPiper (in "design_gen.sv").
`undef BOGUS_USE
`undef WHEN
