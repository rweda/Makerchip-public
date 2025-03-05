\m4_TLV_version 1d: tl-x.org
\SV
   /* An instantiation of a backpressured pipeline, passing through it a transaction that
    * is simply a transaction count.
    */

   `include "sqrt32.v";
   m4_include_url(['https://raw.githubusercontent.com/stevehoover/tlv_flow_lib/5a8c0387be80b2deccfcd1506299b36049e0663e/pipeflow_lib.tlv'])

   m5_makerchip_module

\TLV
   $reset = *reset;
   
   // Input transaction is just a transaction count.
   /in_trans
      m4_rand($avail_rand, 0, 0)
      $cnt[15:0] = /top>>1$reset ? 0 :
                   $avail        ? >>1$cnt + 1 :
                                   $RETAIN;
      
      $avail = $avail_rand && ! /top>>1$reset; // pb pipeline control input
   
   // Feed input transaction into backpressured pipeline.
   |pipe0
      @0
         $reset = /top<>0$reset;
         $ANY = /top/in_trans>>0$ANY;
   // Consume backpressure signal from bp pipeline.
   |pipe0
      @1
         `BOGUS_USE($blocked)  // backpressure not considered by input generation logic
   
   
   // The backpressured pipeline (expanded in NAV-TLV tab)
   m5+bp_pipeline(/top, |pipe, 0, 9)
   
   
   // Transaction logic in the bp pipeline, performing Pythagorean Theorem calculation
   // across three pipeline stages.
   |pipe6
      ?$accepted
         @1
            $aa_sq[7:0] = $aa[3:0] ** 2;
            $bb_sq[7:0] = $bb[3:0] ** 2;
   |pipe7
      ?$accepted
         @1
            $cc_sq[8:0] = $aa_sq + $bb_sq;
   |pipe8
      ?$accepted
         @1
            $cc[8:0] = sqrt($cc_sq);

   
   // Hook up backpressure into bp pipeline.
   |pipe9
      @1
         $blocked = /top/out_trans<<1$blocked;
      
   // Just creating a copy of the output (and backpressure from output end) to group it as such.
   /out_trans
      $ANY = /top|pipe9>>1$ANY;
      `BOGUS_USE($cnt $cc)
      // Block output 50% of the time.
      m4_rand($blocked, 0, 0);
      
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;

\SV
   endmodule
