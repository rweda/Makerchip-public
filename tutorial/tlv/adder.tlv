\m5_TLV_version 1d: tl-x.org
\SV
   m5_makerchip_module
\TLV
   
   // -----------------------
   // Arithmetic logic:
   $out[7:0] = $in1[6:0] + $in2[6:0];
   // -----------------------
   

   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
