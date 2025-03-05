\m5_TLV_version 1d: tl-x.org
\SV

m5_makerchip_module
m4_include_url(['https://raw.githubusercontent.com/stevehoover/tlv_flow_lib/221c93b3603bb4c72d3b024b3ec410e48f60e199/arrays.tlv'])

\TLV
   //$reset = *reset;

   //--------------------------------------------------
   // Stimulus
   //
   
   // Explicit random inputs.
   
   m4_define_hier(['M4_ENTRY'], 4)
   |wr
      @0
         // The array hierarchy (to declare ranges)
         /M4_ENTRY_HIER
         
         m4_rand($wr_en, 0, 0)
         ?$wr_en
            m4_rand($entry, M4_ENTRY_INDEX_MAX, 0)  // entry to write into
            m4_rand($data, 7, 0)  // data to write
   |rd
      @1
         m4_rand($rd_en, 0, 0)
         ?$rd_en
            m4_rand($entry, M4_ENTRY_INDEX_MAX, 0)  // entry to read from
         
   
   //----------------------------------------------------
   // The array

   m5+array1r1w(/top, /entry, |wr, @0, $wr_en, $entry, |rd, @1, $rd_en, $entry, $data[7:0], )


   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 50;
   *failed = 1'b0;

\SV
   endmodule
