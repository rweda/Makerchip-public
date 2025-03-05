\m4_TLV_version 1d: tl-x.org
\SV
   m4_makerchip_module
\TLV
   $num[15:0] = *reset ? 0             // 0 if reset
                       : >>1$num + 1;  // otherwise add one to previous number
\SV
   endmodule
