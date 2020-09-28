
`define XCFI_NO_RD_CHECKS=1

`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [XL:0] u_rs1   = `XCFI_UNMASK_A(`RS1, `RS1_HI);
wire [XL:0] u_result= `XCFI_UNMASK_A(`RD , `RD_HI );

`XCFI_SPEC_CHECK_BEGIN

    assume(`FIELD_RD_ADDR != 0);

    assert(u_rs1 == u_result);

`XCFI_SPEC_CHECK_END

assign spec_valid       = rvfi_valid && dec_mask_a_remask;
assign spec_trap        = 1'b0   ;
assign spec_rs1_addr    = `FIELD_RS1_ADDR & 5'h1E;
assign spec_rs2_addr    = 0;
assign spec_rs3_addr    = 0;
assign spec_rd_addr     = `FIELD_RD_ADDR;
assign spec_rd_wdata    = 0;
assign spec_rd_wide     = 1'b1;
assign spec_rd_wdatahi  = 0;
assign spec_pc_wdata    = rvfi_pc_rdata + 4;
assign spec_mem_addr    = 0;
assign spec_mem_rmask   = 0;
assign spec_mem_wmask   = 0;
assign spec_mem_wdata   = 0;

endmodule
