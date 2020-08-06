`include "defines.svh"
`include "rvfi_macros.vh"
`include "checkers_common.svh"

//
// module: insn_pack_checker
//
//  Checker for the Bitmanip pack[u|h] instructions.
//
module insn_pack_checker (
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
wire [2:0] check_en = `INSN_PACK_CHECKER_EN;

wire dec_pack       = rvfi_valid && (rvfi_insn&32'hfe00707f) == 32'h8004033;
wire dec_packu      = rvfi_valid && (rvfi_insn&32'hfe00707f) == 32'h48004033;
wire dec_packh      = rvfi_valid && (rvfi_insn&32'hfe00707f) == 32'h8007033;

assign spec_valid   = 
    dec_pack    && check_en[0]  ||
    dec_packu   && check_en[1]  ||
    dec_packh   && check_en[2]  ;

wire [31:0] result_pack     = {rvfi_rs2_rdata[15: 0], rvfi_rs1_rdata[15: 0]};
wire [31:0] result_packu    = {rvfi_rs2_rdata[31:16], rvfi_rs1_rdata[31:16]};
wire [31:0] result_packh    = {16'b0                ,
                               rvfi_rs2_rdata[ 7: 0], rvfi_rs1_rdata[ 7: 0]};

wire [31:0] result = 
    {32{dec_pack }} & result_pack   |
    {32{dec_packu}} & result_packu  |
    {32{dec_packh}} & result_packh  ;

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
