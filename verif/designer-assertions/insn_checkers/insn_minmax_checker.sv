`include "defines.svh"
`include "rvfi_macros.vh"
`include "checkers_common.svh"

//
// module: insn_minmax_checker
//
//  Checker for the Bitmanip minmax instructions.
//
module insn_minmax_checker (
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
// Macro is a 4-bit one-hot signal, which masks the individual instrucitons
// which are checked when the design is run through pre-proof synthesis.
// This is just an easy way to control the proof from symbiyosys without
// duplicating lots of files per instruction.
wire [3:0] check_en = `INSN_MINMAX_CHECKER_EN;

wire dec_max        = rvfi_valid && (rvfi_insn & 32'hfe00707f) == 32'ha005033;
wire dec_maxu       = rvfi_valid && (rvfi_insn & 32'hfe00707f) == 32'ha007033;
wire dec_min        = rvfi_valid && (rvfi_insn & 32'hfe00707f) == 32'ha004033;
wire dec_minu       = rvfi_valid && (rvfi_insn & 32'hfe00707f) == 32'ha006033;

assign spec_valid   = 
    dec_max    && check_en[0]  ||
    dec_maxu   && check_en[1]  ||
    dec_min    && check_en[2]  ||
    dec_minu   && check_en[3]  ;

wire [31:0] rs1 = rvfi_rs1_rdata;
wire [31:0] rs2 = rvfi_rs2_rdata;

wire [63:0] result_min  = $signed  (rs1) < $signed  (rs2) ? rs1 : rs2;
wire [63:0] result_max  = $signed  (rs1) > $signed  (rs2) ? rs1 : rs2;
wire [63:0] result_minu = $unsigned(rs1) < $unsigned(rs2) ? rs1 : rs2;
wire [63:0] result_maxu = $unsigned(rs1) > $unsigned(rs2) ? rs1 : rs2;

wire [31:0] result = 
    {32{dec_max }} & result_max  |
    {32{dec_maxu}} & result_maxu |
    {32{dec_min }} & result_min  |
    {32{dec_minu}} & result_minu ;

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

endmodule
