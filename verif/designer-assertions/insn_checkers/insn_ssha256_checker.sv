
`include "defines.svh"
`include "rvfi_macros.vh"
`include "checkers_common.svh"

//
// module: insn_ssha256_checker
//
//  Checker for the scalar sm4 instructions.
//
module insn_ssha256_checker (
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
// Macro is a 2-bit one-hot signal, which masks the individual instrucitons
// which are checked when the design is run through pre-proof synthesis.
// This is just an easy way to control the proof from symbiyosys without
// duplicating lots of files per instruction.
wire [3:0] check_en = `INSN_SSHA256_CHECKER_EN;

wire dec_ssha256_sig0 = rvfi_valid && (rvfi_insn&32'hfff0707f) == 32'he00702b;
wire dec_ssha256_sig1 = rvfi_valid && (rvfi_insn&32'hfff0707f) == 32'he10702b;
wire dec_ssha256_sum0 = rvfi_valid && (rvfi_insn&32'hfff0707f) == 32'he20702b;
wire dec_ssha256_sum1 = rvfi_valid && (rvfi_insn&32'hfff0707f) == 32'he30702b;

assign spec_valid   = 
    dec_ssha256_sig0 && check_en[0] ||
    dec_ssha256_sig1 && check_en[1] ||
    dec_ssha256_sum0 && check_en[2] ||
    dec_ssha256_sum1 && check_en[3] ;

// These instructions never trap.
assign spec_trap        = 1'b0   ;

assign spec_rs1_addr    = rvfi_insn[19:15];
assign spec_rs2_addr    = 5'b0            ;
assign spec_rd_addr     = rvfi_insn[11: 7];
assign spec_rd_wdata    = |spec_rd_addr ? result : 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 32'd4;
assign spec_mem_rmask   = 32'b0;
assign spec_mem_wmask   = 32'b0;
assign spec_mem_wdata   = 32'b0;

wire [31:0] result_sig0 = `ROR32(rvfi_rs1_rdata, 5'h07) ^
                          `ROR32(rvfi_rs1_rdata, 5'h12) ^
                                (rvfi_rs1_rdata>>5'h03) ;

wire [31:0] result_sig1 = `ROR32(rvfi_rs1_rdata, 5'h11) ^
                          `ROR32(rvfi_rs1_rdata, 5'h13) ^
                                (rvfi_rs1_rdata>>5'h0A) ;

wire [31:0] result_sum0 = `ROR32(rvfi_rs1_rdata, 5'h02) ^
                          `ROR32(rvfi_rs1_rdata, 5'h0D) ^
                          `ROR32(rvfi_rs1_rdata, 5'h16) ;

wire [31:0] result_sum1 = `ROR32(rvfi_rs1_rdata, 5'h06) ^
                          `ROR32(rvfi_rs1_rdata, 5'h0B) ^
                          `ROR32(rvfi_rs1_rdata, 5'h19) ;

wire [31:0] result      =
    {32{dec_ssha256_sig0}} & result_sig0 |
    {32{dec_ssha256_sig1}} & result_sig1 |
    {32{dec_ssha256_sum0}} & result_sum0 |
    {32{dec_ssha256_sum1}} & result_sum1 ;

endmodule
