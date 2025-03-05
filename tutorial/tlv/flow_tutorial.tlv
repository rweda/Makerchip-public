\m4_TLV_version 1d: tl-x.org
\SV
/*
Copyright (c) 2018, Steve Hoover
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

m4_include_url(['https:/']['/raw.githubusercontent.com/stevehoover/tlv_flow_lib/5a8c0387be80b2deccfcd1506299b36049e0663e/fundamentals_lib.tlv'])
m4_include_url(['https:/']['/raw.githubusercontent.com/stevehoover/tlv_flow_lib/5a8c0387be80b2deccfcd1506299b36049e0663e/pipeflow_lib.tlv'])
m4_makerchip_module()

\TLV
   
   $reset = *reset;
   
   m4_define_hier(M4_PORT, 4, 0)   // Defines constants for /port[3:0].
   
   
   //-------------
   // DUT
   // ------------
   
   // DUT Flow (FIFO and ring)
   /M4_PORT_HIER   // (becomes /port[3:0])
      m4+simple_bypass_fifo_v2(/port, |fifo_in, @1, |ring_in, @1, 4, 100, /trans)
   m4+simple_ring(/port, |ring_in, @1, |ring_out, @1, /top<>0$reset, |rg, /trans)
   
   // Transaction logic.
   /port[*]
      |fifo_in
         @1
            ?$accepted
               /trans
                  $data[7:0] = *cyc_cnt[7:0];
                  // Compute parity
                  // [+] $parity = ^ {$data, $dest};
      
      |ring_out
         @2
            ?$trans_valid
               /trans
                  `BOGUS_USE($data)
               
                  // Check parity.
                  // [+] $parity_error = $parity != ^ {$data, $dest};

   //--------------
   // Testbench
   m4+router_testbench(/top, /port, |fifo_in, @1, |ring_out, @1, /trans, /top<>0$reset)
   
   
   *passed = | /top/tb/port[*]|passed>>1$passed;
   *failed = *cyc_cnt > 20;
   
\SV
endmodule 
