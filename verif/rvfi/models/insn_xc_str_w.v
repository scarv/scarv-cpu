
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [31:0] addr_byte = (`RS1 + (`RS2 << 2));
wire [31:0] addr_word = addr_byte & 32'hFFFF_FFFC;

assign spec_valid       = rvfi_valid && dec_xc_str_w;
assign spec_trap        = |addr_byte[1:0];
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = `FIELD_RS2_ADDR;
assign spec_rs3_addr    = `FIELD_RS3_ADDR;
assign spec_rd_addr     = 0;
assign spec_rd_wdata    = 0;
assign spec_rd_wide     = 1'b0;
assign spec_rd_wdatahi  = 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 4;
assign spec_mem_addr    = addr_word;
assign spec_mem_rmask   = 0;
assign spec_mem_wmask   = 4'b1111;
assign spec_mem_wdata   = `RS3;

endmodule
