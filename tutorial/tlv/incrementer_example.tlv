\m4_TLV_version 1d: tl-x.org
\SV

   // ===========
   // Incrementer
   // ===========

   // An incrementer implemented bit-level using hierarchy for the bit slice.
   // Testbench compares with result of + operator.

   m4_makerchip_module
\TLV
   m4_define(M4_WIDTH, 8)
   
   // The incrementer
   /slice[M4_WIDTH-1:0]
      // Get carry in from previous slice (or 1 into slice 0).
      $carry_in = (#slice == 0) ? 1'b1
                                : /slice[(#slice - 1) % M4_WIDTH]$carry_out;
!     $Value <= *reset ? 1'b0    // reset to zero
                       : $Value ^ $carry_in;
      $carry_out = $Value && $carry_in;
   
   // Combine output bits into a vector.
   $value[M4_WIDTH-1:0] = /slice[*]$Value;
   
   
   // Testbench
   /tb
!     $Value[M4_WIDTH-1:0] <= *reset ? M4_WIDTH'b0 : $Value + M4_WIDTH'b1;
      $error = /top$value != $Value;
   
      // End simulation
!     *failed = ! *reset && $error;
!     *passed = $Value == M4_WIDTH'd30 && *cyc_cnt >= 32'd30;
\SV
   endmodule
