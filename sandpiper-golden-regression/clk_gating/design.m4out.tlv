\TLV_version [\source run/gen/clk_gating/design.tlv] 1d: tl-x.org
\SV
module clk_gating(input logic clk, input logic reset, input logic [15:0] cyc_cnt, output logic passed, output logic failed); 
   logic [7:0] nine;
\TLV
   // Pipesignal and state assignment under when earlier condition.
   |pipe
      @0
         $reset = *reset;
         $valid = $reset ? 1'b1 : ! >>1$valid;  // Assert every other cycle.
         $valid2 = $reset ? 1'b1 : >>1$reset ? 1'b0 : >>3$valid2;  // Deassert every 3rd cycle.
   |pipe
      ?$valid
         @0
            $cnt[7:0] = *cyc_cnt[7:0];
         @2
            $State[7:0] <= $cnt;
         @4
            $bar[7:0] = $cnt;
            // Pipesignal and state assignment under same-stage nested when condition.
            /hier[1:0]
               $valid2 = |pipe$valid2;
               ?$valid2
                  $foo[7:0] = |pipe$bar;
                  $Foo[7:0] <= |pipe$bar;
                  $Cnt[7:0] <= |pipe$reset ? 8'b0 : $Cnt + 1'b1;
                  \SV_plus
                     always_ff @(posedge clk) begin
                        if (|pipe$valid && $valid2 && ! |pipe$reset && ! |pipe<<4$reset) begin
                           \$display("hier[\%h], cyc: \%h, Cnt: \%h", #hier, *cyc_cnt, <<1$Cnt);
                        end
                     end
            `BOGUS_USE($State)
      
   |pipe2
      @0
         $odd = *reset ? 0 : ! >>1$odd;
         $bob = >>1$odd;
      ?$odd
         @0
            $State <= *reset ? 0 : |pipe2$odd;
            `BOGUS_USE(<<1$State)
         // Conditioned $ANY.
         /copy
            @0
               $ANY = |pipe2$ANY;
            @0
               `BOGUS_USE($bob)
            // Block and multiple state assignments.
            @3
               \always_comb
                  <<1$$One[7:0] = 8'd1;
                  <<1$$Two[7:0] = 8'd2;
               \SV_plus
                  assign <<1$$Three[7:0] = 8'd3;
                  assign <<1$$Four[7:0] = 8'd4;
               {$Five[7:0], $Six[7:0]} <= {8'd5, 8'd6};
               {<<1$Seven[7:0], $eight[7:0], *nine} = {8'd7, 8'd8, 8'd9};
               `BOGUS_USE($One $Two $Three $Four $Five $Six $Seven $eight)
               
               
                  
   // Detect failure.
   |pipe
      @4
         /hier[*]
            $bad = ($foo != <<1$Foo) && (|pipe$valid && |pipe$valid2);
            $final_cnt = $Cnt == 8'd12;
            $failed = ! *reset && ! |pipe$reset && ($bad || (*cyc_cnt == 39 && ! $final_cnt));
      
         // Fail if either /hier[*] failed.
         *passed = *cyc_cnt > 40;
         *failed = | /hier[*]$failed;
         

\SV
endmodule
