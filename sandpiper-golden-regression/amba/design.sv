`line 2 "design.tlv" 0

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

module dut(input logic clk, input logic reset, input logic [15:0] cyc_cnt, output logic passed, output logic failed);    /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_on UNOPTFLAT */


`include "design_gen.sv"
   //_|bus
      // GLOBAL SIGNALS
      //_@0
         assign BUS_hreset_n_a0 = !reset;
      
      // MASTER (Stimulus to Slave)
      //_>master
         //_>transfer
            //_@0
               assign BUS_Master_Transfer_htrans_a0[1:0] = RW_rand_vect[(0 + (0)) % 257 +: 2];     // (Random generation does not follow $htrans data length.
                                         //  All are treated as undefined length.)
               assign BUS_Master_Transfer_hwrite_a0[0:0] = RW_rand_vect[(124 + (0)) % 257 +: 1];
               assign BUS_Master_Transfer_haddr_a0[31:0] = RW_rand_vect[(248 + (0)) % 257 +: 32];     // (Ignoring sequentiality and alignment requirements.)
               assign BUS_Master_Transfer_hwdata_a0[31:0] = RW_rand_vect[(115 + (0)) % 257 +: 32];
               assign BUS_Master_Transfer_hsize_a0[2:0] = 3'b010;     // 32-bit word only.
               assign BUS_Master_Transfer_hburst_a0[2:0] = RW_rand_vect[(239 + (0)) % 257 +: 3];
               assign BUS_Master_Transfer_hprot_a0[6:0] = 7'b0000001; // Device-nE user data only.  (Non-cacheable, non-bufferable).
               assign BUS_Master_Transfer_hmastlock_a0 = 1'b0;        // Locked transfers not supported.
               `BOGUS_USE(BUS_Master_Transfer_hburst_a0 BUS_Master_Transfer_hmastlock_a0 BUS_Master_Transfer_hprot_a0 BUS_Master_Transfer_hsize_a0)  // TODO: Use these.
      // DECODER
      //_>decoder
         //_@0
            assign BUS_Decoder_sel_a0[1:0] = BUS_Master_Transfer_haddr_a0[1:0];
            generate for (slave = 0; slave <= 2; slave++) begin : L1_BUS_Decoder_Slave logic L1_hsel_a0; //_>slave
               assign L1_hsel_a0 = BUS_Decoder_sel_a0 == slave; end endgenerate
            
      // SLAVE
      generate for (slave = 0; slave <= 2; slave++) begin : L1_BUS_Slave logic [5:0] L1_entry_index_a0, L1_entry_index_a1; logic L1_read_a0, L1_read_a1; logic L1_write_a0, L1_write_a1; logic [31:0] w_L1_Entry_Data_a0 [63:0], L1_Entry_Data_a0 [63:0], L1_Entry_Data_a1 [63:0]; //_>slave
         //_@0
            //_>transfer
               assign {BUS_Slave_Transfer_haddr_a0[slave][7:2], BUS_Slave_Transfer_hwdata_a0[slave][31:0], BUS_Slave_Transfer_hwrite_a0[slave][0:0]} = {BUS_Master_Transfer_haddr_a0[7:2], BUS_Master_Transfer_hwdata_a0, BUS_Master_Transfer_hwrite_a0};
            assign L1_write_a0 = (L1_BUS_Decoder_Slave[slave].L1_hsel_a0 &&  BUS_Slave_Transfer_hwrite_a0[slave]) || !BUS_hreset_n_a0;
            assign L1_read_a0  =  L1_BUS_Decoder_Slave[slave].L1_hsel_a0 && !BUS_Slave_Transfer_hwrite_a0[slave];
            assign L1_entry_index_a0[5:0] = BUS_Slave_Transfer_haddr_a0[slave][7:2];
         //_@1
            for (entry = 0; entry <= 63; entry++) begin : L2_Entry logic L2_write_a1; //_>entry
               assign L2_write_a1 = L1_write_a1 && (L1_entry_index_a1 == entry);
               //_?$write
                  assign w_L1_Entry_Data_a0[entry][31:0] = reset ? {26'b0, L1_entry_index_a1}  // $data = $index on reset
                                            : BUS_Slave_Transfer_hwdata_a1[slave]; end      // write
            //_?$read
               //_>transfer
                  assign BUS_Slave_Transfer_hrdata_a1[slave][31:0] = L1_Entry_Data_a1[BUS_Slave_Transfer_haddr_a1[slave][7:2]];
                  assign BUS_Slave_Transfer_hreadyout_a1[slave] = 1'b1;   // Always ready.  (Does this meet the spec requirements?)
                  assign BUS_Slave_Transfer_hresp_a1[slave] = 1'b0; end endgenerate       // No errors.
      
      // MUX (Slave to Master)
      //_>mux
         //_@1
            assign BUS_Mux_valid_a1 = BUS_Master_Transfer_htrans_a1 != 2'b00;
            //_?$valid
               assign {BUS_Mux_hrdata_a1[31:0], BUS_Mux_hreadyout_a1, BUS_Mux_hresp_a1} = {BUS_Slave_Transfer_hrdata_a1[BUS_Decoder_sel_a1], BUS_Slave_Transfer_hreadyout_a1[BUS_Decoder_sel_a1], BUS_Slave_Transfer_hresp_a1[BUS_Decoder_sel_a1]};  // !!! BUG with |bus>slave>transfer$hrdata signal.
      
      // MASTER (Response from Slave)
      //_>master
         //_>return_transfer
            //_@1
               assign BUS_Master_ReturnTransfer_valid_a1 = BUS_Mux_valid_a1;
               //_?$valid
                  assign {BUS_Master_ReturnTransfer_hrdata_a1[31:0], BUS_Master_ReturnTransfer_hreadyout_a1, BUS_Master_ReturnTransfer_hresp_a1} = {BUS_Mux_hrdata_a1, BUS_Mux_hreadyout_a1, BUS_Mux_hresp_a1};
                  `BOGUS_USE(BUS_Master_ReturnTransfer_hrdata_a1 BUS_Master_ReturnTransfer_hreadyout_a1 BUS_Master_ReturnTransfer_hresp_a1)
   
   
   // CHECKING
   //_|default
      //_@0
         assign DEFAULT_Cnt_n1[15:0] = DEFAULT_Cnt_a0 + 16'b1;
         assign passed = DEFAULT_Cnt_a0 == 16'd50;  // Pass after 50 cycles with no checking.

//_\SV
endmodule


// Undefine macros defined by SandPiper (in "design_gen.sv").
`undef BOGUS_USE
