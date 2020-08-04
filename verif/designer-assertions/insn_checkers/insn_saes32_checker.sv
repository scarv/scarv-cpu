`include "defines.svh"
`include "rvfi_macros.vh"

//
// module: insn_saes32_checker
//
//  Checker for the scalar aes32 instructions.
//
module insn_saes32_checker (
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
wire [3:0] check_en = `INSN_SAES32_CHECKER_EN;

wire op_saes32_encsm= rvfi_valid && (rvfi_insn & 32'h3e00707f) == 32'h000202b;
wire op_saes32_encs = rvfi_valid && (rvfi_insn & 32'h3e00707f) == 32'h200202b;
wire op_saes32_decsm= rvfi_valid && (rvfi_insn & 32'h3e00707f) == 32'h400202b;
wire op_saes32_decs = rvfi_valid && (rvfi_insn & 32'h3e00707f) == 32'h600202b;

wire [1:0] op_bs        = rvfi_insn[31:30];

assign spec_valid       = 
    op_saes32_encsm && check_en[0] || 
    op_saes32_encs  && check_en[1] ||
    op_saes32_decsm && check_en[2] || 
    op_saes32_decs  && check_en[3] ;

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


insn_saes32_model i_model (
.valid   (rvfi_valid        ), // Are the inputs valid? Used for logic gating.
.op_encs (op_saes32_encs    ), // Encrypt SubBytes
.op_encsm(op_saes32_encsm   ), // Encrypt SubBytes + MixColumn
.op_decs (op_saes32_decs    ), // Decrypt SubBytes
.op_decsm(op_saes32_decsm   ), // Decrypt SubBytes + MixColumn
.rs1     (rvfi_rs1_rdata    ), // Source register 1
.rs2     (rvfi_rs2_rdata    ), // Source register 2
.bs      (op_bs             ), // Byte select immediate
.rd      (model_rd_wdata    )  // output destination register value.
);


endmodule
