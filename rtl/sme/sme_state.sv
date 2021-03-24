
import sme_pkg::*;

`define SL(IDX) XLEN*IDX+:XLEN

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

input               bank_read   , // Used for storing share to memory.
output [      XL:0] bank_rdata  , // Read data from bank[smectrl.t][smectl.b]

input  [      XL:0] csr_smectl  , // Current SMECTL value.

input   sme_data_t  input_data  , // Input oeprands.

input               alu_valid   , // Accept new input instruction.
output              alu_ready   , // Ready for new input instruction.
input   sme_alu_t   alu_op      , // Input instruction details.

input               cry_valid   , // Accept new input instruction.
output              cry_ready   , // Ready for new input instruction.
input   sme_cry_t   cry_op      , // Input instruction details.

output [      XL:0] alu_result  , // ALU    0'th share result.
output [      XL:0] cry_result    // Crypto 0'th share result.

);

//
// Misc useful signals / parameters
// ------------------------------------------------------------

localparam RMAX  = SMAX+SMAX*(SMAX-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;
localparam RW    = RMAX*XLEN-1;

localparam SM   = SMAX-1;
localparam SW   = SMAX*XLEN-1;

logic [SM:0] rf_clk_req;
logic        alu_clk_req;

assign rf_clk_req[0] = 1'b0;

// TODO: proper clock requests.
assign g_clk_req = |rf_clk_req || alu_clk_req || rng_clk_req || 1'b1;

//
// smectl CSR register
// ------------------------------------------------------------

wire [3:0] smectl_d = csr_smectl[ 8:5]; // Number of masks currently in use.
wire       smectl_t = csr_smectl[   4]; // Current type of masking being used.
wire [3:0] smectl_b = csr_smectl[ 3:0]; // Current bank select for load/store.

//
// Random Number Source
// ------------------------------------------------------------

wire [RW:0] rng      ;  // RNG outputs.

wire        rng_update = 1'b1;
wire        rng_clk_req;

sme_rng #(
.XLEN(XLEN),
.SMAX(SMAX) 
) i_rng (
.g_clk      (g_clk      ),
.g_clk_req  (rng_clk_req),
.g_resetn   (g_resetn   ), // Sychronous active low reset.
.update     (rng_update ), // Update the internal RNG.
.rng        (rng        )  // RNG outputs.
);

//
// Share storage.
// ------------------------------------------------------------

// Storage for the set of shares representing rs1/rs2/rd. I.e. the
// inputs and outputs of the register files.
logic [SW:0] s1_rs1;
logic [SW:0] s1_rs2;

logic [SW:0] s1_alu_rs1;
logic [SW:0] s1_alu_rs2;

logic [SW:0] s1_cry_rs1;
logic [SW:0] s1_cry_rs2;

// Zeroth share comes from GPRs.
assign       s1_rs1[`SL(0)] = input_data.rs1_rdata;
assign       s1_rs2[`SL(0)] = input_data.rs2_rdata;

genvar i;
generate for(i=0; i < SMAX; i = i+1) begin
    assign s1_alu_rs1[`SL(i)] = {XLEN{alu_valid}} & s1_rs1[`SL(i)];
    assign s1_alu_rs2[`SL(i)] = {XLEN{alu_valid}} & s1_rs2[`SL(i)];

    assign s1_cry_rs1[`SL(i)] = {XLEN{cry_valid}} & s1_rs1[`SL(i)];
    assign s1_cry_rs2[`SL(i)] = {XLEN{cry_valid}} & s1_rs2[`SL(i)];
end endgenerate

//
// ALU Instance
// ------------------------------------------------------------

logic [SW:0] alu_rd;

wire alu_rd_wen     = alu_valid && alu_ready && !alu_op.op_unmask;

assign alu_result   = alu_rd[`SL(0)];

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
.rng                (rng                ), // Randomness
.bank_rdata         (bank_rdata         ),
.valid              (alu_valid          ),
.ready              (alu_ready          ),
.shamt              (input_data.shamt   ), // Shift amount for shift/rotate.
.op_xor             (alu_op.op_xor      ),
.op_and             (alu_op.op_and      ),
.op_or              (alu_op.op_or       ),
.op_notrs2          (alu_op.op_notrs2   ), // invert 0'th share of rs2.
.op_shift           (alu_op.op_shift    ),
.op_rotate          (alu_op.op_rotate   ),
.op_left            (alu_op.op_left     ),
.op_right           (alu_op.op_right    ),
.op_add             (alu_op.op_add      ),
.op_sub             (alu_op.op_sub      ),
.op_mask            (alu_op.op_mask     ), // Enmask 0'th element of rs1
.op_unmask          (alu_op.op_unmask   ), // Unmask rs1
.op_remask          (alu_op.op_remask   ), // remask rs1 based on smectl_t
.rs1                (s1_rs1             ), // RS1 as SMAX shares
.rs2                (s1_rs2             ), // RS2 as SMAX shares
.rd                 (alu_rd             )  // RD as SMAX shares
);


