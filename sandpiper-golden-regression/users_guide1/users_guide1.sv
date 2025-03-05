`line 2 "users_guide1.m4out.tlv" 0

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

/* A simple example defining a Verilog module with two accumulators.
 * Accumulators ($accum) reset to zero.  Each cycle a command can be sent
 * to each accumulator to increment it, decrement it, or assign it
 * the value of the other accumulator.
 */

module example (
   // Inputs to TLV
   input clk,
   input reset,
   input [1:0] cmd_vld,
   input [2:0] opcode[1:0],
   // Outputs from TLV
   output halt;
   output [7:0] accum_out[1:0]
);

`include "users_guide1_gen.sv" //_\TLV
   //_|pipeline
      for (cmd = 0; cmd <= 1; cmd++) begin : L1_PIPELINE_Cmd //_>cmd
         //_@0
            assign PIPELINE_Cmd_valid_a0[cmd] = cmd_vld;
         //_?$valid
            //_@1
               assign PIPELINE_Cmd_opcode_a1[cmd][2:0] = opcode[cmd];

               // Decode command.
               assign w_PIPELINE_Cmd_incr_a1[cmd]  = PIPELINE_Cmd_opcode_a1[cmd] == 3'b001;
               assign w_PIPELINE_Cmd_decr_a1[cmd]  = PIPELINE_Cmd_opcode_a1[cmd] == 3'b010;
               assign w_PIPELINE_Cmd_other_a1[cmd] = PIPELINE_Cmd_opcode_a1[cmd] == 3'b100;
         //_@2
            assign PIPELINE_Cmd_accum_a2[cmd][7:0] = reset     ? 8'b0 :           // reset
                          (! PIPELINE_Cmd_valid_a2[cmd]) ? PIPELINE_Cmd_accum_a3[cmd][7:0] :        // invalid, retain
                          PIPELINE_Cmd_incr_a2[cmd]      ? (PIPELINE_Cmd_accum_a3[cmd] + 8'b1) :  // increment
                          PIPELINE_Cmd_decr_a2[cmd]      ? (PIPELINE_Cmd_accum_a3[cmd] - 8'b1) :  // decrement
                          PIPELINE_Cmd_other_a2[cmd]     ? PIPELINE_Cmd_accum_a3[!cmd] :
                                            // set to value of other $accum
                                            // from last cycle
                                       PIPELINE_Cmd_accum_a3[cmd][7:0];   // illegal command, retain
         //_@3
            // Late decode.
            assign PIPELINE_Cmd_halt_a3[cmd] = PIPELINE_Cmd_valid_a3[cmd] && (PIPELINE_Cmd_opcode_a3[cmd] == 3'b111);
      end

      // Outputs
      //_@4
         assign halt = | PIPELINE_Cmd_halt_a4;
         for (cmd = 0; cmd <= 1; cmd++) begin : L1b_PIPELINE_Cmd //_>cmd
            assign accum_out[cmd] = PIPELINE_Cmd_accum_a4[cmd];
         end

//_\SV
endmodule


// Undefine macros defined by SandPiper (in "users_guide1_gen.sv").
`undef BOGUS_USE
