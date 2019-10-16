
`include "xcfi_macros.sv"
`include "xcfi_macros_packed.vh"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [ 1:0] pw          = `INSTR_PACK_WIDTH;

// Automatically accesses RS1 and RS2
`PACK_WIDTH_ARITH_OPERATION_RESULT(*,0)

 // From the PACK_WIDTH_ARITH_OPERATION_RESULT macro.
wire [31:0] insn_result = result;

assign spec_valid       = rvfi_valid && dec_xc_pmul_l;
assign spec_trap        = 1'b0   ;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = `FIELD_RS2_ADDR;
assign spec_rs3_addr    = 0;
assign spec_rd_addr     = `FIELD_RD_ADDR;
assign spec_rd_wdata    = spec_rd_addr ? insn_result : {XLEN{1'b0}};
assign spec_rd_wide     = 1'b0;
assign spec_rd_wdatahi  = 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 4;
assign spec_mem_addr    = 0;
assign spec_mem_rmask   = 0;
assign spec_mem_wmask   = 0;
assign spec_mem_wdata   = 0;

endmodule

