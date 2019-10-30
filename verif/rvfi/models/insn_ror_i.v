
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [ 4:0] shamt       = d_data[24:20];

wire [31:0] insn_result = 
    (`RS1 >> shamt) | (`RS1 << (32-shamt));

assign spec_valid       = rvfi_valid && dec_b_rori;
assign spec_trap        = 1'b0   ;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = 0;
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
