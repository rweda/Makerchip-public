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



// The ISA:

// What's interesting about this ISA?
//   o It's super small.
//   o It's easy to play with and learn from.
//   o Instructions are short, kind-of-readable strings, so no assembler is needed.
//     They would map directly to a denser (~17-bit) encoding if desired.
//   o The only instruction formats are op, load, and store.
//   o Branch/Jump: There is no special format for control-flow instructions. Any
//     instruction can write the PC (relative or absolute). A conditional branch
//     will typically utilize a condition operation that provides a (relative) branch
//     target or zero.
//
// Branch prediction ISA considerations:
//   Typical branch predication techniques can be utilized for conditional branches
//   with an immediate offset (eg p=4?c), though the immediate is VERY limited
//   (small, positive). The immediate could also be used to predicate off subsequent
//   instructions. By convention, b is a branch target register, so it is
//   reasonable to predict the target of "p=b?c", using a stale side copy of b.
//
// ISA Machine Arch:
//   o Single stage "pipeline".
//   o 8 registers.
//   o A word is 12 bits wide.
//   o Operators operate on and produce words as signed or unsigned values and
//     booleans (all-zero/one)
//
//
// Instruction Set:
//
// Instructions are 5-character strings: "D=1o2"
//
// =: Appears in every instruction (just for readability).
// D, 2, 1: "a" - "h" for registers;
//          "0" - "7" for immediate constants (sources, or "0" for unused dest);
//          "P" for absolute dest PC (jump);
//          "p" for relative dest PC (branch), PC = PC + 1 + result(signed).
//
// o: operator
//   Op: (D = 1 o 2) (Eg: "c=a+b"):
//     Arithmetic:
//       +, -, *, /: *, / are unsigned.
//     Compare: (D = (1 o 2) ? all-1s : 0)
//       =, !, <, >, [, ]: ] is >=, [ is <=
//          (On booleans these are XNOR, XOR, !1&2, 1&!2, !1|2, 1|!2)
//     Bitwise:
//       &, |: (Can be used on booleans as well as vectors.)
//     (There are no operators for NAND and NOR and unary !.)
//     Concatination:
//       ~: Extended constant (D = {1[2:0], 2[2:0]})
//       ,: Combine (D = {1[5:0], 2[5:0]})
//     Conditional:
//       ?: (D = 2 ? `0 : 1)
//   Load (Eg: "c=a{b"):
//     {: Load (D = [1 + 2] (typically 1 would be an immediate offset)
//   Store (Eg: "0=a}b"):
//     }: Store ([2] = D = 1) (typically D would be "0" (no dest))
//
// A full-width immediate load sequence, to load octal 2017 is:
//   a=2~0
//   b=1~7
//   a=a,b

// A typical local conditional branch sequence is:
//   a=0-6  // offset
//   c=c-1  // decrementing loop counter
//   p=a?c  // branch by a (to PC+1-6) if c is non-negative (MSB==0)



// The CPU

// The code is parameterized, using the M4 macro preprocessor, for adjustable pipeline
// depth.
//
// Overview:
//   o One instruction traverses the single free-flowing CPU pipeline per cycle.
//   o There is no branch or condition or target prediction.
//   o Instructions are in-order, but the uarch supports loads that return their
//     data out of order (though, they don't).
//
// Replays:
//
// The PC is redirected, and inflight instructions are squashed (their results are
// not committed) for:
//   o jumps (go to jump target)
//   o unconditioned and non-negative-conditioned branches (go to branch target)
//   o instructions that consume a pending register (replay instruction immediately)
//     (See "Loads", below.)
//   o loads that write to a pending register (replay instruction immediately)
//     (See "Loads", below.)
//
// Loads:
//
// Load destination registers are marked "pending", and reads of pending
// registers are replayed. (This could again result in a read of the same
// pending register, to repeat until the load returns.) Writes to pending registers
// are also replayed, so there can be at most one oustanding load to any given
// register. This way, out-of-order loads are supported (though loads are implemented
// to have a fixed latency). A returning load reserves a slot at the beginning
// of the pipeline to reserve a register write port. The returning load writes its
// result and clears the destination register's pending flag.
//
// To support L1 and L2 caches, it would be reasonable to delay register write (if
// necessary) to wait for L1 hits (extending the bypass window), and mark "pending"
// for L1 misses.
//
// Bypass:
//
// Register bypass is provided if one instruction's result is not written to the
// register file in time for the next instruction's read. An additional bypass is
// provided for each additional cycle between read and write.



// /============\
// | Parameters |
// \============/

// Adjust the parameters below to define the pipeline depth and staging.

