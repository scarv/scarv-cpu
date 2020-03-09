
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [XL:0] result_s1 = `RS2_HI              ;
wire [XL:0] result_s0 = `RS1_HI ^ `RS1 ^ `RS2;

assign spec_valid       = rvfi_valid && dec_mask_b_ior;
assign spec_trap        = 1'b0   ;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = `FIELD_RS2_ADDR;
assign spec_rs3_addr    = 0;
assign spec_rd_addr     = `FIELD_RD_ADDR;
assign spec_rd_wdata    = `FIELD_RD_ADDR ? result_s0 : 32'b0;
assign spec_rd_wide     = 1'b1;
assign spec_rd_wdatahi  = result_s1;
assign spec_pc_wdata    = rvfi_pc_rdata + 4;
assign spec_mem_addr    = 0;
assign spec_mem_rmask   = 0;
assign spec_mem_wmask   = 0;
assign spec_mem_wdata   = 0;

endmodule



