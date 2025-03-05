\m4_TLV_version 1d: tl-x.org
\SV
// -----------------------------------------------------------------------------
// Copyright (c) 2017, Redwood EDA, LLC
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
//     * Redistributions of source code must retain the above copyright notice,
//       this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Redwood EDA, LLC nor the names of its contributors
//       may be used to endorse or promote products derived from this software
//       without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// -----------------------------------------------------------------------------


// A dirt-simple CPU for educational purposes.

// What's interesting about this CPU?
//   o It's super small.
//   o It's easy to play with and learn from.
//   o Instructions are short, kind-of-readable strings, so no assembler is needed.
//     They would map directly to a denser (~17-bit) encoding if desired.
//   o The only instruction formats are op, load, and store.
//   o Branch/Jump: There is no special format for control-flow instructions. Any
//     instruction can write the PC (relative or absolute). A conditional branch
//     will typically utilize a condition operation that provides a (relative) branch
//     target or zero. The condition can be predicted as per traditional branch
//     prediction (though there is no branch predictor in this example as it stands).

// Machine Arch:
//   o Single stage "pipeline".
//   o 8 registers.
//   o A word is 12 bits wide.
//   o Operators operate on and produce words as signed or unsigned values and
//     booleans (all-zero/one)
//
// ISA:
//
// Instructions are 5-character strings: "D=1o2"
//
// =: Appears in every instruction (just for readability).
// D, 2, 1: "a" - "h" for register values;
//          "0" - "7" for immediate constants (sources, or "0" for unused dest);
//          "P" for absolute dest PC (jump);
//          "p" for relative dest PC (branch), PC = PC + 1 + result(signed).
//
// o: operator
//   Op: (D = 1 o 2) (Eg: "c=a+b"):
//     +, -, *, /: Arithmetic. *, / are unsigned.
//     =, !, <, >, [, ]: Compare (D = (1 o r) ? all-1s : 0) (] is >=, [ is <=)
//        (On booleans these are XNOR, XOR, !1&2, 1&!2, !1|2, 1|!2)
//     &, |: Bitwise
//        (Can be used on booleans as well as vectors.)
//     (There are no operators for NAND and NOR and unary !.)
//     ~: Extended constant (D = {1[2:0], 2[2:0]})
//     ,: Combine (D = {1[11:6], 2[5:0]})
//     ?: Conditional (D = 2 ? `0 : 1)
//   Load (Eg: "c=a{b") (D = [1 + 2] (typically 1 would be an immediate offset):
//     {: Load
//   Store (Eg: "0=a}b") ([2] = 1):
//     }: Store
//
// A full-width immediate load sequence, to load octal 2017 is:
//   a=2~0
//   b=1~7
//   a=a,b

// A typical local conditional branch sequence is:
//   a=0-6  // offset
//   c=c-1  // decrementing loop counter
//   p=a?c  // branch by a (to PC+1-6) if c is non-negative (MSB==0)


m4_makerchip_module
/* verilator lint_on WIDTH */  // Let's be strict about bit widths.

   m4_define(M4_NUM_INSTRS, 12)
   logic [39:0] instrs [0:M4_NUM_INSTRS-1];


   // =======
   // Program
   // =======

   // Add 1,2,3,...,10 (in that order).
   // Store incremental results in memory locations 0..9. (1, 3, 6, 10, ...)
   //
   // Regs:
   // b: cnt
   // c: ten
   // d: out
   // e: tmp
   // f: offset
   // g: store addr

   assign instrs = '{
      "g=0~0", //     store_addr = 0
      "b=0~1", //     cnt = 1
      "c=1~2", //     ten = 10
      "d=0~0", //     out = 0
      "f=0-6", //     offset = -6
      "d=d+b", //  -> out += cnt
      "0=d}g", //     store out at store_addr
      "b=b+1", //     cnt ++
      "g=g+1", //     store_addr++
      "e=c-b", //     tmp = 10 - cnt
      "p=f?e", //  ^- branch back if tmp >= 0
      "P=0-1"  //     TERMINATE by jumping to -1
   };


\TLV
   
   // =======
   // The CPU
   // =======
   
!  $reset = *reset;

   |fetch
      @0
         
         /instr
            $reset = /top<>0$reset;
            
            //?$fetch  // We'll need this once there are invalid cycles.

            // =====
            // Fetch
            // =====