// Pipeline stages for each piece of logic:
m4_define(M4_PC_MUX_STAGE, 0)
m4_define(M4_FETCH_STAGE, 0)
m4_define(M4_DECODE_STAGE, 1)
m4_define(M4_REG_RD_STAGE, 1)
m4_define(M4_EXECUTE_STAGE, 2)
m4_define(M4_BRANCH_TARGET_CALC_STAGE, 3)
m4_define(M4_MEM_STAGE, 3)
m4_define(M4_REG_WR_STAGE, 3)

// Feedback latencies:
m4_define(M4_REG_BYPASS_STAGES, m4_eval(M4_REG_WR_STAGE - M4_REG_RD_STAGE))
m4_define(M4_JUMP_BUBBLES, m4_eval(M4_EXECUTE_STAGE - M4_PC_MUX_STAGE + 0))  // +1 or +0. +0 aligns PC_MUX with EXECUTE
m4_define(M4_BRANCH_BUBBLES, m4_eval(M4_BRANCH_TARGET_CALC_STAGE - M4_PC_MUX_STAGE + 0))  // +0 aligns PC_MUX with BRANCH_TARGET_CALC. Must be either equal to or one greater than JUMP_LATENCY.
m4_define(M4_LOAD_LATENCY, 4)   // From load to returning load
m4_define(M4_REPLAY_LATENCY, m4_eval(M4_EXECUTE_STAGE - M4_PC_MUX_STAGE + 1))

// Machine parameters:
m4_define(M4_NUM_INSTRS, 13)  // (Must match program exactly.)



m4_makerchip_module
/* verilator lint_on WIDTH */  // Let's be strict about bit widths.
   logic [39:0] instrs [0:M4_NUM_INSTRS-1];


   // /=============\
   // | The Program |
   // \=============/

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
      "h=0{c", //     load the final value
      "P=0-1"  //     TERMINATE by jumping to -1
   };


\TLV
   
   // /=========\
   // | The CPU |
   // \=========/
   
!  $reset = *reset;

   |fetch
      /instr
         @M4_FETCH_STAGE
            $reset = /top<>0$reset;

         @M4_FETCH_STAGE
            //?$fetch  // We'll need this once there are invalid cycles.

            // =====
            // Fetch
            // =====

