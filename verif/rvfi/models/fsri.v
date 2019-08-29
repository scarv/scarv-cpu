
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [ 5:0] shamt       = `FIELD_SHAMT5;
wire [63:0] ror_in      = {`RS1, `RS3};
wire [63:0] insn_result = (ror_in >> (   shamt)) |
                          (ror_in << (64-shamt)) ;

assign spec_valid       = rvfi_valid && dec_b_fsr;
assign spec_trap        = 1'b0   ;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = `FIELD_RS2_ADDR;
assign spec_rs3_addr    = 0;
assign spec_rd_addr     = `FIELD_RD_ADDR;
assign spec_rd_wdata    = spec_rd_addr ? insn_result[63:32] : {XLEN{1'b0}};
assign spec_rd_wide     = 1'b0;
assign spec_rd_wdatahi  = 32'b0
assign spec_pc_wdata    = rvfi_pc_rdata + 4;
assign spec_mem_addr    = 0;
assign spec_mem_rmask   = 0;
assign spec_mem_wmask   = 0;
assign spec_mem_wdata   = 0;

endmodule


