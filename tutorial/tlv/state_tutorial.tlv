\m4_TLV_version 1d: tl-x.org
\SV
   // -------------------------------------------------------------------------------
   // This code implements a bank account balance.
   // Transactions consist of deposits and withdrawals.
   // -------------------------------------------------------------------------------

   m4_makerchip_module   // A generic module declaration macro instantiation
      // Note: We do not ignore width mismatch in this example.
\TLV

   |bank
      @0
         $reset = *reset;
      

      // ----------------------------------------------------------------------------
      // Explicitly assign inputs.
      // Assign/randomize initial balance, account action, and amount to deposit or withdraw
      // ----------------------------------------------------------------------------
      @1
         $init_balance[15:0] = 16'b1; // initial balance
         m4_rand($action, 0, 0)       // deposit = 0; withdrawal = 1
         m4_rand($transaction, 1, 0)  // 75% chance of valid (01, 10, 11); 25% chance of invalid (00)
         m4_rand($rand_amount, 10, 0) // amount to deposit or withdraw
         $amount[15:0] = {5'b0, $rand_amount};


      // ---
      // DUT
      // ---
      @2
         $valid_transaction = $transaction != 2'b0;
         $withdraw_error = $action == 1'b1 && $amount > $Balance ? 1'b1 : // true if withdrawal amount is greater than current balance
                                                                   1'b0;  // false otherwise
         $valid_transaction_or_reset = ($valid_transaction && !$withdraw_error) || $reset;
         
         ?$valid_transaction_or_reset
            $Balance[15:0] <= $reset          ? $init_balance :      // set to init_balance at the beginning
                              $action == 1'b0 ? $Balance + $amount : // deposit amount
                                                $Balance - $amount;  // withdraw amount
            
            //[(1)] Create $NumTransactions to count how many successful transactions occur.


      // -----------------
      // Print transaction
      // -----------------
      @3
         \SV_plus
            always_ff @(posedge clk) begin
               if ($valid_transaction && ! $reset) begin
                  if (!$withdraw_error) begin
                     //[(1)] \$display(" Transaction #: \%0d", $NumTransactions);
                     \$display("     \$\%5d \%0s\ $\%4d = \$\%5d", $Balance, $action == 1'b0 ? "+" : "-", $amount, <<1$Balance);
                  end else begin
                     \$display(" Insufficient funds. Balance: \$\%5d Withdrawal: \$\%4d", <<1$Balance, $amount);
                  end
               end
            end
      

      // ---------------------------------------------------
      // Test for Positive Remaining Balance after 20 Cycles
      // ---------------------------------------------------
      @4
         $CycCount[15:0] <= $reset ? 16'b0 : $CycCount + 16'b1;
         *passed = $Balance[15] == 1'b0 && $CycCount > 16'd20;

\SV
endmodule
