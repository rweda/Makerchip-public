`line 2 "operand4.m4out.tlv" 0

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
`include "operand4_gen.sv"

   // Context:
   //_|pipe1
      //_@3
         assign PIPE1_valid_a3 = ...;
         assign PIPE1_op_a_src_a3[3:0] = ...;
         assign PIPE1_imm_data_a3[63:0] = ...;
      //_@5
         assign PIPE1_reg_data_a5[63:0] = ...;

   //_|pipe1
      //_?$valid
         //_@4
            assign PIPE1_op_a_a4[63:0] =
               (PIPE1_op_a_src_a4 == IMM) ? PIPE1_imm_data_a4    :
               (PIPE1_op_a_src_a4 == BYP) ? PIPE1_rslt_a5     :
               (PIPE1_op_a_src_a4 == REG) ? PIPE1_reg_data_a6 :
               (PIPE1_op_a_src_a4 == MEM) ? mem_data_M321H :
                                    64'b0;
         //_@4
            assign w_PIPE1_rslt_a4[63:0] = f_ALU(PIPE1_opcode_a4, PIPE1_op_a_a4, PIPE1_op_b_a4);


// Undefine macros defined by SandPiper (in "operand4_gen.sv").
`undef BOGUS_USE
         //...
