\m4_TLV_version 1b --stats: tl-x.org
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
m4_include(['pipeflow_tlv.m4'])


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
      m4+flop_fifo(stop, inpipe, 1, fo, 0, >top|reset$reset, 1, 6)

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
   m4+simple_ring(stop, fo, 0, outpipe, 0, >top|reset$reset, 1)

\SV

endmodule
