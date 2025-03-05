\TLV_version 1a: tl-x.org
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

\TLV
   |pipeline
      >cmd[1:0]
         @0
!           $valid = *cmd_vld;
         ?$valid
            @1
!              $opcode[2:0] = *opcode[cmd];

               // Decode command.
               $incr  = $opcode == 3'b001;
               $decr  = $opcode == 3'b010;
               $other = $opcode == 3'b100;
         @2
            $accum[7:0] = *reset     ? 8'b0 :           // reset
                          (! $valid) ? $RETAIN :        // invalid, retain
                          $incr      ? ($accum#+1 + 8'b1) :  // increment
                          $decr      ? ($accum#+1 - 8'b1) :  // decrement
                          $other     ? >cmd[!cmd]$accum#+1 :
                                            // set to value of other $accum
                                            // from last cycle
                                       $RETAIN;   // illegal command, retain
         @3
            // Late decode.
            $halt = $valid && ($opcode == 3'b111);

      // Outputs
      @4
!        *halt = | >cmd[*]$halt;
         >cmd[*]
!           *accum_out[cmd] = $accum;

\SV
endmodule
