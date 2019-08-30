
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

localparam BOP_LUT_SEL  = 31;

wire [ 7:0] uxcrypto_b0 = rvfi_aux[ 7:0];
wire [ 7:0] uxcrypto_b1 = rvfi_aux[15:8];

wire [ 7:0] lut         = rvfi_insn[BOP_LUT_SEL] ? uxcrypto_b1 : uxcrypto_b0;

wire [31:0] insn_result ;

genvar i;
generate for(i = 0; i < 32; i = i + 1) begin

    wire [2:0] lut_in = {`RS3[i], `RS2[i], `RS1[i]};

    assign     insn_result[i] = lut[lut_in];

end endgenerate

assign spec_valid       = rvfi_valid && dec_xc_bop;
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


