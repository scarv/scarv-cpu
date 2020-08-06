`include "defines.svh"
`include "rvfi_macros.vh"
`include "checkers_common.svh"

//
// module: insn_shfl_checker
//
//  Checker for the Bitmanip [un]shfl[i] instructions.
//
module insn_shfl_checker (
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
wire [3:0] check_en = `INSN_SHFL_CHECKER_EN;

wire dec_shfl       = rvfi_valid && (rvfi_insn& 32'hfe00707f) == 32'h8001033;
wire dec_unshfl     = rvfi_valid && (rvfi_insn& 32'hfe00707f) == 32'h8005033;
wire dec_shfli      = rvfi_valid && (rvfi_insn& 32'hfe00707f) == 32'h8001013;
wire dec_unshfli    = rvfi_valid && (rvfi_insn& 32'hfe00707f) == 32'h8005013;

wire unshfl         = dec_unshfl || dec_unshfli;

assign spec_valid   = 
    dec_shfl    && check_en[0] ||
    dec_unshfl  && check_en[1] ||
    dec_shfli   && check_en[2] ||
    dec_unshfli && check_en[3] ;

wire [ 3:0] shamt = dec_shfli || dec_unshfli ? rvfi_insn     [23:20] :
                                               rvfi_rs2_rdata[ 3: 0] ;

function [31:0] shuf_stage;
    input [31:0] src    ;
    input [31:0] maskL  ; 
    input [31:0] maskR  ;
    input integer N     ;
    reg   [31:0] x      ;
	x = src & ~(maskL | maskR);
	x = x | ((src <<  N) & maskL) | ((src >>  N) & maskR);
	shuf_stage = x;
endfunction

function [31:0] func_shfl;
    input [31:0] rs1    ;
    input [ 3:0] ctrl   ;
    reg   [31:0] x      ;

    x = rs1;

	if (ctrl & 8) x = shuf_stage(x, 32'h00ff0000, 32'h0000ff00, 8);
	if (ctrl & 4) x = shuf_stage(x, 32'h0f000f00, 32'h00f000f0, 4);
	if (ctrl & 2) x = shuf_stage(x, 32'h30303030, 32'h0c0c0c0c, 2);
	if (ctrl & 1) x = shuf_stage(x, 32'h44444444, 32'h22222222, 1);

    func_shfl = x  ;
endfunction

function [31:0] func_unshfl;
    input [31:0] rs1    ;
    input [ 3:0] ctrl   ;
    reg   [31:0] x      ;

    x = rs1;

	if (ctrl & 1) x = shuf_stage(x, 32'h44444444, 32'h22222222, 1);
	if (ctrl & 2) x = shuf_stage(x, 32'h30303030, 32'h0c0c0c0c, 2);
	if (ctrl & 4) x = shuf_stage(x, 32'h0f000f00, 32'h00f000f0, 4);
	if (ctrl & 8) x = shuf_stage(x, 32'h00ff0000, 32'h0000ff00, 8);

    func_unshfl = x  ;
endfunction


wire [31:0] result = unshfl ? func_unshfl(rvfi_rs1_rdata, shamt) :
                                func_shfl(rvfi_rs1_rdata, shamt) ;

// These instructions never trap.
assign spec_trap        = 1'b0   ;

assign spec_rs1_addr    = rvfi_insn[19:15];
assign spec_rs2_addr    = dec_shfli || dec_unshfli ? 5'b0 : rvfi_insn[24:20];
assign spec_rd_addr     = rvfi_insn[11: 7];
assign spec_rd_wdata    = |spec_rd_addr ? result : 32'b0;
assign spec_pc_wdata    = rvfi_pc_rdata + 32'd4;
assign spec_mem_rmask   = 32'b0;
assign spec_mem_wmask   = 32'b0;
assign spec_mem_wdata   = 32'b0;

`undef ROR32
`undef ROL32

endmodule
