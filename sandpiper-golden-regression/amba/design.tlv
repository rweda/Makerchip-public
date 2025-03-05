\m4_TLV_version 1c: tl-x.org
\SV
/*
Copyright (c) 2015, Steven F. Hoover

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * The name of Steven F. Hoover
      may not be used to endorse or promote products derived from this software
      without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* verilator lint_off MULTIDRIVEN */

m4_top_module_def(dut)


\TLV
   |bus
      // GLOBAL SIGNALS
      @0
         $hreset_n = !*reset;
      
      // MASTER (Stimulus to Slave)
      >master
         >transfer
            @0
               m4_rand($htrans, 1,0)     // (Random generation does not follow $htrans data length.
                                         //  All are treated as undefined length.)
               m4_rand($hwrite, 0,0)
               m4_rand($haddr, 31,0)     // (Ignoring sequentiality and alignment requirements.)
               m4_rand($hwdata, 31,0)
               $hsize[2:0] = 3'b010;     // 32-bit word only.
               m4_rand($hburst, 2,0)
               $hprot[6:0] = 7'b0000001; // Device-nE user data only.  (Non-cacheable, non-bufferable).
               $hmastlock = 1'b0;        // Locked transfers not supported.
               `BOGUS_USE($hburst $hmastlock $hprot $hsize)  // TODO: Use these.
      // DECODER
      >decoder
         @0
            $sel[1:0] = |bus>master>transfer$haddr[1:0];
            >slave[2:0]
               $hsel = >decoder$sel == #slave;
            
      // SLAVE
      >slave[2:0]
         @0
            >transfer
               $ANY = |bus>master>transfer$ANY;
            $write = (|bus>decoder>slave$hsel &&  >transfer$hwrite) || !|bus$hreset_n;
            $read  =  |bus>decoder>slave$hsel && !>transfer$hwrite;
            $entry_index[5:0] = >transfer$haddr[7:2];
         @1
            >entry[63:0]
               $write = >slave$write && (>slave$entry_index == #entry);
               ?$write
                  %next$Data[31:0] = *reset ? {26'b0, >slave$entry_index}  // $data = $index on reset
                                            : >slave>transfer$hwdata;      // write
            ?$read
               >transfer
                  $hrdata[31:0] = >slave>entry[$haddr[7:2]]$Data;
                  $hreadyout = 1'b1;   // Always ready.  (Does this meet the spec requirements?)
                  $hresp = 1'b0;       // No errors.
      
      // MUX (Slave to Master)
      >mux
         @1
            $valid = |bus>master>transfer$htrans != 2'b00;
            ?$valid
               $ANY = |bus>slave[|bus>decoder$sel]>transfer$ANY;  // !!! BUG with |bus>slave>transfer$hrdata signal.
      
      // MASTER (Response from Slave)
      >master
         >return_transfer
            @1
               $valid = |bus>mux$valid;
               ?$valid
                  $ANY = |bus>mux$ANY;
                  `BOGUS_USE($hrdata $hreadyout $hresp)
   
   
   // CHECKING
   |default
      @0
         %next$Cnt[15:0] = $Cnt + 16'b1;
         *passed = $Cnt == 16'd50;  // Pass after 50 cycles with no checking.

\SV
endmodule
