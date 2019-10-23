
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [ 1:0] shamt       = d_data[31:30];

wire [31:0] insn_result;

fml_xc_sha3_checker i_sha3_checker (
.rs1   (`RS1        ), // Input source register 1
.rs2   (`RS2        ), // Input source register 2
.shamt (shamt       ), // Post-Shift Amount
.f_xy  (1'b0        ), // xc.sha3.xy instruction function
.f_x1  (1'b0        ), // xc.sha3.x1 instruction function
.f_x2  (1'b0        ), // xc.sha3.x2 instruction function
.f_x4  (1'b1        ), // xc.sha3.x4 instruction function
.f_yx  (1'b0        ), // xc.sha3.yx instruction function
.result(insn_result )  //
);

assign spec_valid       = rvfi_valid && dec_xc_sha3_x4;
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
