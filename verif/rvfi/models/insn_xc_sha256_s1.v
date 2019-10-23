
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

`define ROR32(a,b) ((a >> b) | (a << 32-b))
`define SRL32(a,b) ((a >> b)              )

wire [31:0] insn_result = (`ROR32(`RS1,17)) ^
                          (`ROR32(`RS1,19)) ^
                          (`SRL32(`RS1,10)) ;

assign spec_valid       = rvfi_valid && dec_xc_sha256_s1;
assign spec_trap        = 1'b0;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = 0;
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
