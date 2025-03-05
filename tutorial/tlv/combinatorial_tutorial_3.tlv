\m4_TLV_version 1d: tl-x.org
\SV
   m4_makerchip_module
\TLV
   
   // Ternary operator:
   $num1[7:0] = $big ? 255 : 0;
   
   // Chained ternary operator:
   $num2[7:0] = $big    ? 255 :
                $medium ? 100 :
                $small  ? 5   :
                          0;
\SV
endmodule
