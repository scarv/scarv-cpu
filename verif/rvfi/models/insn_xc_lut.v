
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);
`XCFI_INSN_CHECK_COMMON

wire [63:0] concat = {`RS1, `RS2};

wire [31:0] insn_result;

wire [ 3:0] lut[15:0];

genvar i;
generate for (i = 0; i < 16; i = i + 1) begin
    assign lut[i] = concat[4*i+3:4*i];
end endgenerate

genvar j;
generate for (j = 0; j < 8; j = j + 1) begin
    wire [3:0] lin = `RS3[4*j+3:4*j];
    assign insn_result[4*j+3:4*j] = lut[lin];
end endgenerate

assign spec_valid       = rvfi_valid && dec_xc_lut;
assign spec_trap        = 1'b0   ;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = `FIELD_RS2_ADDR;
assign spec_rs3_addr    = `FIELD_RS3_ADDR;
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

