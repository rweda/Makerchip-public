\m5_TLV_version 1d: tl-x.org
\SV
   `include "sqrt32.v";
   m4_include_lib(https://raw.githubusercontent.com/stevehoover/makerchip_examples/refs/heads/master/pythagoras_viz.tlv)
   
   m4_makerchip_module
\TLV
   

   // DUT (Design Under Test)
   |calc
      // [+] ?$valid
      @1                                  // [>>>]
         $aa_sq[7:0] = $aa[3:0] ** 2;     // [>>>]
         $bb_sq[7:0] = $bb[3:0] ** 2;     // [>>>]
      @2                                  // [>>>]
         $cc_sq[8:0] = $aa_sq + $bb_sq;   // [>>>]
      @3                                  // [>>>]
         $cc[4:0] = sqrt($cc_sq);         // [>>>]






   // Test Bench
   |calc
      @0
         // Stimulus
         $valid = & $rand_valid[1:0];  // Valid with 1/4 probability
                                       // (& over two random bits).
      @3
         // VIZ and LOG output.
         m5+pythagorean_viz_and_log(0)
\SV
   endmodule
