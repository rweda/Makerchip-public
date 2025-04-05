\m4_TLV_version 1d: tl-x.org
\SV
   `include "sqrt32.v";
   
   // =============================================
   // Time-Division Multiplexer and De-multiplexing
   // =============================================

   // A wide vector, at a 1/4 "frequency" (1 valid cycle, followed by 3 invalid ones)
   // is time-division multiplexed (TDM) into a narrow vector, carrying one of n pieces per cycle,
   // (1st, least-significant flit in stage 0, 2nd in stage 2, etc.)
   // and this is de-multiplexed into a stream similar to the original in the same pipeline.
   // This is a useful design pattern for reducing wire routing.

   m4_makerchip_module
\TLV
   
   // Stimulus
   |in
      @0
         // Control signals
!        $reset = *reset;
         $cnt[1:0] = $reset ? 0 : >>1$cnt + 1;
         $valid = $cnt == 0 && ! $reset;
      // Random wide input vector, valid every nth cycle.
      ?$valid
         @0
            m4_rand($packet_in, 15, 0)
      // TDM the wide vector into narrow pieces.
      @0
         $flit[3:0] = >>0$valid ? >>0$packet_in[3:0] :
                      >>1$valid ? >>1$packet_in[7:4] :
                      >>2$valid ? >>2$packet_in[11:8] :
                                  >>3$packet_in[15:12];
      // Reassemble (de-multiplex) the data into its original wide form in a
      // different pipeline.
      @4  // 3 or more. Increase to add transit time.
         ?$valid
            $packet_out[15:0] = {<<3$flit, <<2$flit, <<1$flit, <>0$flit};

         // Print & check
         \always_comb
            if ($valid)
               \$display("\%h became \%h", $packet_in, $packet_out);
         $error = $reset ? 0 : >>1$error || ($valid && ($packet_in != $packet_out));
   
   
         // Assert these to end simulation (before the cycle limit).
         *passed = *cyc_cnt > 40;
         *failed = *cyc_cnt > 30 && $valid && $error;

\SV
   endmodule