!           $raw[39:0] = *instrs\[$Pc[3:0]\];
            
         // A returning load clobbers the instruction.
         @M4_PC_MUX_STAGE
            $returning_ld = >>M4_LOAD_LATENCY$valid_ld;
         @M4_DECODE_STAGE
            $returning_ld_reg[2:0] = >>M4_LOAD_LATENCY$dest_reg;
         
         @M4_PC_MUX_STAGE
            // =======
            // Next PC
            // =======
            
            //?$fetch_or_reset
            $Pc[11:0] <=
               $reset ? 0 :
               >>M4_BRANCH_BUBBLES$valid_mispred_branch ? >>M4_BRANCH_BUBBLES$branch_target :
               >>M4_JUMP_BUBBLES$valid_jump ? >>M4_JUMP_BUBBLES$jump_target :
               >>m4_eval(M4_REPLAY_LATENCY-1)$replay ? >>m4_eval(M4_REPLAY_LATENCY-1)$Pc :
               $returning_ld ? $RETAIN :  // Returning load, so next PC is the previous next PC (unless there was a branch that wasn't visible yet)
                        $Pc + 12'b1;

         @M4_DECODE_STAGE

            // ======
            // DECODE
            // ======

            // Characters
            $dest_char[7:0] = $raw[39:32];
            /src[2:1]
               $char[7:0] = (#src == 1) ? /instr$raw[23:16] : /instr$raw[7:0];
            $op_char[7:0] = $raw[15:8];

            // Dest
            $dest_is_reg = ($dest_char >= "a" && $dest_char <= "h") || $returning_ld;
            $dest_tmp[7:0] = $dest_char - "a";
            $dest_reg[2:0] = $returning_ld ? $returning_ld_reg : $dest_tmp[2:0];
            $jump = $dest_char == "P";
            $branch = $dest_char == "p";
            $no_dest = $dest_char == "0";
            $write_pc = $jump || $branch;
            $dest_valid = $write_pc || $dest_is_reg;
            $illegal_dest = !($dest_is_reg || 
                              (($branch || $jump || $no_dest) && ! $ld));  // Load must have reg dest.

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
            
            // Branch instructions with a condition (that might be worth predicting).
            $conditional_branch = $branch && /op$conditional;
            
         @M4_REG_RD_STAGE
            // ======
            // Reg Rd
            // ======
            
            /regs[7:0]
            /src[*]
               $is_reg_condition = $is_reg;
               ?$is_reg_condition
                  $reg_value[11:0] =
                     // Bypass stages:
                     m4_ifelse(m4_eval(M4_REG_BYPASS_STAGES >= 1), 0, ,(/instr>>1$dest_is_reg && (/instr>>1$dest_reg == $reg)) ? /instr>>1$rslt :)
                     m4_ifelse(m4_eval(M4_REG_BYPASS_STAGES >= 2), 0, ,(/instr>>2$dest_is_reg && (/instr>>2$dest_reg == $reg)) ? /instr>>2$rslt :)
                     m4_ifelse(m4_eval(M4_REG_BYPASS_STAGES >= 3), 0, ,(/instr>>3$dest_is_reg && (/instr>>3$dest_reg == $reg)) ? /instr>>3$rslt :)
                     /instr/regs[$reg]>>M4_REG_BYPASS_STAGES$Value;
               $valid = !$illegal;
               ?$valid
                  $value[11:0] = $is_reg ? $reg_value :
                                           {9'b0, $imm_value}; // $is_imm
               $replay = $is_reg && /instr/regs[$reg]>>1$next_pending;
            $replay = | /src[*]$replay || ($dest_is_reg && /regs[$dest_reg]>>1$next_pending);
            
         @M4_EXECUTE_STAGE
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
            ?$dest_valid
               $rslt[11:0] =
                  $returning_ld ? >>M4_LOAD_LATENCY$ld_rslt :
                  $st ? /src[1]$value :
                  $op_full ? $op_full_rslt :
                  $op_compare ? {12{$compare_rslt}} :
                  //$ld ? $ld_rslt :
                        12'b0;
               
         @M4_EXECUTE_STAGE
            // =========
            // Target PC
            // =========
            
            // Jump (Dest = "P") and Branch (Dest = "p") Targets.
            ?$jump
               $jump_target[11:0] = $rslt;
            // Always predict taken; mispredict if jump or unconditioned branch or
            //   conditioned branch with positive condition.
            $mispred_branch = $branch && ! ($conditional_branch && /src[2]$value[11]);
            $valid_jump = $jump && ! $squash;
            $valid_mispred_branch = $mispred_branch && ~$squash;
            $valid_ld = $ld && ! $squash;
            $valid_st = $st && ! $squash;
            $valid_illegal = $illegal && ! $squash;
            // Squash. Keep a count of the number of cycles remaining in the shadow of a mispredict.
            $squash = | $SquashCnt || $returning_ld || $replay;
            $SquashCnt[2:0] <=
               $reset                ? 3'b0 :
               $valid_mispred_branch ? M4_BRANCH_BUBBLES :
               $valid_jump           ? M4_JUMP_BUBBLES :
               $replay               ? M4_REPLAY_LATENCY - 3'b1:
               $SquashCnt == 3'b0    ? 3'b0 :
                                       $SquashCnt - 3'b1;
         @M4_BRANCH_TARGET_CALC_STAGE
            ?$branch
               $branch_target[11:0] = $Pc + 12'b1 + $rslt;
            
            
            // ====
            // Load
            // ====
            
            /mem[31:0]
         ?$ld
            @M4_EXECUTE_STAGE
               $addr[11:0] = /src[1]$value + /src[2]$value;
            @M4_MEM_STAGE
               $ld_rslt[11:0] = /mem[$addr[4:0]]$Word;
         
         // Array writes are not currently permitted to use assignment
         // syntax, so \always_comb is used, and this must be outside of
         // when conditions, so we need to use if. <<1 because no <= support
         // in this context. (This limitation will be lifted.)

         @M4_MEM_STAGE
            // =====
            // Store
            // =====

            \always_comb
               if ($valid_st)
                  /mem[/src[2]$value[4:0]]<<1$$Word[11:0] = /src[1]$value;

         @M4_REG_WR_STAGE
            // =========
            // Reg Write
            // =========

            $reg_write = ($dest_is_reg && ! $squash) || $returning_ld;
            \always_comb
               if ($reg_write)
                  /regs[$dest_reg]<<1$$Value[11:0] = $reset ? 12'h0 : $rslt;
         
         // There's no bypass on pending, so we must write the same cycle we read.
         @M4_EXECUTE_STAGE
            /regs[*]
               $reg_match = /instr$dest_reg == #regs;
               $next_pending =  // Should be state, but need to consume prior to flop, which SandPiper doesn't support, yet.
                  /instr$reset ? 1'b0 :
                  // set for loads
                  /instr$valid_ld && $reg_match   ? 1'b1 :
                  // clear when load returns
                  /instr$returning_ld && $reg_match ? 1'b0 :
                               $RETAIN;

         
   // Assert these to end simulation (before the cycle limit).
!  *passed = ! *reset && |fetch/instr>>5$Pc == 12'hfff;
!  *failed = ! *reset && (*cyc_cnt > 1000 || (! |fetch/instr>>3$reset && |fetch/instr>>6$valid_illegal));
\SV
   endmodule
