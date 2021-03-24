

`define SL(IDX) XLEN*IDX+:XLEN

//
// module: sme_alu
//
//  Implements the core arithmetic and logical operations for SME.
//  - Add (arithmetic/boolean)
//  - Sub (arithmetic/boolean)
//  - XOR
//  - AND
//  - OR 
//  - XNOR
//  - ANDN
//  - ORN
//  - Shift left/right
//  - Rotate right
//  - Rotate left
//  - CLMUL?
//  - MUL?
//  - mask / re-mask
//
module sme_alu #(
parameter XLEN            = 32  ,
parameter SMAX            =  4    // Max number of hardware shares supported.
)(

input         g_clk     , // Global clock
output        g_clk_req , // Global clock request
input         g_resetn  , // Sychronous active low reset.

input         smectl_t  , // Masking type. 0=bool, 1=arithmetic
input  [ 3:0] smectl_d  , // Current number of shares to use.
input  [RW:0] rng       , // RNG outputs.

input  [XL:0] bank_rdata, // Used for un-masking one share at a time.

input         flush     , // Flush current operation, discard results.

input         valid     ,
output        ready     ,
input  [ 4:0] shamt     , // Shift amount for shift/rotate.
input         op_xor    ,
input         op_and    ,
input         op_or     ,
input         op_notrs2 , // invert 0'th share of rs2 for andn/orn/xnor.
input         op_shift  ,
input         op_rotate ,
input         op_left   ,
input         op_right  ,
input         op_add    ,
input         op_sub    ,
input         op_mask   , // Enmask 0'th element of rs1 based on smectl_t
input         op_unmask , // Unmask rs1
input         op_remask , // remask rs1 based on smectl_t
input  [SW:0] rs1       , // RS1 as SMAX shares
input  [SW:0] rs2       , // RS2 as SMAX shares
        
output [SW:0] rd          // RD as SMAX shares

);

//
// Misc useful signals / parameters
// ------------------------------------------------------------

localparam RMAX  = SMAX+SMAX*(SMAX-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;
localparam RW    = RMAX*XLEN-1;

localparam SM   = SMAX-1;
localparam XL   = XLEN-1;
localparam SW   = SMAX*XLEN-1;

wire        new_instr       = valid && ready;

wire        op_addsub       = op_add      || op_sub   ;

wire        op_mask_bool    = op_mask                 ;

wire        op_remask_bool  = op_remask               ;

wire        op_unmask_bool  = op_unmask               ;

wire        op_shfrot       = op_shift    || op_rotate;

wire        and_clk_req;
wire        add_clk_req;

assign      g_clk_req       = 1'b1;

logic [SW:0] bitwise_rs1    ;
logic [SW:0] bitwise_rs2    ;
logic [SW:0] result_xor     ;
logic [SW:0] result_shift   ;
logic [SW:0] result_and     ;
logic [SW:0] result_add     ;
logic [SW:0] result_or      ;
logic [SW:0] result_baddsub ; // Binary masked add sub.
logic [SW:0] result_mask    ;
logic [SW:0] result_remask  ;


//
// 32-bit KS masked Adder
// ============================================================

wire    adder_valid = op_addsub && valid;
wire    adder_ready;

sme_ks_adder #(
.D(SMAX), // Number of shares.
.N(  32)  // Width of the operation.
) i_ks_adder (
.g_clk       (g_clk       ), // Global clock
.g_resetn    (g_resetn    ), // Sychronous active low reset. 
.en          (adder_valid ), // Operation Enable.
.sub         (op_sub      ), // Subtract when =1, add when =0.
.s_rng       (rng         ), // Extra randomness.
.s_mxor      (result_xor  ), // RS1 as SMAX shares
.s_mand      (result_and  ), // RS2 as SMAX shares
.s_rd        (result_add  ), // RD as SMAX shares
.rdy         (adder_ready ) 
);

//
// Helper logic for en-masking
// ============================================================

logic [XL:0] all_rng; // Stores XOR of all 1..SMAX prng outputs for en-mask.

// For doing en-mask.
always_comb begin : collapse_rng
    integer i;
    all_rng = 0;
    for (i = 1; i < SMAX; i = i+1) begin
        all_rng = all_rng ^ rng[i*XLEN+:XLEN];
    end
end


//
// Non-linear operations
// ============================================================

wire dom_and_en = (valid && (op_and || op_or))  ||
                   adder_valid                  ;

//
// Instance DOM AND
sme_dom_and #(
.D(SMAX),   // Number of shares
.N(XLEN)    // Bit-width of the operation.
) i_dom_and (
.g_clk      (g_clk      ), // Global clock
.g_resetn   (g_resetn   ), // Sychronous active low reset.
.en         (dom_and_en ), // Enable.
.rng        (rng        ), // Extra randomness.
.rs1        (bitwise_rs1), // RS1 as SMAX shares
.rs2        (bitwise_rs2), // RS2 as SMAX shares
.rd         (result_and )  // RD as SMAX shares
);

//
// Un-masking
// ------------------------------------------------------------

logic       unmask_en  ;
always @(negedge g_clk) unmask_en <= op_unmask_bool && valid;

wire  [XL:0] mask_to_remove = {XLEN{unmask_en}} & bank_rdata;
wire  [XL:0] result_unmask  = rs1[0*XLEN+:XLEN] ^ mask_to_remove;


//
// Simple linear operations
// ============================================================

genvar l;
generate for(l = 0; l < SMAX; l = l+1) begin : g_linear_ops // BEGIN GENERATE

//
// Masking / Remasking
// ------------------------------------------------------------

assign result_mask  [`SL(l)] = 
    l==0    ? rs1[`SL(0)] ^ all_rng :
              rng[`SL(l)]           ;

