\m4_TLV_version 1d: tl-x.org
\SV

// An example of a two-dimensional array (a banked register file) implemented various ways.
// The RF is written with a transaction (/top|wr/trans$ANY @0) and read into (/top|rd/trans$ANY @1).
// |rd and |wr pipelines are naturally-aligned in the sense that data written to the array from |wr is first
// visible to the stage-aligned |rd transaction.

m4_makerchip_module
m4_include_url(['https://raw.githubusercontent.com/stevehoover/tlv_flow_lib/aa1f91c9e09326e8506bd81d8a077455ddfb0606/arrays.tlv'])

\TLV
   //$reset = *reset;

   //--------------------------------------------------
   // Stimulus
   //
   
   // Explicit random inputs (same inputs for all approaches).
   
   m4_define_hier(['M4_BANK'], 2)
   m4_define_hier(['M4_ENTRY'], 4)
   |wr
      @0
         // The array hierarchy (to declare ranges)
         /M4_BANK_HIER
            /M4_ENTRY_HIER
               // These must be declared before referenced (currently).
               /trans2
               /trans3
               /trans4
         m4_rand($wr_en, 0, 0)
         ?$wr_en
            m4_rand($bank, M4_BANK_INDEX_MAX, 0)
            m4_rand($entry, M4_ENTRY_INDEX_MAX, 0)
            /trans
               m4_rand($data1, 7, 0)
               m4_rand($data2, 3, 0)
   |rd
      @1
         m4_rand($rd_en, 0, 0)
         ?$rd_en
            m4_rand($bank, M4_BANK_INDEX_MAX, 0)
            m4_rand($entry, M4_ENTRY_INDEX_MAX, 0)
         
   
   //----------------------------------------------------
   // Approach 1:
   // Utilizing SV module instantiation.
   
   // ... (not implemented)
   
   
   //----------------------------------------------------
   // Approach 2:
   // Utilizing array write.
   
   // Write Pipeline
   |wr
      @0
         // Write the transaction
         // (TLV assignment syntax prohibits assignment outside of it's own scope, but \SV_plus does not.)
         \SV_plus
            always_comb
               if ($wr_en)
                  /bank[$bank]/entry[$entry]/trans2$$ANY = /trans$ANY;
   
   // Read Pipeline
   |rd
      @1
         // Read transaction from array
         ?$rd_en
            /trans2
               $ANY = /top|wr/bank[|rd$bank]/entry[|rd$entry]/trans2<>0$ANY;
               `BOGUS_USE($data1 $data2)  // Pull transaction through.

   
   //----------------------------------------------------
   // Approach 3:
   // Write each entry every cycle (preserving value w/ recirculation).
   // Most-native TLV, but poor simulation performance today.
   
   // Write Pipeline
   |wr
      @0
         // The array hierarchy
         /bank[*]
            /entry[*]
               /trans3
                  $ANY = (|wr$wr_en && (|wr$bank == #bank) && (|wr$entry == #entry))
                              ? |wr/trans$ANY :
                                >>1$ANY;
   
   // Read Pipeline
   |rd
      @1
         // Read
         ?$rd_en
            /trans3
               $ANY = /top|wr/bank[|rd$bank]/entry[|rd$entry]/trans3<>0$ANY;
               `BOGUS_USE($data1 $data2)  // Pull transaction through.

   //----------------------------------------------------
   // Approach 4:
   // Utilizing macro, per bank.

   /M4_BANK_HIER
      // Copy of /top|wr and /top|rd per bank.
      |wr
         @0
            $wr_en = /top|wr$wr_en && /top|wr$bank == #bank;
            ?$wr_en
               $entry[M4_ENTRY_RANGE] = /top|wr$entry;
               /trans4
                  $ANY = /top|wr/trans$ANY;
      |rd
         @1
            $rd_en = /top|rd$rd_en && /top|rd$bank == #bank;
            ?$rd_en
               $entry[M4_ENTRY_RANGE] = /top|rd$entry;
      m4+array1r1w(/bank, /entry, |wr, @0, $wr_en, $entry, |rd, @1, $rd_en, $entry, $ANY, /trans4)
   // Pull read out of the bank.
   |rd
      @1
         ?$rd_en
            /trans4
               $ANY = /top/bank[|rd$bank]|rd/trans4$ANY;


   //-----------------------------------------------------
   // Checking
   
   |rd
      @1
         ?$rd_en
            /mismatch
               // A vector pulled through $ANY, with bits asserted for any mismatches between read data for
               // different implementations.
               $ANY = (|rd/trans2$ANY ^ |rd/trans3$ANY) |
                      (|rd/trans2$ANY ^ |rd/trans4$ANY);
         // $error if any mismatching data was read.
         $error = $rd_en &&
                  (| /mismatch$data1 ||
                   | /mismatch$data2);
      
      
   // Assert these to end simulation (before the cycle limit).
   *passed = *cyc_cnt > 50;
   *failed = *cyc_cnt > 4 && |rd>>2$error;

\SV
   endmodule
