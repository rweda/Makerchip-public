\TLV_version 1c: tl-x.org
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




// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//
// THIS IS NOT CURRENT W/ LATEST EP VERSION
// EP IS CURRENTLY THE MASTER
// DO NOT EDIT W/O UPDATING
//
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!






// Based on an example by Max Yi and David Harris 12/9/03


// Eliminate:

// states and instructions

  typedef enum logic [3:0] {FETCH1 = 4'b0000, FETCH2, FETCH3, FETCH4,
                            DECODE, MEMADR, LBRD, LBWR, SBWR,
                            RTYPEEX, RTYPEWR, BEQEX, JEX} statetype;
  typedef enum logic [5:0] {LB    = 6'b100000,
                            SB    = 6'b101000,
                            RTYPE = 6'b000000,
                            BEQ   = 6'b000100,
                            J     = 6'b000010} opcode;


// testbench
module testbench #(parameter WIDTH = 8, REGBITS = 3)();

  logic done, done_tlv;
  logic [15:0] cyc;

  logic             clk;
  logic             reset;
  logic             memread, memwrite, memread_tlv, memwrite_tlv;
  logic [WIDTH-1:0] adr, writedata, adr_tlv, writedata_tlv;
  logic [WIDTH-1:0] memdata, memdata_tlv;

  // instantiate devices to be tested
  mips #(WIDTH,REGBITS) dut(clk, reset, memdata, memread, 
                            memwrite, adr, writedata);
  mips_tlv #(WIDTH,REGBITS) dut_tlv(clk, reset, memdata_tlv, memread_tlv,
                                    memwrite_tlv, adr_tlv, writedata_tlv);

  // external memory for code and data
  exmemory #(WIDTH) exmem(clk, memwrite, adr, writedata, memdata);
  // external memory for code and data
  exmemory #(WIDTH) exmem_tlv(clk, memwrite_tlv, adr_tlv, writedata_tlv, memdata_tlv);

  // initialize test
  initial
    begin
      $dumpfile("dump.vcd"); $dumpvars;
      reset <= 1; # 102; reset <= 0;
      done <= 0;
      done_tlv <= 0;
      cyc <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  always@(negedge clk)
    begin
      cyc <= cyc + 1;
      if(memwrite)
        assert(adr == 76 & writedata == 7) begin
          $display("Verilog Simulation completely successfully @ cyc %d.", cyc);
          done <= 1'b1;
        end
        else $error("Simulation Failed.");
      if(memwrite_tlv)
        assert(adr_tlv == 76 & writedata_tlv == 7) begin
          $display("TLV SIMULATION COMPLETED Successfully!!!!!!!!!!!!!!!!!!!!!!!!");
          done_tlv <= 1'b1;
        end
        else $error("SIMULATION FAILED!!!!!!!!!!!!!!!!!!!!!!!");
      if ((done && done_tlv) || (cyc > 300))
        $finish;
    end
endmodule



// Memory (an SV library component)

// external memory accessed by MIPS
module exmemory #(parameter WIDTH = 8)
                 (input  logic             clk,
                  input  logic             memwrite,
                  input  logic [WIDTH-1:0] adr, writedata,
                  output logic [WIDTH-1:0] memdata);

  logic [31:0]      mem [2**(WIDTH-2)-1:0];
  logic [31:0]      word;
  logic [1:0]       bytesel;
  logic [WIDTH-2:0] wordadr;

  initial
    $readmemh("../../../examples/mips/memfile.dat", mem);

  assign bytesel = adr[1:0];
  assign wordadr = adr[WIDTH-1:2];

  // read and write bytes from 32-bit word
  always @(posedge clk)
    if(memwrite) 
      case (bytesel)
        2'b00: mem[wordadr][7:0]   <= writedata;
        2'b01: mem[wordadr][15:8]  <= writedata;
        2'b10: mem[wordadr][23:16] <= writedata;
        2'b11: mem[wordadr][31:24] <= writedata;
      endcase

   assign word = mem[wordadr];
   always_comb
     case (bytesel)
       2'b00: memdata = word[7:0];
       2'b01: memdata = word[15:8];
       2'b10: memdata = word[23:16];
       2'b11: memdata = word[31:24];
     endcase