//
// Crypto Instance
// ------------------------------------------------------------

logic [SW:0] cry_rd;

wire cry_rd_wen     = cry_valid && cry_ready;

assign cry_result   = cry_rd[`SL(0)];

sme_crypto #(
.XLEN(32    ),
.SMAX(SMAX  )
) i_sme_crypto (
.g_clk          (g_clk              ), // Global clock
.g_clk_req      (g_clk_req          ), // Global clock request
.g_resetn       (g_resetn           ), // Sychronous active low reset.
.smectl_d       (smectl_d           ), // Current number of shares to use.
.rng            (rng                ), // RNG outputs.
.flush          (flush              ), // Flush operation, discard results.
.valid          (cry_valid          ),
.ready          (cry_ready          ),
.op_aeses       (cry_op.op_aeses    ),
.op_aesesm      (cry_op.op_aesesm   ),
.op_aesds       (cry_op.op_aesds    ),
.op_aesdsm      (cry_op.op_aesdsm   ),
.bs             (cry_op.bs          ), // AES byte select.
.rs1            (s1_rs1             ), // RS1 as SMAX shares
.rs2            (s1_rs2             ), // RS2 as SMAX shares
.rd             (cry_rd             )  // RD as SMAX shares
);

//
// Register File Instances
// ------------------------------------------------------------

localparam BI = $clog2(SMAX)-1;

wire bank_read_en = bank_read || (alu_op.op_unmask && alu_valid);
wire [XL:0] bank_rdata_sel[SM:0];
genvar bs;
generate for(bs=0; bs<SMAX;bs=bs+1) begin
    assign bank_rdata_sel[bs] =
        {XLEN{(bank_read_en) && smectl_b[BI:0] == bs}} & s1_rs2[`SL(bs)];
end endgenerate

assign bank_rdata = bank_rdata_sel[smectl_b[BI:0]];

wire   [3:0] bank_rs1_addr = input_data.rs1_addr;
wire   [3:0] bank_rs2_addr = input_data.rs2_addr;

wire [SW:0] result_wdata    ;
assign      result_wdata    = alu_rd_wen ? alu_rd : cry_rd;

//
// Note that the 0'th register file is the normal RISC-V GPRS, so we
// need to instance SMAX-1 sme_regfile modules

genvar rf_i;
generate for(rf_i = 1; rf_i < SMAX; rf_i = rf_i + 1) begin: gen_regfile

// Write to regfile from bank load/store interface?
wire bank_write         = bank_wen  && smectl_b == rf_i;

// Write enable for _this_ registerfile.
wire        rf_wen      = cry_rd_wen || alu_rd_wen || bank_write;
wire [ 3:0] rf_addr     = bank_wen  ? bank_waddr : input_data.rd_addr;
wire [XL:0] rf_wdata    = bank_wen  ? bank_wdata : result_wdata[`SL(rf_i)];

sme_regfile i_rf (
.g_clk      (g_clk              ), // Global clock
.g_clk_req  (rf_clk_req[rf_i]   ), // Global clock request
.g_resetn   (g_resetn           ), // Sychronous active low reset.
.rs1_addr   (bank_rs1_addr      ), // Source register 1 address
.rs1_rdata  (s1_rs1[`SL(rf_i)]  ), // Source register 1 read data
.rs2_addr   (bank_rs2_addr      ), // Source register 2 address
.rs2_rdata  (s1_rs2[`SL(rf_i)]  ), // Source register 2 read data
.rd_wen     (rf_wen             ), // Write enable
.rd_addr    (rf_addr            ), // Write address
.rd_wdata   (rf_wdata           )  // Write data
);

end endgenerate

endmodule

`undef SL

