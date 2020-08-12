`include "defines.svh"
`include "rvfi_macros.vh"
`include "checkers_common.svh"

//
// module: insn_gorc_checker
//
//  Checker for the Bitmanip gorc instructions.
//
module insn_gorc_checker (
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
wire [1:0] check_en = `INSN_GORC_CHECKER_EN;

wire dec_gorc       = rvfi_valid && (rvfi_insn & 32'hfe00707f) == 32'h28005033;
wire dec_gorci      = rvfi_valid && (rvfi_insn & 32'hfc00707f) == 32'h28005013;

assign spec_valid   = 
    dec_gorc   && check_en[0]  ||
    dec_gorc   && check_en[1]  ;

wire [ 4:0] shamt = dec_gorci ? rvfi_insn[24:20] : rvfi_rs2_rdata[4:0];

function [31:0] gorc;
  input [31:0] rs1    ;
  input [ 4:0] ctrl   ;
  reg   [31:0] x      ;

  x = rs1;

  if (ctrl &  1) x = x | ((x& 32'h55555555) <<  1) | ((x& 32'hAAAAAAAA) >>  1);
  if (ctrl &  2) x = x | ((x& 32'h33333333) <<  2) | ((x& 32'hCCCCCCCC) >>  2);
  if (ctrl &  4) x = x | ((x& 32'h0F0F0F0F) <<  4) | ((x& 32'hF0F0F0F0) >>  4);
  if (ctrl &  8) x = x | ((x& 32'h00FF00FF) <<  8) | ((x& 32'hFF00FF00) >>  8);
  if (ctrl & 16) x = x | ((x& 32'h0000FFFF) << 16) | ((x& 32'hFFFF0000) >> 16);

  gorc = x  ;
endfunction

wire [31:0] result = gorc(rvfi_rs1_rdata, shamt);

// These instructions never trap.
assign spec_trap        = 1'b0   ;

assign spec_rs1_addr    = rvfi_insn[19:15];
assign spec_rs2_addr    = dec_gorci ? 5'b0 : rvfi_insn[24:20];
assign spec_rd_addr     = rvfi_insn[11: 7];
assign spec_rd_wdata    = |spec_rd_addr ? result : 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 32'd4;
assign spec_mem_rmask   = 32'b0;
assign spec_mem_wmask   = 32'b0;
assign spec_mem_wdata   = 32'b0;

`undef ROR32
`undef ROL32

endmodule
