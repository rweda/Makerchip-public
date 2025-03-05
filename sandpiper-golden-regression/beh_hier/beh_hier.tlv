\TLV_version 1b: tl-x.org
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
   SV code...
\TLV
   // Manufactured enable.
   |conditions
      @1
         $valid1 = 1'b0;
      ?$valid1
         >tmp2
            @1
               $valid2 = 1'b0;
            ?$valid2
               @1
                  $in = 1'b0;
               @3
                  $conditioned = $in;
   >core[1:0]
      >inst[3:0]
         |pipe1
            @2
               \viz_alpha
                  Some viz content w/ escapes: \ "  " '' .'
                  // And comments w/ escapes: \ "  " '' .'
                  And some more./* >bad|ref$sig1 '>bad|ref$sig2'
                  end */
                  And some more content '>inst|pipe2$out#+4'
            ?$valid
               @3
                  $op_a[63:0] =
                     ($op_a_src == IMM) ? $imm_data    :
                     ($op_a_src == BYP) ? $rslt#+1     :
                     ($op_a_src == REG) ? $reg_data#+2 :
!                    ($op_a_src == MEM) ? *mem_data_M320H :
                                          64'b0;
            @1
               // comment
               //
               \source dummy_file.tlv 100
                  $valid = *test_sig;
                  // comment
                  \source dummy2.tlv 200
                     $foo2 = 1'b0;
                     //
                     $warn2 = $foo2;
                     //
                  \end_source
               \end_source
            //
            ?$valid
               @4
                  $rslt[63:0] = f_ALU($opcode, $op_a, $op_b);
               @5
                  $reg_data[63:0] = ...;
         |pipe2
            @5
               $ANY = >inst|pipe1$ANY#+0;
            @6
               $out[63:0] = $rslt;
               `BOGUS_USE($out);
   >core[1]
      >inst[*:0]
      >inst[{0:lo}]
      >inst[0]
      >inst[{hi}]
   |test
      @0
         $foo = blah;
               
\SV_plus
   foo = >core[1]>inst[>core[1]>inst[0]|pipe1$valid#+1]|pipe1$valid#+1;
   foo = >core[1]>inst[|test$foo#+0]|pipe1$valid#+1;
   
// whitespace testing
\TLV

   >it   //comment/
         //cont'd/

         //cont'd2/  
             
      // node:
      
   

      $foo = $bar;
   

             