\TLV_version [\source run/gen/life/life.tlv] 1c: tl-x.org
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

module life(input logic clk, input logic reset, input logic [15:0] cyc_cnt, output logic passed, output logic failed);    /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_on UNOPTFLAT */

// -------------------------
// Parameters

// Board size
localparam X_SIZE = 10;  // Note: There's a hardcoded X_SIZE in $display statement.
localparam Y_SIZE = 10;


\TLV

   // -------------------------
   // Design

   |life
      >yy[Y_SIZE-1:0]
         >xx[X_SIZE-1:0]
            @0
!              $reset = *reset;
            @1
               // Cell logic

               // ===========
               // Population count ($cnt) of 3x3 square (with edge logic).
               
               // Sum left + me + right.
               $row_cnt[1:0] = {1'b0, (>xx[(xx + X_SIZE-1) % X_SIZE]$Alive & (xx > 0))} +
                               {1'b0, $Alive} +
                               {1'b0, (>xx[(xx + 1) % X_SIZE]$Alive & (xx < X_SIZE-1))};
               // Sum three $row_cnt's: above + mine + below.
               $cnt[3:0] = {2'b00, (>yy[(yy + Y_SIZE-1) % Y_SIZE]>xx$row_cnt & {2{(yy > 0)}})} +
                           {2'b00, $row_cnt[1:0]} +
                           {2'b00, (>yy[(yy + 1) % Y_SIZE]>xx$row_cnt & {2{(yy < Y_SIZE-1)}})};


               // ===========
               // Init state.
               
               $init_alive[0:0] = *RW_rand_vect[(0 + ((yy * xx) ^ ((3 * xx) + yy))) % 257 +: 1];


               // ===========
               // Am I alive?
               
               %next$Alive = $reset ? $init_alive :                // init
                             $Alive ? ($cnt >= 3 && $cnt <= 4) :   // stay alive
                                      ($cnt == 3);                 // born




   // -------------------------
   // Embedded testbench
   // Declare success when total live cells was above 40% and remains below 20% for 20 cycles.

   // Count live cells through accumulation, into $alive_cnt.
   // Accumulate right-to-left, then bottom-to-top through >yy[0].
   |life
      @0
!        $reset = *reset;
      @1
         >yy[*]
            >xx[*]
               \SV_plus
                  if (xx < X_SIZE - 1)
                     assign $$right_alive_accum[10:0] = >xx[xx + 1]$horiz_alive_accum;
                  else
                     assign $$right_alive_accum[10:0] = 11'b0;
               $horiz_alive_accum[10:0] = $right_alive_accum + {10'b0, $Alive};
            \SV_plus
               if (yy < Y_SIZE -1)
                  assign $$below_alive_accum[21:0] = >yy[yy + 1]$vert_alive_accum;
               else
                  assign $$below_alive_accum[21:0] = 22'b0;
            $vert_alive_accum[21:0] = $below_alive_accum + {11'b0, >yy>xx[0]$horiz_alive_accum};
         $alive_cnt[21:0] = >yy[0]$vert_alive_accum;
         $above_min_start = $alive_cnt > (((X_SIZE * Y_SIZE) >> 3) * 3);  // 3/8
         $below_max_stop  = $alive_cnt < (((X_SIZE * Y_SIZE) >> 4) * 1);  // 1/16
         %next$StartOk = $reset ? 1'b0 : ($StartOk || $above_min_start);
         %next$StopCnt[7:0] = $reset          ? 8'b0 :
                              $below_max_stop ? $StopCnt + 8'b1 :
                                                8'b0;
         *passed = $StartOk && ($StopCnt > 8'd20);

   |life
      // Print
      @1
         \SV_plus
            always_ff @(posedge clk) begin
               \$display("---------------");
               for (int y = 0; y < Y_SIZE; y++) begin
                  if (!$reset) begin
                     \$display("    %10b", >yy[y]>xx[*]$Alive);
                  end
               end
            end
\SV
endmodule
