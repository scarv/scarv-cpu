
`include "xcfi_macros.sv"
`include "xcfi_macros_packed.vh"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [ 2:0] pw          = `INSTR_PACK_WIDTH << 1;

wire [63:0] insn_result = `PW_CLMUL32(`RS1, `RS2, 32);

assign spec_valid       = rvfi_valid && dec_xc_pclmul_l;
assign spec_trap        = 1'b0   ;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = `FIELD_RS2_ADDR;
assign spec_rs3_addr    = 0;
assign spec_rd_addr     = `FIELD_RD_ADDR;
assign spec_rd_wdata    = spec_rd_addr ? insn_result[31:0] : {XLEN{1'b0}};
assign spec_rd_wide     = 1'b0;
assign spec_rd_wdatahi  = 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 4;
assign spec_mem_addr    = 0;
assign spec_mem_rmask   = 0;
assign spec_mem_wmask   = 0;
assign spec_mem_wdata   = 0;

endmodule

