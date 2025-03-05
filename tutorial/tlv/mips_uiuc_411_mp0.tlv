\m4_TLV_version 1c: tl-x.org
\SV

// ================
// UIUC ECE 411 MP0
// ================

// M4 preprocessor parameters
m4_define(m4_is_piped, true)  // true/false

// Define m4_piped(if_piped, if_not_piped)
m4_define(m4_piped, ['m4_ifelse(m4_is_piped, true, $1, $2)'])


// ----------------
// File: lc3b_types

typedef logic [15:0] lc3b_word;
typedef logic  [7:0] lc3b_byte;

typedef logic  [8:0] lc3b_offset9;
typedef logic  [5:0] lc3b_offset6;

typedef logic  [2:0] lc3b_reg;
typedef logic  [2:0] lc3b_nzp;
typedef logic  [1:0] lc3b_mem_wmask;


typedef enum bit [3:0] {
    op_add  = 4'b0001,
    op_and  = 4'b0101,
    op_br   = 4'b0000,
    op_jmp  = 4'b1100,   /* also RET */
    op_jsr  = 4'b0100,   /* also JSRR */
    op_ldb  = 4'b0010,
    op_ldi  = 4'b1010,
    op_lea  = 4'b1110,
    op_not  = 4'b1001,
    op_ldr  = 4'b0110,
    op_rti  = 4'b1000,
    op_shf  = 4'b1101,
    op_stb  = 4'b0011,
    op_sti  = 4'b1011,
    op_str  = 4'b0111,
    op_trap = 4'b1111
} lc3b_opcode;

typedef enum bit [3:0] {
    alu_add,
    alu_and,
    alu_not
    //alu_pass,
    //alu_sll,
    //alu_srl,
    //alu_sra
} lc3b_aluop;



