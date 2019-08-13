
`include "xcfi_macros.sv"

module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);

`XCFI_INSN_CHECK_COMMON

`define ROR32(a,b) ((a >> b) | (a << 32-b))

wire [31:0] insn_result = (`ROR32(`RS1, 2)) ^
                          (`ROR32(`RS1,13)) ^
                          (`ROR32(`RS1,22)) ;

wire                  spec_valid       = rvfi_valid && dec_xc_sha256_s2;
wire                  spec_trap        = 1'b0;
wire [         4 : 0] spec_rs1_addr    = `FIELD_RS1_ADDR;
wire [         4 : 0] spec_rs2_addr    = `FIELD_RS2_ADDR;
wire [         4 : 0] spec_rs3_addr    = `FIELD_RS3_ADDR;
wire [         4 : 0] spec_rd_addr     = `FIELD_RD_ADDR;
wire [XLEN   - 1 : 0] spec_rd_wdata    = |spec_rd_addr ? insn_result : 0;
wire [XLEN   - 1 : 0] spec_pc_wdata    = rvfi_pc_rdata + 4;
wire [XLEN   - 1 : 0] spec_mem_addr    = 0;
wire [XLEN/8 - 1 : 0] spec_mem_rmask   = 0;

wire [XLEN/8 - 1 : 0] spec_mem_wmask   = 0;
wire [XLEN   - 1 : 0] spec_mem_wdata   = 0;

endmodule

