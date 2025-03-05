\m4_TLV_version 1d: tl-x.org
\SV
m4_include_url(['https://raw.githubusercontent.com/stevehoover/tlv_flow_lib/5a8c0387be80b2deccfcd1506299b36049e0663e/pipeflow_lib.tlv'])

/*
This example illustrates the use of a speculation macro.
An imperfect addition and a perfect addition are calculated. A speculation macro compares the results and
indicates whether the imperfect computation was correct. If incorrect, a one-cycle penalty is applied to the output,
and the correct value is presented. Results subsequent to a misspeculation will also be delayed until an
invalid slot is able to absorb the delay. So, results in the output pipeline (|out_pipe) will remain in order,
but the delay will vary by a cycle.

The speculative addition is performed assuming that, for each bit, we can ignore bits that are more than two bits
to the right (less-significant).
*/

   m4_makerchip_module
\TLV
   // Intantiate speculation flow for speculation in cycle 0 with comparison in cycle 1.
   m4+1cyc_speculate(/top, |in_pipe, |out_pipe, @0, @1, ['$sum'])
   
   |in_pipe
      @0
         // The input transaction is randomly valid or not.
         m4_rand($valid, 0, 0)
      ?$valid
         @0
            // The input transaction containing:
            //   - two values to add
            //   - an ID -- an example of a transaction field that follows the transaction through the fast or slow path.
            /trans
               // The two random input values.
               // Bits [-1:-2] are needed by the speculative addition to compute the LSB since each bit looks at the two less significant bits.
               // We provide the upper bit as zero to avoid overflow.
               /in[1:0]
                  m4_rand($rand_value, 6, 0, in)
                  $value[7:-2] = {1'b0, $rand_value, 2'b0};
               // The transaction ID.
               $id[15:0] = *cyc_cnt;
            
            // Compute speculative $sum.
            /pred_trans
               /digit[7:0]
                  // Do a 2-bit sum for each bit as a low-logic-depth approximation.
                  $small_sum[0:-2] = |in_pipe/trans/in[0]$value[#digit:#digit-2] +
                                     |in_pipe/trans/in[1]$value[#digit:#digit-2];
                  $bit = $small_sum[0];
               $sum[7:0] = /digit[*]$bit;
            
            // Compute non-speculative $sum.
            /trans
               $sum[7:0] = /in[0]$value[7:0] + /in[1]$value[7:0];
               
   // Pretend there is a consumer of the transaction ($id and $sum) at the macro output.
   |out_pipe
      /trans
         ?$valid
            @1
               `BOGUS_USE($id $sum)

   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = *cyc_cnt > 300;
   *failed = 1'b0;
\SV
   endmodule
