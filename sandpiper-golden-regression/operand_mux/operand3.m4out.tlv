\TLV_version [\source run/gen/operand_mux/operand3.tlv] 1d: tl-x.org
\SV
/*
Copyright (c) 2014, Intel Corporation

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Intel Corporation nor the names of its contributors
      may be used to endorse or promote products derived from this software
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
...
\source run/gen/operand_mux/operand3.tlv 35
\TLV
   // Test m4+ macro.
   \source run/gen/operand_mux/operand3.tlv 30   // Instantiated from run/gen/operand_mux/operand3.tlv, 38 as: m4+my_macro(|pipe1, @1, $test_sig)
      |pipe1
         @1
            $tmp[0:0] = *RW_rand_vect[(0 + (0)) % 257 +: 1];
            $test_sig = |pipe1$tmp;
            `BOGUS_USE($test_sig)
   \end_source
   
   // Context:
   |inst
      @2
         $valid = ...;
      @3
         $op_a_src[3:0] = ...;
         $imm_data[63:0] = ...;
      @5
         $reg_data[63:0] = ...;

   |inst
      ?$valid
         @3
            $op_a[63:0] =
               ($op_a_src == IMM) ? $imm_data    :
               ($op_a_src == BYP) ? >>1$rslt     :
               ($op_a_src == REG) ? >>2$reg_data :
!              ($op_a_src == MEM) ? *mem_data_M320H :
                                    64'b0;

         @4
            $rslt[63:0] = f_ALU($opcode, $op_a, $op_b);
      //...
