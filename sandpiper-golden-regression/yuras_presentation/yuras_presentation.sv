`line 2 "yuras_presentation.m4out.tlv" 0

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

   
`include "yuras_presentation_gen.sv"
   //_|pipe0
      //_@0
         assign PIPE0_valid_a0 = ...;
         assign PIPE0_sig_c_a0 = ...;
      //_?$valid
         //_@1
            
            always_comb begin
               w_PIPE0_sig_f_a1.field = ...; end
            assign w_PIPE0_sig_f_a1.other_field = PIPE0_sig_c_a1 ? 1'b1 : PIPE0_sig_f_a2.other_field;
            assign w_PIPE0_sig_a_a1 = ...;
            assign w_PIPE0_sig_g_a1 = ..;
         //_@4.1
            assign w_PIPE0_sig_b_a4L = PIPE0_sig_a_a6L && PIPE0_sig_c_a8L && PIPE0_sig_g_a4L && PIPE0_sig_f_a4L.field;
         //_@9
            assign structure.field = PIPE0_sig_b_a9;


// Undefine macros defined by SandPiper (in "yuras_presentation_gen.sv").
`undef BOGUS_USE
