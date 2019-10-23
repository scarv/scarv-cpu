
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [31:0] insn_result;

xc_aessub_checker i_xc_aessub_checker(
.clock (1'b0         ), // Checker is completely combinatorial
.reset (1'b0         ), // Checker is completely combinatorial
.valid (spec_valid   ), // Are the inputs valid?
.rs1   (`RS1         ), // Input source register 1
.rs2   (`RS2         ), // Input source register 2
.enc   (1'b0         ), // Perform encrypt (set) or decrypt (clear).
.rot   (1'b0         ), // Perform encrypt (set) or decrypt (clear).
.ready (             ), // Checker always completes in once cycle.
.result(insn_result  )  // 
);

assign spec_valid       = rvfi_valid && dec_xc_aessub_dec;
assign spec_trap        = 1'b0;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = `FIELD_RS2_ADDR;
assign spec_rs3_addr    = 0;
assign spec_rd_addr     = `FIELD_RD_ADDR;
assign spec_rd_wdata    = |spec_rd_addr ? insn_result : 0;
assign spec_rd_wide     = 1'b0;
assign spec_rd_wdatahi  = 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 4;
assign spec_mem_addr    = 0;
assign spec_mem_rmask   = 0;
assign spec_mem_wmask   = 0;
assign spec_mem_wdata   = 0;

endmodule
