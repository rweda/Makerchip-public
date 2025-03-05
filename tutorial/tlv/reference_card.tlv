\m4_TLV_version 1d: tl-x.org
// -------------------------
// TL-Verilog Reference Card
// -------------------------

\TLV reference_card()
   // Identifiers:
   |pipeline         // Pipeline
   /beh_hier         // Behavioral hierarchy
   ?$when            // When condition
   ?$When            // When state condition
   @1                // Pipestage (@-1 permitted)
   @+=1              // Subsequent pipestage (or @+=-1 for prior pipestage)
   @++               // Shorthand for @+=1
   $pipesignal       // Pipesignal
   $StateSignal      // State signal
   $$assigned_signal // Assigned pipesignal or state signal in context other than
   $$AssignedStateSig//   left-hand side (i.e. "$sig =", "{$sig, ...} =", and "$$Sig <=".
   *SV_signal        // SV signal reference
   **SV_type         // SV datatype
   >>2               // Ahead reference (>>-2 permitted)
   <<2               // Behind reference
   <>0               // Naturally-aligned reference (i.e. >>0)
   ^attribute        // (mixed case) Attribute

   // Keywords:
   \SV          // Region containing SV code
   \TLV         // Region of TL-Verilog code
   \SV_plus     // Region or scope containing SV code with TLV references
   \always_comb // Always_comb block with TLV references (no begin/end)
   \source      // For use by pre-processors to associate source code line numbers
   \end_source  // Goes with \source
   $ANY         // Any signal in the scope; used to create transaction flow
   $RETAIN      // Shorthand for the previous value of the assigned signal


   // Special-Case Variants:
   // Within \SV_plus blocks, if support for Verilog 2005 and earlier is needed:
   $$^reg_pipesignal   // These explicitly identify an assignment that must be of
   $$^RegStateSignal   //   'reg' type (vs. 'wire') (sequential assignment, vs.
   $$^ANY              //    'assign' and connectivity).





// Just to allow simulation to pass...
\SV
   m4_makerchip_module
      assign passed = 1;
   endmodule
