\m4_TLV_version 1c: tl-x.org
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

   m4_top_module_def(bank)   // A generic module declaration macro instantiation
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
         m4_rand($action, 0, 0) // deposit = 0; withdrawal = 1
         m4_rand($transaction, 1, 0) // 75% chance of valid (01, 10, 11); 25% chance of invalid (00)
         m4_rand($amount, 10, 0) // amount to deposit or withdraw
      
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

