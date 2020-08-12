`include "defines.svh"
`include "rvfi_macros.vh"
`include "checkers_common.svh"

//
// module: insn_shiftones_checker
//
//  Checker for the Bitmanip shiftones instructions.
//
module insn_shiftones_checker (
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
wire [3:0] check_en = `INSN_SHONES_CHECKER_EN;

wire dec_slo        = rvfi_valid && (rvfi_insn & 32'hfe00707f) == 32'h20001033;
wire dec_sloi       = rvfi_valid && (rvfi_insn & 32'hfc00707f) == 32'h20001013;
wire dec_sro        = rvfi_valid && (rvfi_insn & 32'hfe00707f) == 32'h20005033;
wire dec_sroi       = rvfi_valid && (rvfi_insn & 32'hfc00707f) == 32'h20005013;

assign spec_valid   = 
    dec_slo    && check_en[0]  ||
    dec_sloi   && check_en[1]  ||
    dec_sro    && check_en[2]  ||
    dec_sroi   && check_en[3]  ;

wire [ 4:0] shamt = dec_sloi || dec_sroi ? rvfi_insn[24:20]     :
                                           rvfi_rs2_rdata[4:0]  ;

wire [63:0] result_slo  = {rvfi_rs1_rdata,32'hFFFF_FFFF } << shamt;
wire [63:0] result_sloi = {rvfi_rs1_rdata,32'hFFFF_FFFF } << shamt;
wire [63:0] result_sro  = {32'hFFFF_FFFF ,rvfi_rs1_rdata} >> shamt;
wire [63:0] result_sroi = {32'hFFFF_FFFF ,rvfi_rs1_rdata} >> shamt;
                             

wire [31:0] result = 
    {32{dec_slo }} & result_slo [63:32] |
    {32{dec_sloi}} & result_sloi[63:32] |
    {32{dec_sro }} & result_sro [31: 0] |
    {32{dec_sroi}} & result_sroi[31: 0] ;

// These instructions never trap.
assign spec_trap        = 1'b0   ;

assign spec_rs1_addr    = rvfi_insn[19:15];
assign spec_rs2_addr    = dec_sloi || dec_sroi ? 5'b0 : rvfi_insn[24:20];
assign spec_rd_addr     = rvfi_insn[11: 7];
assign spec_rd_wdata    = |spec_rd_addr ? result : 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 32'd4;
assign spec_mem_rmask   = 32'b0;
assign spec_mem_wmask   = 32'b0;
assign spec_mem_wdata   = 32'b0;

endmodule