assign result_remask[`SL(l)] =
    l < SMAX-1 || SMAX%2==0 ? rs1[`SL(l)] ^ rng[`SL(0)] :
                              rs1[`SL(l)]               ;


//
// Bitwise or/xor/nor/xnor
// ------------------------------------------------------------

wire inv_rs1 = op_or             ;
wire inv_rs2 = op_or ^  op_notrs2;

//
// Bitwise Linear operations - implement logic-and-not instructions by
// inverting the 0th share iff it's that kind of instruction.
if(l == 0) assign bitwise_rs1[`SL(l)] = inv_rs1 ? ~rs1[`SL(l)] : rs1[`SL(l)];
else       assign bitwise_rs1[`SL(l)] =                          rs1[`SL(l)];

if(l == 0) assign bitwise_rs2[`SL(l)] = inv_rs2 ? ~rs2[`SL(l)] : rs2[`SL(l)];
else       assign bitwise_rs2[`SL(l)] =                          rs2[`SL(l)];

//
// OR - not dom and. Just invert the 0'th share.
if(l == 0) assign result_or[`SL(l)] = ~result_and[`SL(l)];
else       assign result_or[`SL(l)] =  result_and[`SL(l)];


//
// XOR - each share xor'd individually
assign result_xor[`SL(l)] = rs1[`SL(l)] ^ bitwise_rs2[`SL(l)];

//
// Shift and rotate
// ------------------------------------------------------------

//
// Shift and rotate based linear operations. Thing to shift/rotate in
// rs1. Shamt in dedicated signal.
wire  [2*XLEN-1:0] shift_input = {
    {op_rotate ? rs1[`SL(l)] : {XLEN{1'b0}} },
    {            rs1[`SL(l)]                }
};

wire [2*XLEN-1:0] shift_in_rev;
wire [2*XLEN-1:0] shift_out_rev;

// Reverse bits iff shifting right.
wire  [2*XLEN-1:0] shift_value = op_right ? shift_input  : shift_in_rev;

// Always shift right.
wire  [2*XLEN-1:0] shift_output= shift_value >> shamt;

// (un)reverse bits if shifting left.
wire  [2*XLEN-1:0] shift_result= op_right ? shift_output : shift_out_rev;

genvar i;
for(i = 0; i<2*XLEN; i=i+1) begin
    assign shift_in_rev [i] = shift_input  [2*XLEN-1-i];
    assign shift_out_rev[i] = shift_output [2*XLEN-1-i];
end 

assign result_shift[`SL(l)]         = 
    op_right || !op_rotate ? shift_result[      XL: 0] :
                             shift_result[2*XLEN-1:32] ;

//
// Add / subtract (arithmetic)
// ------------------------------------------------------------

wire [XL:0] bmask_add_lhs =                    rs1[`SL(l)] ;
wire [XL:0] bmask_add_rhs = op_sub          ? ~rs2[`SL(l)] :
                                               rs2[`SL(l)] ;

wire [XL:0] bmask_add_cin = {{XL{1'b0}}, op_sub};

wire [XL:0] bmask_add_out = bmask_add_lhs + bmask_add_rhs + bmask_add_cin;
assign      result_baddsub[`SL(l)] = bmask_add_out;

//
// Result multiplexing
// ------------------------------------------------------------

wire sel_result_add = op_addsub;

assign rd[`SL(l)]= 
    op_remask_bool      ? result_remask[`SL(l)]     :
    op_unmask_bool&&l==0? result_unmask             :
    op_mask             ? result_mask[`SL(l)]       :
    op_and              ? result_and[`SL(l)]        :
    op_or               ? result_or [`SL(l)]        :
    op_addsub           ? result_add[`SL(l)]        :
    op_xor              ? result_xor[`SL(l)]        :
    sel_result_add      ? result_baddsub[`SL(l)]    :
    op_shfrot           ? result_shift[`SL(l)]      :
                          {XLEN{1'b0}}              ;

end endgenerate // g_linear_ops -------------------------------- END GENERATE

// Is the ALU finished with the current (possibly multi-cycle) operation?
assign ready = op_addsub ? (adder_valid && adder_ready) : valid;

endmodule

`undef SL

