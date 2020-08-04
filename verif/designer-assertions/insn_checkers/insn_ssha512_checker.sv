
`include "defines.svh"
`include "rvfi_macros.vh"
`include "checkers_common.svh"

//
// module: insn_ssha512_checker
//
//  Checker for the scalar sha512 instructions.
//
module insn_ssha512_checker (
input                                 rvfi_valid,
input  [`RISCV_FORMAL_ILEN   - 1 : 0] rvfi_insn,
input  [`RISCV_FORMAL_XLEN   - 1 : 0] rvfi_pc_rdata,
input  [`RISCV_FORMAL_XLEN   - 1 : 0] rvfi_rs1_rdata,
input  [`RISCV_FORMAL_XLEN   - 1 : 0] rvfi_rs2_rdata,
input  [`RISCV_FORMAL_XLEN   - 1 : 0] rvfi_mem_rdata,
`ifdef RISCV_FORMAL_CSR_MISA
input  [`RISCV_FORMAL_XLEN   - 1 : 0] rvfi_csr_misa_rdata,
output [`RISCV_FORMAL_XLEN   - 1 : 0] spec_csr_misa_rmask,
`endif
output                                spec_valid,
output                                spec_trap,
output [                       4 : 0] spec_rs1_addr,
output [                       4 : 0] spec_rs2_addr,
output [                       4 : 0] spec_rd_addr,
output [`RISCV_FORMAL_XLEN   - 1 : 0] spec_rd_wdata,
output [`RISCV_FORMAL_XLEN   - 1 : 0] spec_pc_wdata,
output [`RISCV_FORMAL_XLEN   - 1 : 0] spec_mem_addr,
output [`RISCV_FORMAL_XLEN/8 - 1 : 0] spec_mem_rmask,
output [`RISCV_FORMAL_XLEN/8 - 1 : 0] spec_mem_wmask,
output [`RISCV_FORMAL_XLEN   - 1 : 0] spec_mem_wdata
);

//
// Macro is a 5-bit one-hot signal, which masks the individual instrucitons
// which are checked when the design is run through pre-proof synthesis.
// This is just an easy way to control the proof from symbiyosys without
// duplicating lots of files per instruction.
wire [5:0] check_en = `INSN_SSHA512_CHECKER_EN;

wire dec_ssha512_sig0l = rvfi_valid&&(rvfi_insn&32'hfe00707f) == 32'h1000702b;
wire dec_ssha512_sig0h = rvfi_valid&&(rvfi_insn&32'hfe00707f) == 32'h1200702b;
wire dec_ssha512_sig1l = rvfi_valid&&(rvfi_insn&32'hfe00707f) == 32'h1400702b;
wire dec_ssha512_sig1h = rvfi_valid&&(rvfi_insn&32'hfe00707f) == 32'h1600702b;
wire dec_ssha512_sum0r = rvfi_valid&&(rvfi_insn&32'hfe00707f) == 32'h1800702b;
wire dec_ssha512_sum1r = rvfi_valid&&(rvfi_insn&32'hfe00707f) == 32'h1a00702b;

assign spec_valid   = 
    dec_ssha512_sig0l && check_en[0] ||
    dec_ssha512_sig0h && check_en[1] ||
    dec_ssha512_sig1l && check_en[2] ||
    dec_ssha512_sig1h && check_en[3] ||
    dec_ssha512_sum0r && check_en[4] ||
    dec_ssha512_sum1r && check_en[5] ;

// These instructions never trap.
assign spec_trap        = 1'b0   ;

assign spec_rs1_addr    = rvfi_insn[19:15];
assign spec_rs2_addr    = rvfi_insn[24:20];
assign spec_rd_addr     = rvfi_insn[11: 7];
assign spec_rd_wdata    = |spec_rd_addr ? result : 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 32'd4;
assign spec_mem_rmask   = 32'b0;
assign spec_mem_wmask   = 32'b0;
assign spec_mem_wdata   = 32'b0;

wire [31:0] result_sig0l=
    (rvfi_rs1_rdata >>  1)^(rvfi_rs1_rdata >>  7)^(rvfi_rs1_rdata >>  8) ^
    (rvfi_rs2_rdata << 31)^(rvfi_rs2_rdata << 25)^(rvfi_rs2_rdata << 24) ;

wire [31:0] result_sig0h=
    (rvfi_rs1_rdata >>  1)^(rvfi_rs1_rdata >>  7)^(rvfi_rs1_rdata >>  8) ^
    (rvfi_rs2_rdata << 31)                       ^(rvfi_rs2_rdata << 24) ;

wire [31:0] result_sig1l=
    (rvfi_rs1_rdata >>  3)^(rvfi_rs1_rdata >>  6)^(rvfi_rs1_rdata >> 19) ^
    (rvfi_rs2_rdata << 29)^(rvfi_rs2_rdata << 26)^(rvfi_rs2_rdata << 13) ;

wire [31:0] result_sig1h=
    (rvfi_rs1_rdata >>  3)^(rvfi_rs1_rdata >>  6)^(rvfi_rs1_rdata >> 19) ^
    (rvfi_rs2_rdata << 29)                       ^(rvfi_rs2_rdata << 13) ;

wire [31:0] result_sum0r=
    (rvfi_rs1_rdata << 25)^(rvfi_rs1_rdata << 30)^(rvfi_rs1_rdata >> 28) ^
    (rvfi_rs2_rdata <<  7)^(rvfi_rs2_rdata <<  2)^(rvfi_rs2_rdata << 24) ;

wire [31:0] result_sum1r=
    (rvfi_rs1_rdata << 23)^(rvfi_rs1_rdata << 14)^(rvfi_rs1_rdata >> 18) ^
    (rvfi_rs2_rdata <<  9)^(rvfi_rs2_rdata << 18)^(rvfi_rs2_rdata << 14) ;

wire [31:0] result      =
    {32{dec_ssha512_sig0l}} & result_sig0l |
    {32{dec_ssha512_sig0h}} & result_sig0h |
    {32{dec_ssha512_sig1l}} & result_sig1l |
    {32{dec_ssha512_sig1h}} & result_sig1h |
    {32{dec_ssha512_sum0r}} & result_sum0r |
    {32{dec_ssha512_sum1r}} & result_sum1r ;

endmodule
