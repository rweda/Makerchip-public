`line 2 "operand3.tlv" 0

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
`line 36 "operand3.tlv"
`include "operand3_gen.sv"
   // Test m4+ macro.
   `line 31 "operand3.tlv"
      //_|pipe1
         //_@1
            assign PIPE1_tmp_a1[0:0] = RW_rand_vect[(0 + (0)) % 257 +: 1];
            assign PIPE1_test_sig_a1 = PIPE1_tmp_a1;
            `BOGUS_USE(PIPE1_test_sig_a1)
   //_\end_source
   `line 39 "operand3.tlv"
   
   // Context:
   //_|inst
      //_@2
         assign INST_valid_a2 = ...;
      //_@3
         assign INST_op_a_src_a3[3:0] = ...;
         assign INST_imm_data_a3[63:0] = ...;
      //_@5
         assign INST_reg_data_a5[63:0] = ...;

   //_|inst
      //_?$valid
         //_@3
            assign w_INST_op_a_a3[63:0] =
               (INST_op_a_src_a3 == IMM) ? INST_imm_data_a3    :
               (INST_op_a_src_a3 == BYP) ? INST_rslt_a4     :
               (INST_op_a_src_a3 == REG) ? INST_reg_data_a5 :
               (INST_op_a_src_a3 == MEM) ? mem_data_M320H :
                                    64'b0;

         //_@4
            assign INST_rslt_a4[63:0] = f_ALU(INST_opcode_a4, INST_op_a_a4, INST_op_b_a4);


// Undefine macros defined by SandPiper (in "operand3_gen.sv").
`undef BOGUS_USE
      //...
