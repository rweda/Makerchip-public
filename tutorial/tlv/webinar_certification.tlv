\m4_TLV_version 1d: tl-x.org
\SV
   `include "sqrt32.v";
   
   // ===============================
   // Webinar Certification Challenge
   // ===============================

   // Webinar participants, complete this challenge, as described in the slides,
   // and submit result to instructors.
   //
   // Perform the following computation distributed as shown in the
   // slides.
   //    leg(n+1) = sqrt((leg(n) ** 2) * 2)
   //
   // Proper syntax for this computation is below.
   // You must provide proper context for the computation.
   //    $leg[15:0] = >>???$valid ? >>???$hyp : 16'd16;
   //    $hyp_sq[32:0] = ($leg ** 2) << 1;
   //    $hyp[15:0] = sqrt($hyp_sq);

   m4_makerchip_module
\TLV
   
   // Stimulus
   |calc
      @0
!        $reset = *reset;
         $valid = (! $reset && >>1$reset) ||   // pulse after reset
                  >>2$valid;                   // valid every 2nd cycle
   
   |calc
      // FILL IN MISSING LOGIC HERE.

   // Print
   |calc
      @2
         \always_comb
            \$display("\%d", $leg);

\SV
   endmodule
