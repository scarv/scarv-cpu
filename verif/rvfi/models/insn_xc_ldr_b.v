
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [31:0] addr_byte = (`RS1 + (`RS2 ));
wire [31:0] addr_word = addr_byte & 32'hFFFF_FFFC;

wire b3 = addr_byte[1:0] == 2'b11;
wire b2 = addr_byte[1:0] == 2'b10;
wire b1 = addr_byte[1:0] == 2'b01;
wire b0 = addr_byte[1:0] == 2'b00;


wire wb_en = |spec_rd_addr && !spec_trap;

assign spec_valid       = rvfi_valid && dec_xc_ldr_b;
assign spec_trap        = 1'b0;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = `FIELD_RS2_ADDR;
assign spec_rs3_addr    = 0;
assign spec_rd_addr     = spec_trap    ? 0 : `FIELD_RD_ADDR;
assign spec_rd_wdata    =
    wb_en && b0 ? {{24{rvfi_mem_rdata[ 7]}},rvfi_mem_rdata[ 7: 0]} :
    wb_en && b1 ? {{24{rvfi_mem_rdata[15]}},rvfi_mem_rdata[15: 8]} :
    wb_en && b2 ? {{24{rvfi_mem_rdata[23]}},rvfi_mem_rdata[23:16]} :
    wb_en && b3 ? {{24{rvfi_mem_rdata[31]}},rvfi_mem_rdata[31:24]} :
                  {XLEN{1'b0}}                                     ;

assign spec_rd_wide     = 1'b0;
assign spec_rd_wdatahi  = 32'b0;

assign spec_pc_wdata    = rvfi_pc_rdata + 4;
assign spec_mem_addr    = addr_word;
assign spec_mem_rmask   = {
    b3,b2,b1,b0
};

assign spec_mem_wmask   = 0;
assign spec_mem_wdata   = 0;

endmodule
