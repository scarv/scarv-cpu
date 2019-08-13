
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [31:0] addr_byte = (`RS1 + (`RS2 << 1));
wire [31:0] addr_word = addr_byte & 32'hFFFF_FFFC;

wire wb_en = |spec_rd_addr && !spec_trap;

wire                  spec_valid       = rvfi_valid && dec_xc_ldr_hu;
wire                  spec_trap        = |addr_byte[0];
wire [         4 : 0] spec_rs1_addr    = `FIELD_RS1_ADDR;
wire [         4 : 0] spec_rs2_addr    = `FIELD_RS2_ADDR;
wire [         4 : 0] spec_rs3_addr    = 0;
wire [         4 : 0] spec_rd_addr     = spec_trap    ? 0 : `FIELD_RD_ADDR;
wire [XLEN   - 1 : 0] spec_rd_wdata    =
    wb_en && !addr_byte[1] ? {16'b0,rvfi_mem_rdata[15: 0]} :
    wb_en &&  addr_byte[1] ? {16'b0,rvfi_mem_rdata[31:16]} :
                             {XLEN{1'b0}}                  ;

wire [XLEN   - 1 : 0] spec_pc_wdata    = rvfi_pc_rdata + 4;
wire [XLEN   - 1 : 0] spec_mem_addr    = addr_word;
wire [XLEN/8 - 1 : 0] spec_mem_rmask   = {
    {2{ addr_byte[1]}},
    {2{!addr_byte[1]}}
};

wire [XLEN/8 - 1 : 0] spec_mem_wmask   = 0;
wire [XLEN   - 1 : 0] spec_mem_wdata   = 0;

endmodule
