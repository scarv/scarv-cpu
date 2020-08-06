`include "defines.svh"
`include "rvfi_macros.vh"
`include "checkers_common.svh"

//
// module: insn_rotate_checker
//
//  Checker for the Bitmanip rotate instructions.
//
module insn_rotate_checker (
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

`define ROR32(X,Y) ((X>>Y) | (X << (32-Y)))
`define ROL32(X,Y) ((X<<Y) | (X >> (32-Y)))

wire dec_rol        = rvfi_valid && (rvfi_insn&32'hfe00707f) == 32'h60001033;
wire dec_ror        = rvfi_valid && (rvfi_insn&32'hfe00707f) == 32'h60005033;
wire dec_rori       = rvfi_valid && (rvfi_insn&32'hfc00707f) == 32'h60005013;

assign spec_valid   = 
    dec_rol    && check_en[0]  ||
    dec_ror    && check_en[1]  ||
    dec_rori   && check_en[2]  ;

wire [ 4:0] shamt = dec_rori ? rvfi_insn[24:20] : rvfi_rs2_rdata[4:0];

wire [31:0] result_rol     = `ROL32(rvfi_rs1_rdata, shamt);
wire [31:0] result_ror     = `ROR32(rvfi_rs1_rdata, shamt);
wire [31:0] result_rori    = `ROR32(rvfi_rs1_rdata, shamt);
                             

wire [31:0] result = 
    {32{dec_rol }} & result_rol   |
    {32{dec_ror }} & result_ror   |
    {32{dec_rori}} & result_rori  ;

// These instructions never trap.
assign spec_trap        = 1'b0   ;

assign spec_rs1_addr    = rvfi_insn[19:15];
assign spec_rs2_addr    = dec_rori ? 5'b0 : rvfi_insn[24:20];
assign spec_rd_addr     = rvfi_insn[11: 7];
assign spec_rd_wdata    = |spec_rd_addr ? result : 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 32'd4;
assign spec_mem_rmask   = 32'b0;
assign spec_mem_wmask   = 32'b0;
assign spec_mem_wdata   = 32'b0;

`undef ROR32
`undef ROL32

endmodule
