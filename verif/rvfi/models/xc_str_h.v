
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

wire [31:0] addr_byte = (`RS1 + (`RS2 << 1));
wire [31:0] addr_word = addr_byte & 32'hFFFF_FFFC;

wire                  spec_valid       = rvfi_valid && dec_xc_str_h;
wire                  spec_trap        = addr_byte[0];
wire [         4 : 0] spec_rs1_addr    = `FIELD_RS1_ADDR;
wire [         4 : 0] spec_rs2_addr    = `FIELD_RS2_ADDR;
wire [         4 : 0] spec_rs3_addr    = `FIELD_RS3_ADDR;
wire [         4 : 0] spec_rd_addr     = 0;
wire [XLEN   - 1 : 0] spec_rd_wdata    = 0;
wire [XLEN   - 1 : 0] spec_pc_wdata    = rvfi_pc_rdata + 4;
wire [XLEN   - 1 : 0] spec_mem_addr    = addr_word;
wire [XLEN/8 - 1 : 0] spec_mem_rmask   = 0;

wire [XLEN/8 - 1 : 0] spec_mem_wmask   = {
    {2{ addr_byte[1]}},
    {2{!addr_byte[1]}}
};

wire [XLEN   - 1 : 0] spec_mem_wdata   = `RS3[15:0] << (16*addr_byte[1]);

endmodule
