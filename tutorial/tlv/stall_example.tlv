\m4_TLV_version 1d: tl-x.org



// Stall pipeline macro.
// This is generic to calculation in pipeline, but not pipeline depth and pipeline names.
\TLV stall_pipeline()
   |calc2
      @0
         $ANY = /top|calc3>>1$stall ? >>1$ANY : /top|calc1>>1$ANY;
   |calc3
      @0
         $ANY = /top|calc3>>1$stall ? >>1$ANY : /top|calc2>>1$ANY;



\SV
   // Example from slide 34 of https://www.youtube.com/embed/BIwpN7za95M
   `include "sqrt32.v";

   m4_makerchip_module


\TLV
   m4+stall_pipeline()
   |calc1
      @1
         $aa_sq[31:0] = $aa * $aa;
         $bb_sq[31:0] = $bb * $bb;
   |calc2
      @1
         $cc_sq[31:0] = $aa_sq + $bb_sq;
   |calc3
      @1
         $cc[31:0] = sqrt($cc_sq);



\TLV
   // Testbench
   |calc1
      @1
         m4_rand($aa, 31, 0)
         m4_rand($bb, 31, 0)
   |calc3
      @1
         m4_rand($stall, 0, 0)
         `BOGUS_USE($cc[31:0])
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;



\SV
   endmodule
