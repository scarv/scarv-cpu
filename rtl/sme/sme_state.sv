
import sme_pkg::*;

//
// module: sme_state
//
//  Contains the register files for the SME share storage.
//
module sme_state #(
parameter SMAX            = 4   , // Max number of hardware shares supported.
parameter LINEAR_FUS      = 4   , // How many linear ops to instance?
parameter NONLINEAR_WIDTH = XLEN  // How wide is the nonlinear op data path?
)(
input               g_clk       , // Global clock
output wire         g_clk_req   , // Global clock request
input               g_resetn    , // Sychronous active low reset.

input  wire         flush       , // Flush in progress instructions.

input               bank_wen    , // Write loaded data to bank.
input  [       3:0] bank_waddr  , // Register of the bank to write.
input  [      XL:0] bank_wdata  , // Write data being loaded into bank.

output [      XL:0] bank_rdata  , // Read data from bank[smectrl.t][smectl.b]

input  [      XL:0] csr_smectl  , // Current SMECTL value.

input               instr_valid , // Accept new input instruction.
output              instr_ready , // Ready for new input instruction.
input   sme_instr_t instr_in    , // Input instruction details.

output              result_valid, // Output result to host core ready.
input               result_ready, // Host core ready for results.
output sme_result_t result_out    // The result of the instruction.

);

//
// Misc useful signals / parameters
// ------------------------------------------------------------

localparam SM   = SMAX-1;

logic [SM:0] rf_clk_req;
logic        alu_clk_req;

assign rf_clk_req[0] = 1'b0;

// TODO: proper clock requests.
assign g_clk_req = |rf_clk_req || alu_clk_req || 1'b1;

//
// smectl CSR register
// ------------------------------------------------------------

wire [3:0] smectl_d = csr_smectl[ 8:5]; // Number of masks currently in use.
wire       smectl_t = csr_smectl[   4]; // Current type of masking being used.
wire [3:0] smectl_b = csr_smectl[ 3:0]; // Current bank select for load/store.

//
// Share storage.
// ------------------------------------------------------------

// Storage for the set of shares representing rs1/rs2/rd. I.e. the
// inputs and outputs of the register files.
logic [XL:0] s1_rs1 [SM:0];
logic [XL:0] s1_rs2 [SM:0];
logic [XL:0] alu_rd [SM:0];

// Zeroth share comes from GPRs.
assign       s1_rs1[0] = instr_in.rs1_rdata;
assign       s1_rs2[0] = instr_in.rs2_rdata;

//
// ALU Instance
// ------------------------------------------------------------

wire alu_rd_wen = instr_valid && instr_ready;

sme_alu #(
.XLEN (32   ),
.SMAX (SMAX ) // Max number of hardware shares supported.
) i_sme_alu (
.g_clk              (g_clk              ), // Global clock
.g_clk_req          (alu_clk_req        ), // Global clock request
.g_resetn           (g_resetn           ), // Sychronous active low reset.
.smectl_t           (smectl_t           ), // Masking type 0=bool, 1=arithmetic
.smectl_d           (smectl_d           ), // Current number of shares to use.
.flush              (flush              ), // Flush current operation
.valid              (instr_valid        ),
.ready              (instr_ready        ),
.shamt              (instr_in.shamt     ), // Shift amount for shift/rotate.
.op_xor             (instr_in.op_xor    ),
.op_and             (instr_in.op_and    ),
.op_or              (instr_in.op_or     ),
.op_notrs2          (instr_in.op_notrs2 ), // invert 0'th share of rs2.
.op_shift           (instr_in.op_shift  ),
.op_rotate          (instr_in.op_rotate ),
.op_left            (instr_in.op_left   ),
.op_right           (instr_in.op_right  ),
.op_add             (instr_in.op_add    ),
.op_sub             (instr_in.op_sub    ),
.op_mask            (instr_in.op_mask   ), // Enmask 0'th element of rs1
.op_unmask          (instr_in.op_unmask ), // Unmask rs1
.op_remask          (instr_in.op_remask ), // remask rs1 based on smectl_t
.rs1                (s1_rs1             ), // RS1 as SMAX shares
.rs2                (s1_rs2             ), // RS2 as SMAX shares
.rd                 (alu_rd             )  // RD as SMAX shares
);

//
// Register File Instances
// ------------------------------------------------------------

localparam BI = $clog2(SMAX)-1;

assign bank_rdata = s1_rs2[smectl_b[BI:0]]; // TODO: Leakage hazard.

wire   [3:0] bank_rs1_addr = instr_in.rs1_addr;
wire   [3:0] bank_rs2_addr = instr_in.rs2_addr;

//
// Note that the 0'th register file is the normal RISC-V GPRS, so we
// need to instance SMAX-1 sme_regfile modules

genvar rf_i;
generate for(rf_i = 1; rf_i < SMAX; rf_i = rf_i + 1) begin: gen_regfile

// Write to regfile from bank load/store interface?
wire bank_write         = bank_wen  && smectl_b == rf_i;

// Write enable for _this_ registerfile.
wire        rf_wen      = alu_rd_wen || bank_write;
wire [ 3:0] rf_addr     = bank_wen  ? bank_waddr : instr_in.rd_addr;
wire [XL:0] rf_wdata    = bank_wen  ? bank_wdata : alu_rd[rf_i];

sme_regfile i_rf (
.g_clk      (g_clk              ), // Global clock
.g_clk_req  (rf_clk_req[rf_i]   ), // Global clock request
.g_resetn   (g_resetn           ), // Sychronous active low reset.
.rs1_addr   (bank_rs1_addr      ), // Source register 1 address
.rs1_rdata  (s1_rs1[rf_i]       ), // Source register 1 read data
.rs2_addr   (bank_rs2_addr      ), // Source register 2 address
.rs2_rdata  (s1_rs2[rf_i]       ), // Source register 2 read data
.rd_wen     (rf_wen             ), // Write enable
.rd_addr    (rf_addr            ), // Write address
.rd_wdata   (rf_wdata           )  // Write data
);

end endgenerate

endmodule