!           $raw[39:0] = *instrs\[$Pc[3:0]\];

            // ======
            // DECODE
            // ======

            // Characters
            $dest_char[7:0] = $raw[39:32];
            /src[2:1]
               $char[7:0] = (#src == 1) ? /instr$raw[23:16] : /instr$raw[7:0];
            $op_char[7:0] = $raw[15:8];

            // Dest
            $dest_is_reg = $dest_char >= "a" && $dest_char <= "h";
            $dest_tmp[7:0] = $dest_char - "a";
            $dest_reg[2:0] = $dest_tmp[2:0];
            $jump = $dest_char == "P";
            $branch = $dest_char == "p";
            $no_dest = $dest_char == "0";
            $write_pc = $jump || $branch;
            $dest_valid = $write_pc || $dest_is_reg;
            $illegal_dest = !($dest_is_reg || 
                              $branch || $jump || $no_dest);

            /src[*]
               // Src1
               $is_reg = $char >= "a" && $char <= "h";
               $reg_tmp[7:0] = $char - "a";
               $reg[2:0] = $reg_tmp[2:0];
               $is_imm = $char >= "0" && $char < "8";
               $imm_tmp[7:0] = $char - "0";
               $imm_value[2:0] = $imm_tmp[2:0];
               $illegal = !($is_reg || $is_imm);

            // Opcode:
            /op
               $char[7:0] = /instr$op_char;
               // Arithmetic
               $add = $char == "+";
               $sub = $char == "-";
               $mul = $char == "*";
               $div = $char == "/";
               // Compare and bool (w/ 1 bit rslt)
               $eq = $char == "=";
               $ne = $char == "!";
               $lt = $char == "<";
               $gt = $char == ">";
               $le = $char == "[";
               $ge = $char == "]";
               $and = $char == "&";
               $or = $char == "|";
               // Wide Immediate
               $wide_imm = $char == "~";
               $combine = $char == ",";
               // Conditional
               $conditional = $char == "?";
               // Memory
               $ld = $char == "{";
               $st = $char == "}";
               // Opcode classes:
               $arith = $add || $sub || $mul || $div;
               $compare = $eq || $ne || $lt || $gt || $le || $ge;
               $bitwise = $and || $or;
               $full = $arith || $bitwise || $wide_imm || $combine || $conditional;
               //$op3 = $compare || $full;
               $mem = $ld || $st;
               $illegal = !($compare || $full || $mem);
            $op_compare = /op$compare;
            $op_full = /op$full;
            $ld = /op$ld;
            $st = /op$st;
            $illegal = $illegal_dest || (| /src[*]$illegal) || /op$illegal;
            
            // ======
            // Reg Rd
            // ======
            
            /src[*]
               $local_is_reg = $is_reg;
               ?$local_is_reg
                  $reg_value[11:0] = /instr/reg[$reg]$Value;
               $valid = !$illegal;
               ?$valid
                  $value[11:0] = $is_reg      ? $reg_value :
                                                {9'b0, $imm_value}; // $is_imm
            
            
            // =======
            // Execute
            // =======
            
            ?$op_compare
               $compare_rslt =
                  /op$eq ? /src[1]$value == /src[2]$value :
                  /op$ne ? /src[1]$value != /src[2]$value :
                  /op$lt ? /src[1]$value < /src[2]$value :
                  /op$gt ? /src[1]$value > /src[2]$value :
                  /op$le ? /src[1]$value <= /src[2]$value :
                  /op$ge ? /src[1]$value >= /src[2]$value :
                           1'b0;
            ?$op_full
               $op_full_rslt[11:0] =
                  /op$add ? /src[1]$value + /src[2]$value :
                  /op$sub ? /src[1]$value - /src[2]$value :
                  /op$mul ? /src[1]$value * /src[2]$value :
                  /op$div ? /src[1]$value * /src[2]$value :
                  /op$and ? /src[1]$value & /src[2]$value :
                  /op$or ? /src[1]$value | /src[2]$value :
                  /op$wide_imm ? {6'b0, /src[1]$value[2:0], /src[2]$value[2:0]} :
                  /op$combine ? {/src[1]$value[5:0], /src[2]$value[5:0]} :
                  /op$conditional ? (/src[2]$value[11] ? 12'b0 : /src[1]$value) :
                                    12'b0;
            
            // =======
            // Next PC
            // =======
            
            // Jump (Dest = "P") and Branch (Dest = "p") Targets.
            ?$jump
               $jump_target[11:0] = $rslt;
            ?$branch
               $branch_target[11:0] = $Pc + 12'b1 + $rslt;
            
            //?$fetch_or_reset
            $Pc[11:0] <=
               $reset ? 0 :
               $jump  ? $jump_target :
               $branch ? $branch_target :
               //$stall ? $RETAIN :
                        $Pc + 12'b1;
            
            // ?$fetch
            
            // ====
            // Load
            // ====
            
            ?$ld
               $addr[11:0] = /src[1]$value + /src[2]$value;
               $ld_rslt[11:0] = /mem[$addr[4:0]]$Word;
            
            // =========
            // Reg Write
            // =========
            
            ?$dest_valid
               $rslt[11:0] =
                  $op_full ? $op_full_rslt :
                  $op_compare ? {12{$compare_rslt}} :
                  $ld ? $ld_rslt :
                        12'b0;
               
         // Array writes are not currently permitted to use assignment
         // syntax, so \always_comb is used, and this must be outside of
         // when conditions, so we need to use if. <<1 because no <= support
         // in this context. (This limitation will be lifted.)
         /instr
            // Store mem write.
            /mem[31:0]
            \always_comb
               if ($st) // && $fetch
                  /mem[/src[2]$value[4:0]]<<1$$Word[11:0] = /src[1]$value;
            // Reg file write.
            /reg[7:0]
            \always_comb
               if ($dest_is_reg) // && $fetch
                  /reg[$dest_reg]<<1$$Value[11:0] = $rslt;
            
            
   // Assert these to end simulation (before Makerchip cycle limit).
!  *passed = ! *reset && *cyc_cnt > 1000 || |fetch/instr>>3$Pc == 12'hfff;
!  *failed = ! *reset && ! |fetch/instr>>3$reset && |fetch/instr>>3$illegal;
\SV
   endmodule