m4_makerchip_module
\TLV
   /*
   
   // Fetch pipe fetches an insruction.
   |fetch
      @1   // "fetch1"
      @2   // "fetch2"
   // A pipeline for execution, beginning from fetch response from memory.
   |exe
      @2   // "fetch2"
      @3   // "fetch3"
      @4   // "decode"
      @5   // exe ("add", "and", "not", "calc_addr", "br")
      @6   // "ld1/st1", "br_taken", or next "fetch 1"
      @7   // "st2", next "fetch 1" after "br_taken"
   // Pipeline for memory response for fetch/load/store.
   // Stages align with those of the instruction fetch response.
   |resp
      @2   // "ld1/st2"
      @3   // "ld2", IR, next "fetch1" for store
      @4   // next "fetch1" for load
   */
   
   // Fetch next instruction
   |fetch
      // Next PC
      @0
         $reset = *reset;
         
         $valid_br_taken = >top|exe%+6$valid_br_taken;
         $pc[15:0] =
            $reset ? 16'b0 :
            ($valid_br_taken && %prev$instr_valid)
               ? // Add to PC (increment or branch).
                 %prev$pc +
                    (%prev$instr_valid
                       ? // increment
                         16'd2
                       : // branch
                         {{7{>top|exe%+m4_piped(6, 4)$offset9[8]}},  // sign ext
                          >top|exe%+m4_piped(6, 4)$offset9})         // branch target
               : $RETAIN;
               
      // Next instruction
      @1
         $instr_valid =
            // first instruction
            (%prev$reset && ! $reset) ||
            // store
            (>top|resp%+2$mem_resp && >top|resp%+2$StorePending) ||  // >top|resp%+2$st_resp_valid, but better timing.
            // load
            >top|resp%+3$ld_resp_valid ||
            // else (alu, branch not-taken)
            >top|exe%+5$valid_exe_inst;
   
   // Execute the instruction that was fetched.
   |exe
      //@2
      //   $reset = *reset;
         
      @3
         $instr_valid      = >top|resp%+0$fetch_resp_valid;    
         $ir[15:0] = $instr_valid ? >top|resp%+0$mem_rdata :
                                    $RETAIN;
      
      // Decode
      @4
         // Condition on valid instruction if pipelined implementation.
         m4_piped(,$one = 1'b1;)
         m4_piped(?$instr_valid, ?$one)
            // Instruction fields:
            $opcode[3:0]  = $ir[15:12];
            $dest[2:0]    = $ir[11:9];
            $src1[2:0]    = $ir[8:6];
            $src2[2:0]    = $ir[2:0];
            $offset6[5:0] = $ir[5:0];
            $offset9[8:0] = $ir[8:0];
         
            // Opcode Decode:
            \always_comb
               casez($opcode)
                  op_add:  $$aluop[3:0] = alu_add;
                  op_and:  $aluop = alu_and;
                  op_not:  $aluop = alu_not;
                  //op_pass: $aluop = alu_pass;
                  //op_sll:  $aluop = alu_sll;
                  //op_srl:  $aluop = alu_srl;
                  //op_sra:  $aluop = alu_sra;
                  default: $aluop = 'x;
               endcase
            $br = $opcode == op_br;
         $valid_ld = $instr_valid && $opcode == op_ldr;
         $valid_st = $instr_valid && $opcode == op_str;
         $valid_mem_instr = $valid_ld || $valid_st;
            
      // Regfile
      @4
         regfile rf(.clk(*clk),
                    .load(>top|resp%-1$ld_resp_valid),
                    .in(($instr_valid && ! $valid_mem_instr)
                              ? %+1$rslt :
                                >top|resp%-1$mem_rdata),
                    .src_a($src1),
                    .src_b($src2),
                    .dest($dest),
                    .reg_a($$reg_a[15:0]),
                    .reg_b($$reg_b[15:0]));

      // ALU
      @5
         $adj_offset6[15:0] = {{10{$offset6[5]}}, $offset6};
         alu alu(.aluop($aluop),
                 .a($reg_a),
                 .b($valid_mem_instr ? $adj_offset6 : $reg_b),
                 .f($$rslt[15:0]));

      // Branch target
      @5
         $cc[2:0] = {$rslt[15], $rslt == 16'b0, | $rslt[14:0]};
      @6
         $valid_br_taken = $instr_valid && $br &&
                           $cc == m4_piped(, %-2)$dest;  // CCCOMP
         // Cases that go to "fetch 1" after "exe".
         $valid_exe_inst = $instr_valid && !($valid_mem_instr || $valid_br_taken);
         
      // MAR/MDR
      @5
         $mar[15:0] =
            $valid_mem_instr          ? $rslt :             // ld/st
            >top|fetch%-4$instr_valid ? >top|fetch%-4$pc :  // instruction load
                                        $RETAIN;
         // Note: MDR as spec'ed holds both ld and store data, which gets in the way for
         //       a pipelined design, so I just let load data stage separately.
         $mdr[15:0] =
            $valid_st     ? $rslt :     // st
                            $RETAIN;
      // Memory
      @6
         $fetch = >top|fetch%-4$instr_valid;
         /*
         magic_memory mem(.clk(clk),
                          .read($valid_ld || $fetch),
                          .write($valid_st),
                          .wmask(2'b11),
                          .address($mar),
                          .wdata($reg_a),
                          .resp($$mem_resp),
                          .rdata($$mem_rdata[15:0]));
         */
         // Just return random data for now, 2 cycles later.
         m4_rand($mem_rdata, 15, 0)
         $mem_op = $valid_mem_instr || $fetch;
         $mem_resp = %+2$mem_op;
   
   // Handle response from memory, whether fetch, ld, or st.
   |resp
      @1
         $reset = *reset;
      @2
         // Remember the purpose of the memory operation: fetch, load, or store.
         {%next$FetchPending,
          %next$LoadPending,
          $next_store_pending} =
            $reset || $mem_resp        ? 3'b000 :
            >top|fetch%+0$instr_valid  ? 3'b100 :
            >top|exe%+4$valid_ld       ? 3'b010 :
            >top|exe%+5$valid_st       ? 3'b001 :
                                         {$FetchPending, $LoadPending, $StorePending};  // $RETAIN
         %next$StorePending = $next_store_pending;
         
      // This pipeline is fed from memory response.
      @2
         $mem_resp = >top|exe%+4$mem_resp;
         $mem_rdata[15:0] = >top|exe%+4$mem_rdata;
         
      // Characterize response.
      @3
         $ld_resp_valid    = $mem_resp && $LoadPending;
         //$st_resp_valid    = $mem_resp && $StorePending;
         $fetch_resp_valid = $mem_resp && $FetchPending;
         
   
   // ---------
   // Testbench
   
   // Just run for fixed number of cycles
   $reset = *reset;
   %next$Cnt[15:0] = $reset ? 16'b0 :
                              $Cnt + 16'b1;
   *passed = $Cnt > 16'd200;
\SV
endmodule




//
// Provided files (alphabetically):
//



// -------------
// File: alu.sv

module alu
(
    input lc3b_aluop aluop,
    input lc3b_word a, b,
    output lc3b_word f
);

always_comb
begin
    case (aluop)
        alu_add: f = a + b;
        alu_and: f = a & b;
        alu_not: f = ~a;
        //alu_pass: f = a;
        //alu_sll: f = a << b;
        //alu_srl: f = a >> b;
        //alu_sra: f = $signed(a) >>> b;
        default: $display("Unknown aluop");
    endcase
end

endmodule : alu



// ---------------------
// File: magic_memory.sv

/*
 * Magic memory
 */
module magic_memory
(
    input clk,

    /* Port A */
    input read,
    input write,
    input [1:0] wmask,
    input [15:0] address,
    input [15:0] wdata,
    output logic resp,
    output logic [15:0] rdata
);

logic [7:0] mem [0:2**($bits(address))-1];
logic [15:0] internal_address;

/* Initialize memory contents from memory.lst file */
//initial
//begin
//    $readmemh("memory.lst", mem);
//end

/* Calculate internal address */
assign internal_address = {address[15:1], 1'b0};

/* Read */
always_comb
begin : mem_read
    rdata = {mem[internal_address+1], mem[internal_address]};
end : mem_read

/* Write */
always @(posedge clk)
begin : mem_write
    if (write)
    begin
        if (wmask[1])
        begin
            mem[internal_address+1] = wdata[15:8];
        end

        if (wmask[0])
        begin
            mem[internal_address] = wdata[7:0];
        end
    end
end : mem_write

/* Magic memory responds immediately */
assign resp = read | write;

endmodule : magic_memory




// ----------------
// File: regfile.sv

module regfile
(
    input clk,
    input load,
    input lc3b_word in,
    input lc3b_reg src_a, src_b, dest,
    output lc3b_word reg_a, reg_b
);

lc3b_word data [7:0] /* synthesis ramstyle = "logic" */;

/* Altera device registers are 0 at power on. Specify this
 * so that Modelsim works as expected.
 */
initial
begin
    for (int i = 0; i < $size(data); i++)
    begin
        data[i] = 16'b0;
    end
end

always_ff @(posedge clk)
begin
    if (load == 1)
    begin
        data[dest] = in;
    end
end

always_comb
begin
    reg_a = data[src_a];
    reg_b = data[src_b];
end

endmodule : regfile
