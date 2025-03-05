\TLV_version [\source run/gen/bank/bank.tlv] 1c: tl-x.org
\SV
   // -------------------------------------------------------------------------------
   // This example comes from Redwood EDA, LLC's TL-Verilog Tutorial Series,
   // available here:
   //   redwoodeda.com/lab
   //
   // This code implements a bank account balance.
   // Transactions consist of deposits and withdrawals.
   // -------------------------------------------------------------------------------

   // An "\SV" region, like this one, is just straight SystemVerilog
   // (with m4 macro preprocessing), and in this case, it's just an
   // m4 macro instantiation.

   module bank(input logic clk, input logic reset, input logic [15:0] cyc_cnt, output logic passed, output logic failed);    /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_on UNOPTFLAT */   // A generic module declaration macro instantiation
   /* verilator lint_off WIDTH */

\TLV

   |bank
      @0
         $reset = *reset;
      
      // ----------------------------------------------------------------------------
      // Randomize initial balance, account action, and amount to deposit or withdraw
      // ----------------------------------------------------------------------------
      @1
         $init_balance[15:0] = 16'b1; // initial balance
         $action[0:0] = *RW_rand_vect[(0 + (0)) % 257 +: 1]; // deposit = 0; withdrawal = 1
         $transaction[1:0] = *RW_rand_vect[(124 + (0)) % 257 +: 2]; // 75% chance of valid (01, 10, 11); 25% chance of invalid (00)
         $amount[10:0] = *RW_rand_vect[(248 + (0)) % 257 +: 11]; // amount to deposit or withdraw
      
      // ---
      // DUT
      // ---
      @2
         $valid_transaction = $transaction != 2'b0;
         $withdraw_error = $action == 1'b1 && $amount > $Balance ? 1'b1 : // true if withdrawal amount is greater than current balance
                                                                   1'b0;  // false otherwise
         $valid_transaction_or_reset = ($valid_transaction && !$withdraw_error) || $reset;
         
         ?$valid_transaction_or_reset
            %next$Balance[15:0] = $reset          ? $init_balance :      // set to init_balance at the beginning
                                  $action == 1'b0 ? $Balance + $amount : // deposit amount
                                                    $Balance - $amount;  // withdraw amount
            
            //[(1)] make $NumTransaction count how many successful transactions occur
            %next$NumTransaction[8:0] = $reset ? 11'b1 : $NumTransaction + 11'b1;
      
      // -----------------
      // Print transaction
      // -----------------
      @3
         \SV_plus
            always_ff @(posedge clk) begin
               if ($valid_transaction) begin
                  if (!$withdraw_error) begin
                     \$display(" Transaction #: \%0d", $NumTransaction);
                     \$display("     $\%5d \%0s $\%4d = $\%5d", $Balance, $action == 1'b0 ? "+" : "-", $amount, %next$Balance);
                  end else begin
                     \$display(" Error: Not enough balance to withdraw that much.");
                     \$display("     Balance: $\%5d      Withdrawal Amount: $\%4d", $Balance, $amount);
                  end
               end
            end
      
      // ---------------------------------------------------
      // Test for Positive Remaining Balance after 20 Cycles
      // ---------------------------------------------------
      @4
         %next$CycCount[15:0] = $reset ? 16'b1 : $CycCount + 1;
         *passed = $Balance > 0 && $CycCount > 20;

\SV
endmodule

