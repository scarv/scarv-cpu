
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
output sme_result_t result_out   // The result of the instruction.

);

//
// Misc useful signals / parameters
// ------------------------------------------------------------

localparam SM   = SMAX-1;

logic [SM:0] rf_clk_req;
assign rf_clk_req[0] = 1'b0;

// TODO: proper clock requests.
assign g_clk_req = |rf_clk_req || 1'b1;

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
logic [XL:0] s4_rd  [SM:0];

// Zeroth share comes from GPRs.
assign       s1_rs1[0] = instr_in.rs1_rdata;
assign       s1_rs2[0] = instr_in.rs2_rdata;

wire         s4_rd_wen  ;
wire  [ 3:0] s4_rd_addr ;

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
wire        rf_wen      = s4_rd_wen || bank_write;
wire [ 3:0] rf_addr     = bank_wen  ? bank_waddr : s4_rd_addr ;
wire [XL:0] rf_wdata    = bank_wen  ? bank_wdata : s4_rd[rf_i];

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