endmodule

  typedef enum logic [5:0] {ADD = 6'b100000,
                            SUB = 6'b100010,
                            AND = 6'b100100,
                            OR  = 6'b100101,
                            SLT = 6'b101010} functcode;


// simplified MIPS processor
module mips_tlv #(parameter WIDTH = 8, REGBITS = 3)
             (input  logic             clk, reset, 
              input  logic [WIDTH-1:0] memdata, 
              output logic             memread, memwrite, 
              output logic [WIDTH-1:0] adr, writedata);



\TLV

   >unpipelined
      
      |cpu
         @0
!           $reset = *reset;
            
            // Ready for next instruction?
            $valid_instr = !$reset &&
                           (%+1$reset ||   // Valid immediately after reset
                            (%+6$valid_instr && (%+5$beq_type || %+5$jtype)) ||  // Branch & jump
                            (%+7$valid_instr && (%+5$sb_type || %+5$rtype)) ||   // Store & arith
                            (%+8$valid_instr && %+5$lb_type)                     // Load
                           );
         @1  // Fetch PC byte
            $fetch = $valid_instr || %+1$valid_instr || %+2$valid_instr || %+3$valid_instr;

            // Memory read/write.
!           //*adr = (%+6$valid_instr && %+4$mem_type) ? %+6$alu_out : $Pc;
!           //*memread = $fetch || %+6$valid_instr && %+4$lb_type;
!           $memdata[WIDTH-1:0] = *memdata;

            // Next PC
            %next$Pc[WIDTH-1:0] = $reset                       ? '0          :
                                  $fetch                       ? %+5$alu_out :
                                  %+5$valid_instr && %+4$jtype ? %+4$imm_x4  :
                                  %+6$beq_update_pc            ? %+6$alu_out :
                                  $RETAIN;
         @4
            
            // Combine instruction bytes.
            $instr[31:0] = %-4$reset    ? '0 :
                           $valid_instr ? {%-3$memdata, %-2$memdata, %-1$memdata, $memdata} :
                                          $RETAIN;
         
         // decode/reg fetch
         @5
            // Instruction fields:
            $imm[7:0] = $instr[7:0];
            $imm_x4[7:0] = {$instr[5:0], 2'b00};
            $op[5:0] = $instr[31:26];
            $funct[5:0] = $instr[5:0];
            
            // Operand decode:
            $rtype    = $op == 6'b000000;
            $mem_type = $op[5];
            $lb_type  = $mem_type && !$op[3];
            $sb_type  = $mem_type &&  $op[3];
            $beq_type = $op[2];
            $jtype    = $op[1];
         @6
            // The pipeline is utilized the cycle before a beq.
            $beq_target_calc = %next$valid_instr && %next$beq_type;
         @7
            $beq_update_pc = $beq_target_calc && %next$zero;

         @5
            // Register access:
            $ra1[REGBITS-1:0] = $instr[REGBITS+20:21];
            $ra2[REGBITS-1:0] = $instr[REGBITS+15:16];
            $wa[REGBITS-1:0] = (%+2$valid_instr && $rtype)
                    ? $instr[REGBITS+10:11]   // %+2
                    : $instr[REGBITS+15:16];
            $wd[WIDTH-1:0] = %+2$lb_type ? %-3$memdata : %+2$alu_out;
            $regwrite = (%+3$valid_instr && $lb_type) || (%+2$valid_instr && $rtype);
            regfile #(WIDTH,REGBITS) rf(clk, $regwrite, $ra1, $ra2,
                                        $wa, $wd, $$rd1[WIDTH-1:0], $$rd2[WIDTH-1:0]);

         // ALU ($src_a, $src_b) -> ($alu_rslt, $zero)
         //
            
         // ALU sources
         @6
            $src_a[WIDTH-1:0] = $valid_instr ? $rd1 : %-5$Pc;
            $src_b[WIDTH-1:0] = 
                %-5$fetch                         ? 1       :     // Next byte of instr
                $beq_target_calc                  ? %-1$imm_x4 :  // Branch target
                %-1$mem_type                      ? %-1$imm :     // Mem addr calc
                                                    $rd2;         // ALU instr
            
            $alu_op[1:0] = $valid_instr ? {%-1$rtype, %-1$beq_type} : 2'b00;
            aludec ac($alu_op, %-1$funct, $$alu_control[2:0]);
            
            // ALU
            alu #(WIDTH) alunit($src_a, $src_b, $alu_control, $$alu_out[WIDTH-1:0], $$zero);
         @7
!           //*memwrite = *reset ? 1'b0 // avoid writing 'X
            //                   : $valid_instr && $sb_type;
         @6
!           //*writedata = $rd2;
      
      
   >pipelined
         
      |cpu
         @0
!           $reset = *reset;
            
            // Ready for next instruction?
            $valid_instr = !$reset &&
                           (%+1$reset ||   // Valid immediately after reset
                            (%+6$beq_type || %+6$jtype) ||  // Branch & jump
                            (%+7$sb_type || %+7$rtype) ||   // Store & arith
                            %+8$lb_type                     // Load
                           );
         @1  // Fetch PC byte
            $fetch = $valid_instr || %+1$valid_instr || %+2$valid_instr || %+3$valid_instr;

            // Memory read/write.
!           *adr = %+6$mem_type ? %+6$alu_out : $Pc;
            $mem_read = $fetch || %+6$lb_type;
!           *memread = $mem_read;
            ?$mem_read
!              $memdata[WIDTH-1:0] = *memdata;

            // Next PC
            %next$Pc[WIDTH-1:0] = $reset                       ? '0          :
                                  $fetch                       ? %+5$alu_out :
                                  %+5$jtype                    ? %+5$imm_x4  :
                                  %+6$beq_update_pc            ? %+6$alu_out :
                                  $RETAIN;
         @4
            // Combine instruction bytes.
            ?$valid_instr
               $instr[31:0] = {%-3$memdata, %-2$memdata, %-1$memdata, $memdata} `BOGUS_USE($RETAIN);  // BUG WORKAROUND (fixed, but not in EP)!!!!
         
         // decode/reg fetch
         @5
            // Characterize the transaction
            
            ?$valid_instr
               // Instruction fields:
               $imm[7:0] = $instr[7:0];
               $imm_x4[7:0] = {$instr[5:0], 2'b00};
               $op[5:0] = $instr[31:26];
               $funct[5:0] = $instr[5:0];
            
            // Operand decode:
            $rtype    = $valid_instr && ($op == 6'b000000);
            $mem_type = $valid_instr &&  $op[5];
            $lb_type  = $mem_type && !$op[3];
            $sb_type  = $mem_type &&  $op[3];
            $beq_type = $valid_instr && $op[2];
            $jtype    = $valid_instr && $op[1];

         @6
            // The pipeline is utilized the cycle before a beq.
            $beq_target_calc = %next$valid_instr && %next$beq_type;
         @7
            $beq_update_pc = $beq_target_calc && %next$zero;

         @5
            // Register access:
            $ra1[REGBITS-1:0] = $instr[REGBITS+20:21];
            $ra2[REGBITS-1:0] = $instr[REGBITS+15:16];
            ?$regwrite
               $wa[REGBITS-1:0] = %+2$rtype
                       ? %+2$instr[REGBITS+10:11]   // %+2
                       : %+3$instr[REGBITS+15:16];
               $wd[WIDTH-1:0] = %+2$rtype ? %+2$alu_out : %-3$memdata;
            $regwrite = %+3$lb_type || %+2$rtype;
            regfile #(WIDTH,REGBITS) rf2(clk, $regwrite, $ra1, $ra2,
                                        $wa, $wd, $$rd1[WIDTH-1:0], $$rd2[WIDTH-1:0]);

         // ALU ($src_a, $src_b) -> ($alu_rslt, $zero)
         //
            
         // ALU sources
         @6
            $alu_valid = $valid_instr ||    // any instr
                         %next$beq_type ||  // branch target
                         %-5$fetch;         // next PC byte
            ?$alu_valid
               $src_a[WIDTH-1:0] = $valid_instr ? $rd1 : %-5$Pc;
               $src_b[WIDTH-1:0] = 
                   %-5$fetch                         ? 1       :       // Next byte of instr
                   $beq_target_calc                  ? %next$imm_x4 :  // Branch target
                   $mem_type                         ? $imm :          // Mem addr calc
                                                       $rd2;           // ALU instr
            
               $alu_op[1:0] = $valid_instr ? {$rtype, $beq_type} : 2'b00;
               aludec ac2($alu_op, $funct, $$alu_control[2:0]);
            
               // ALU
               alu #(WIDTH) alunit2($src_a, $src_b, $alu_control, $$alu_out[WIDTH-1:0], $$zero);
            
         @7
!           *memwrite = *reset ? 1'b0 // avoid writing 'X
                               : $sb_type;
            ?$sb_type
!              *writedata = $rd2;


\SV
endmodule




// And this will all go away:

// simplified MIPS processor
module mips #(parameter WIDTH = 8, REGBITS = 3)
             (input  logic             clk, pre_reset, 
              input  logic [WIDTH-1:0] memdata, 
              output logic             memread, memwrite, 
              output logic [WIDTH-1:0] adr, writedata);

   logic [31:0] instr;
   logic        zero, alusrca, memtoreg, iord, pcen, regwrite, regdst;
   logic [1:0]  pcsrc, alusrcb;
   logic [3:0]  irwrite;
   logic [2:0]  alucontrol;
   logic [5:0]  op, funct;
   logic reset;

   flop #(1) rst_flp(clk, pre_reset, reset);
   

   assign op = instr[31:26];      
   assign funct = instr[5:0];  
      
   controller  cont(clk, reset, op, funct, zero, memread, memwrite, 
                    alusrca, memtoreg, iord, pcen, regwrite, regdst,
                    pcsrc, alusrcb, alucontrol, irwrite);
   datapath    #(WIDTH, REGBITS) 
               dp(clk, reset, memdata, alusrca, memtoreg, iord, pcen,
                  regwrite, regdst, pcsrc, alusrcb, irwrite, alucontrol,
                  zero, instr, adr, writedata);
endmodule

module controller(input logic clk, reset, 
                  input  logic [5:0] op, funct,
                  input  logic       zero, 
                  output logic       memread, memwrite, alusrca,  
                  output logic       memtoreg, iord, pcen, 
                  output logic       regwrite, regdst, 
                  output logic [1:0] pcsrc, alusrcb,
                  output logic [2:0] alucontrol,
                  output logic [3:0] irwrite);

  statetype       state;
  logic           pcwrite, branch;
  logic     [1:0] aluop;

  // control FSM
  statelogic statelog(clk, reset, op, state);
  outputlogic outputlog(state, memread, memwrite, alusrca,
                        memtoreg, iord, 
                        regwrite, regdst, pcsrc, alusrcb, irwrite, 
                        pcwrite, branch, aluop);

  // other control decoding
  aludec  ac(aluop, funct, alucontrol);
  assign pcen = pcwrite | (branch & zero); // program counter enable
endmodule

module statelogic(input  logic       clk, reset,
                  input  logic [5:0] op,
                  output statetype   state);

  statetype nextstate;
  
  always_ff @(posedge clk)
    if (reset) state <= FETCH1;
    else       state <= nextstate;
    
  always_comb
    begin
      case (state)
        FETCH1:  nextstate = FETCH2;
        FETCH2:  nextstate = FETCH3;
        FETCH3:  nextstate = FETCH4;
        FETCH4:  nextstate = DECODE;
        DECODE:  case(op)
                   LB:      nextstate = MEMADR;
                   SB:      nextstate = MEMADR;
                   RTYPE:   nextstate = RTYPEEX;
                   BEQ:     nextstate = BEQEX;
                   J:       nextstate = JEX;
                   default: nextstate = FETCH1; // should never happen
                 endcase
        MEMADR:  case(op)
                   LB:      nextstate = LBRD;
                   SB:      nextstate = SBWR;
                   default: nextstate = FETCH1; // should never happen
                 endcase
        LBRD:    nextstate = LBWR;
        LBWR:    nextstate = FETCH1;
        SBWR:    nextstate = FETCH1;
        RTYPEEX: nextstate = RTYPEWR;
        RTYPEWR: nextstate = FETCH1;
        BEQEX:   nextstate = FETCH1;
        JEX:     nextstate = FETCH1;
        default: nextstate = FETCH1; // should never happen
      endcase
    end
endmodule

module outputlogic(input statetype state,
                   output logic       memread, memwrite, alusrca,  
                   output logic       memtoreg, iord, 
                   output logic       regwrite, regdst, 
                   output logic [1:0] pcsrc, alusrcb,
                   output logic [3:0] irwrite,
                   output logic       pcwrite, branch,
                   output logic [1:0] aluop);

  always_comb
    begin
      // set all outputs to zero, then 
      // conditionally assert just the appropriate ones
      irwrite = 4'b0000;
      pcwrite = 0; branch = 0;
      regwrite = 0; regdst = 0;
      memread = 0; memwrite = 0;
      alusrca = 0; alusrcb = 2'b00; aluop = 2'b00;
      pcsrc = 2'b00;
      iord = 0; memtoreg = 0;
      case (state)
        FETCH1: 
          begin
            memread = 1; 
            irwrite = 4'b0001; 
            alusrcb = 2'b01; 
            pcwrite = 1;
          end
        FETCH2: 
          begin
            memread = 1;
            irwrite = 4'b0010;
            alusrcb = 2'b01;
            pcwrite = 1;
          end
        FETCH3:
          begin
            memread = 1;
            irwrite = 4'b0100;
            alusrcb = 2'b01;
            pcwrite = 1;
          end
        FETCH4:
          begin
            memread = 1;
            irwrite = 4'b1000;
            alusrcb = 2'b01;
            pcwrite = 1;
          end
        DECODE: alusrcb = 2'b11;
        MEMADR:
          begin
            alusrca = 1;
            alusrcb = 2'b10;
          end
        LBRD:
          begin
            memread = 1;
            iord    = 1;
          end
        LBWR:
          begin
            regwrite = 1;
            memtoreg = 1;
          end
        SBWR:
          begin
            memwrite = 1;
            iord     = 1;
          end
        RTYPEEX: 
          begin
            alusrca = 1;
            aluop   = 2'b10;
          end
        RTYPEWR:
          begin
            regdst   = 1;
            regwrite = 1;
          end
        BEQEX:
          begin
            alusrca = 1;
            aluop   = 2'b01;
            branch  = 1;
            pcsrc   = 2'b01;
          end
        JEX:
          begin
            pcwrite  = 1;
            pcsrc    = 2'b10;
          end
      endcase
    end
endmodule

module aludec(input  logic [1:0] aluop, 
              input  logic [5:0] funct, 
              output logic [2:0] alucontrol);

  always_comb
    case (aluop)
      2'b00: alucontrol = 3'b010;  // add for lb/sb/addi
      2'b01: alucontrol = 3'b110;  // subtract (for beq)
      default: case(funct)      // R-Type instructions
                 ADD: alucontrol = 3'b010;
                 SUB: alucontrol = 3'b110;
                 AND: alucontrol = 3'b000;
                 OR:  alucontrol = 3'b001;
                 SLT: alucontrol = 3'b111;
                 default:   alucontrol = 3'b101; // should never happen
               endcase
    endcase
endmodule

module datapath #(parameter WIDTH = 8, REGBITS = 3)
                 (input  logic             clk, reset, 
                  input  logic [WIDTH-1:0] memdata, 
                  input  logic             alusrca, memtoreg, iord, 
                  input  logic             pcen, regwrite, regdst,
                  input  logic [1:0]       pcsrc, alusrcb, 
                  input  logic [3:0]       irwrite, 
                  input  logic [2:0]       alucontrol, 
                  output logic             zero, 
                  output logic [31:0]      instr, 
                  output logic [WIDTH-1:0] adr, writedata);

  logic [REGBITS-1:0] ra1, ra2, wa;
  logic [WIDTH-1:0]   pc, nextpc, data, rd1, rd2, wd, a, srca, 
                      srcb, aluresult, aluout, immx4;

  logic [WIDTH-1:0] CONST_ZERO = 0;
  logic [WIDTH-1:0] CONST_ONE =  1;

  // shift left immediate field by 2
  assign immx4 = {instr[WIDTH-3:0],2'b00};

  // register file address fields
  assign ra1 = instr[REGBITS+20:21];
  assign ra2 = instr[REGBITS+15:16];
  mux2       #(REGBITS) regmux(instr[REGBITS+15:16], 
                               instr[REGBITS+10:11], regdst, wa);

   // independent of bit width, load instruction into four 8-bit registers over four cycles
  flopen     #(8)      ir0(clk, irwrite[0], memdata[7:0], instr[7:0]);
  flopen     #(8)      ir1(clk, irwrite[1], memdata[7:0], instr[15:8]);
  flopen     #(8)      ir2(clk, irwrite[2], memdata[7:0], instr[23:16]);
  flopen     #(8)      ir3(clk, irwrite[3], memdata[7:0], instr[31:24]);

  // datapath
  flopenr    #(WIDTH)  pcreg(clk, reset, pcen, nextpc, pc);
  flop       #(WIDTH)  datareg(clk, memdata, data);
  flop       #(WIDTH)  areg(clk, rd1, a);
  flop       #(WIDTH)  wrdreg(clk, rd2, writedata);
  flop       #(WIDTH)  resreg(clk, aluresult, aluout);
  mux2       #(WIDTH)  adrmux(pc, aluout, iord, adr);
  mux2       #(WIDTH)  src1mux(pc, a, alusrca, srca);
  mux4       #(WIDTH)  src2mux(writedata, CONST_ONE, instr[WIDTH-1:0], 
                               immx4, alusrcb, srcb);
  mux3       #(WIDTH)  pcmux(aluresult, aluout, immx4, 
                             pcsrc, nextpc);
  mux2       #(WIDTH)  wdmux(aluout, data, memtoreg, wd);
  regfile    #(WIDTH,REGBITS) rf(clk, regwrite, ra1, ra2, 
                                 wa, wd, rd1, rd2);
  alu        #(WIDTH) alunit(srca, srcb, alucontrol, aluresult, zero);
endmodule

module alu #(parameter WIDTH = 8)
            (input  logic [WIDTH-1:0] a, b, 
             input  logic [2:0]       alucontrol, 
             output logic [WIDTH-1:0] result,
             output logic             zero);

  logic [WIDTH-1:0] b2, andresult, orresult, sumresult, sltresult;

  andN    andblock(a, b, andresult);
  orN     orblock(a, b, orresult);
  condinv binv(b, alucontrol[2], b2);
  adder   addblock(a, b2, alucontrol[2], sumresult);
  // slt should be 1 if most significant bit of sum is 1
  assign sltresult = sumresult[WIDTH-1];

  mux4 resultmux(andresult, orresult, sumresult, sltresult, alucontrol[1:0], result);
  zerodetect #(WIDTH) zd(result, zero);
endmodule

module regfile #(parameter WIDTH = 8, REGBITS = 3)
                (input  logic               clk, 
                 input  logic               regwrite, 
                 input  logic [REGBITS-1:0] ra1, ra2, wa, 
                 input  logic [WIDTH-1:0]   wd, 
                 output logic [WIDTH-1:0]   rd1, rd2);

   logic [WIDTH-1:0] RAM [2**REGBITS-1:0];

  // three ported register file
  // read two ports combinationally
  // write third port on rising edge of clock
  // register 0 hardwired to 0
  always @(posedge clk)
    if (regwrite) RAM[wa] <= wd;

  assign rd1 = ra1 ? RAM[ra1] : 0;
  assign rd2 = ra2 ? RAM[ra2] : 0;
endmodule

module zerodetect #(parameter WIDTH = 8)
                   (input  logic [WIDTH-1:0] a, 
                    output logic             y);

   assign y = (a==0);
endmodule	

module flop #(parameter WIDTH = 8)
             (input  logic             clk, 
              input  logic [WIDTH-1:0] d, 
              output logic [WIDTH-1:0] q);

  always_ff @(posedge clk)
    q <= d;
endmodule

module flopen #(parameter WIDTH = 8)
               (input  logic             clk, en,
                input  logic [WIDTH-1:0] d, 
                output logic [WIDTH-1:0] q);

  always_ff @(posedge clk)
    if (en) q <= d;
endmodule

module flopenr #(parameter WIDTH = 8)
                (input  logic             clk, reset, en,
                 input  logic [WIDTH-1:0] d, 
                 output logic [WIDTH-1:0] q);
 
  always_ff @(posedge clk)
    if      (reset) q <= 0;
    else if (en)    q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  always_comb 
    casez (s)
      2'b00: y = d0;
      2'b01: y = d1;
      2'b1?: y = d2;
    endcase
endmodule

module mux4 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2, d3,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);

  always_comb
    case (s)
      2'b00: y = d0;
      2'b01: y = d1;
      2'b10: y = d2;
      2'b11: y = d3;
    endcase
endmodule

module andN #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] a, b,
              output logic [WIDTH-1:0] y);

  assign y = a & b;
endmodule

module orN #(parameter WIDTH = 8)
            (input  logic [WIDTH-1:0] a, b,
             output logic [WIDTH-1:0] y);

  assign y = a | b;
endmodule

module inv #(parameter WIDTH = 8)
            (input  logic [WIDTH-1:0] a,
             output logic [WIDTH-1:0] y);

  assign y = ~a;
endmodule

module condinv #(parameter WIDTH = 8)
                (input  logic [WIDTH-1:0] a,
                 input  logic             invert,
                 output logic [WIDTH-1:0] y);

  logic [WIDTH-1:0] ab;

  inv  inverter(a, ab);
  mux2 invmux(a, ab, invert, y);
endmodule

module adder #(parameter WIDTH = 8)
              (input  logic [WIDTH-1:0] a, b,
               input  logic             cin,
               output logic [WIDTH-1:0] y);

  assign y = a + b + cin;
endmodule
