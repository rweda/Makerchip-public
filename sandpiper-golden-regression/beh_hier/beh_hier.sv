`line 2 "run/gen/beh_hier/beh_hier.m4out.tlv" 0

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
   SV code...
`include "beh_hier_gen.sv" //_\TLV
   // Manufactured enable.
   //_|conditions
      //_@1
         assign CONDITIONS_valid1_a1 = 1'b0;
      //_?$valid1
         //_>tmp2
            //_@1
               assign CONDITIONS_Tmp2_valid2_a1 = 1'b0;
            //_?$valid2
               //_@1
                  assign w_CONDITIONS_Tmp2_in_a1 = 1'b0;
               //_@3
                  assign w_CONDITIONS_Tmp2_conditioned_a3 = CONDITIONS_Tmp2_in_a3;
   for (core = 0; core <= 1; core++) begin : L1_Core //_>core

      // For >inst|pipe1$valid.
      logic L1_Inst_PIPE1_valid_a1 [3:0],
            L1_Inst_PIPE1_valid_a2 [3:0],
            L1_Inst_PIPE1_valid_a3 [3:0],
            L1_Inst_PIPE1_valid_a4 [3:0],
            L1_Inst_PIPE1_valid_a5 [3:0];

      for (inst = 0; inst <= 3; inst++) begin : L2_Inst //_>inst

         // For |pipe1$foo2.
         logic L2_PIPE1_foo2_a1;

         // For |pipe1$op_a.
         logic [63:0] w_L2_PIPE1_op_a_a3,
                      L2_PIPE1_op_a_a4;

         // For |pipe1$reg_data.
         logic [63:0] L2_PIPE1_reg_data_a5;

         // For |pipe1$rslt.
         logic [63:0] L2_PIPE1_rslt_a4,
                      L2_PIPE1_rslt_a5;

         // For |pipe1$warn2.
         logic L2_PIPE1_warn2_a1;

         // For |pipe2$out.
         logic [63:0] L2_PIPE2_out_a6;

         // For |pipe2$rslt.
         logic [63:0] L2_PIPE2_rslt_a5,
                      L2_PIPE2_rslt_a6;

         //_|pipe1
            //_@2
               
            //_?$valid
               //_@3
                  assign w_L2_PIPE1_op_a_a3[63:0] =
                     (Core_Inst_PIPE1_op_a_src_a3[core][inst] == IMM) ? Core_Inst_PIPE1_imm_data_a3[core][inst]    :
                     (Core_Inst_PIPE1_op_a_src_a3[core][inst] == BYP) ? L2_PIPE1_rslt_a4     :
                     (Core_Inst_PIPE1_op_a_src_a3[core][inst] == REG) ? L2_PIPE1_reg_data_a5 :
                     (Core_Inst_PIPE1_op_a_src_a3[core][inst] == MEM) ? mem_data_M320H :
                                          64'b0;
            //_@1
               // comment
               //
               `line 101 "dummy_file.tlv"
                  assign L1_Inst_PIPE1_valid_a1[inst] = test_sig;
                  // comment
                  `line 201 "dummy2.tlv"
                     assign L2_PIPE1_foo2_a1 = 1'b0;
                     //
                     assign L2_PIPE1_warn2_a1 = L2_PIPE1_foo2_a1;
                     //
                  //_\end_source
                  `line 104 "dummy_file.tlv"
               //_\end_source
               `line 66 "run/gen/beh_hier/beh_hier.m4out.tlv"
            //
            //_?$valid
               //_@4
                  assign L2_PIPE1_rslt_a4[63:0] = f_ALU(Core_Inst_PIPE1_opcode_a4[core][inst], L2_PIPE1_op_a_a4, Core_Inst_PIPE1_op_b_a4[core][inst]);
               //_@5
                  assign L2_PIPE1_reg_data_a5[63:0] = ...;
         //_|pipe2
            //_@5
               assign {L2_PIPE2_rslt_a5[63:0]} = {L2_PIPE1_rslt_a5};
            //_@6
               assign L2_PIPE2_out_a6[63:0] = L2_PIPE2_rslt_a6;
               `BOGUS_USE(L2_PIPE2_out_a6);
      end
   end
   for (core = 0; core <= 1; core++) begin : L1b_Core //_>core
      //_>inst
      //_>inst
      //_>inst
      //_>inst
   end
   //_|test
      //_@0
         assign TEST_foo_a0 = blah;
               
/*SV_plus*/
   foo = L1_Core[1].L1_Inst_PIPE1_valid_a1[L1_Core[1].L1_Inst_PIPE1_valid_a1[0]];
   foo = L1_Core[1].L1_Inst_PIPE1_valid_a1[TEST_foo_a0];
   
// whitespace testing
//_\TLV

   //_>it   //comment/
         //cont'd/

         //cont'd2/  
             
      // node:
      
   

      assign It_foo_a0 = It_bar_a0;
   

             


// Undefine macros defined by SandPiper (in "beh_hier_gen.sv").
`undef BOGUS_USE
