\m4_TLV_version 1b: tl-x.org
\SV

// Provides clk and reset to design.tlv.
// Instantiates design as design(.*) so additional inputs and outputs can be added.
// Ends simulation on max cycles argument below, or assertion of success signal.
// Additional testbench functionality can be added here, or within design using TLV.
// See: "top_module_tlv.m4" for definition.
m4_top_module_inst(dut, 100)
