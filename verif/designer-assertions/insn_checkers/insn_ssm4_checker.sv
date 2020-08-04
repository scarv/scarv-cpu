`include "defines.svh"
`include "rvfi_macros.vh"

//
// module: insn_ssm4_checker
//
//  Checker for the scalar sm4 instructions.
//
module insn_ssm4_checker (
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
wire [1:0] check_en = `INSN_SSM4_CHECKER_EN;

wire dec_ssm4_ed    = rvfi_valid && (rvfi_insn & 32'h3e00707f) == 32'h800302b;
wire dec_ssm4_ks    = rvfi_valid && (rvfi_insn & 32'h3e00707f) == 32'ha00302b;

wire [1:0] op_bs    = rvfi_insn[31:30];

assign spec_valid   = 
    dec_ssm4_ed && check_en[0] || 
    dec_ssm4_ks && check_en[1] ;

// These instructions never trap.
assign spec_trap        = 1'b0   ;

wire [31:0] model_rd_wdata;

assign spec_rs1_addr    = rvfi_insn[19:15];
assign spec_rs2_addr    = rvfi_insn[24:20];
assign spec_rd_addr     = rvfi_insn[11: 7];
assign spec_rd_wdata    = |spec_rd_addr ? model_rd_wdata : 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 32'd4;
assign spec_mem_rmask   = 32'b0;
assign spec_mem_wmask   = 32'b0;
assign spec_mem_wdata   = 32'b0;


insn_ssm4_model i_model (
.op_ssm4_ed (dec_ssm4_ed       ), // Encrypt SubBytes
.op_ssm4_ks (dec_ssm4_ks       ), // Encrypt SubBytes + MixColumn
.rs1        (rvfi_rs1_rdata    ), // Source register 1
.rs2        (rvfi_rs2_rdata    ), // Source register 2
.bs         (op_bs             ), // Byte select immediate
.result     (model_rd_wdata    )  // output destination register value.
);


endmodule
