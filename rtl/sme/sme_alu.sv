
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
//  - mask / re-mask / unmask
//
module sme_alu #(
parameter XLEN            = 32  ,
parameter SMAX            =  4    // Max number of hardware shares supported.
)(

input         g_clk     , // Global clock
input         g_clk_req , // Global clock request
input         g_resetn  , // Sychronous active low reset.

input         smectl_t  , // Masking type. 0=bool, 1=arithmetic
input  [ 3:0] smectl_d  , // Current number of shares to use.

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
input  [XL:0] rs1 [SM:0], // RS1 as SMAX shares
input  [XL:0] rs2 [SM:0], // RS2 as SMAX shares
        
output [XL:0] rd  [SM:0]  // RD as SMAX shares

);

//
// Misc useful signals / parameters
// ------------------------------------------------------------

localparam SM   = SMAX-1;
localparam XL   = XLEN-1;

wire        new_instr       = valid && ready;

wire        op_addsub_arith =(op_add      || op_sub   ) &&  smectl_t;
wire        op_addsub_bool  =(op_add      || op_sub   ) && !smectl_t;

wire        op_mask_arith   = op_mask                   &&  smectl_t;
wire        op_mask_bool    = op_mask                   && !smectl_t;

wire        op_remask_arith = op_remask                 &&  smectl_t;
wire        op_remask_bool  = op_remask                 && !smectl_t;

wire        op_unmask_arith = op_unmask                 &&  smectl_t;
wire        op_unmask_bool  = op_unmask                 && !smectl_t;

wire        op_shfrot       = op_shift    || op_rotate;

wire        and_clk_req;

//
// Randomness sources
// ============================================================

wire [XL:0] rng [SM:0];
wire [SM:0] rng_taps = {SMAX{1'b0}};

genvar prng;
generate for(prng=0; prng<SMAX; prng = prng+1) begin: g_prngs

    sme_lfsr32 #(
        .RESET_VALUE(32'h3456_789A<<prng | 32'h3456_789A>>prng)
    ) i_lfsr32 (
        .g_clk    (g_clk            ), // Clock to update PRNG
        .g_resetn (g_resetn         ), // Syncrhonous active low reset.
        .update   (1'b1             ), // Update PRNG with new value.
        .extra_tap(rng_taps[prng]   ), // Additional seed bit, from TRNG.
        .prng     (rng[prng]        )  // Current PRNG value.
    );

end endgenerate // g_prngs

//
// Simple linear operations
// ============================================================

wire logic_and_not;

logic [XL:0] bitwise_rs2        [SM:0];
logic [XL:0] result_xor         [SM:0];
logic [XL:0] result_shift       [SM:0];
logic [XL:0] result_and         [SM:0];
logic [XL:0] result_or          [SM:0];

logic [XL:0] result_aaddsub     [SM:0]; // Arithmetic add sub.

//
// Instance DOM AND
sme_dom_and #(
.D(SMAX),   // Number of shares
.N(XLEN)    // Bit-width of the operation.
) i_dom_and (
.g_clk      (g_clk      ), // Global clock
.g_clk_req  (and_clk_req), // Global clock request
.g_resetn   (g_resetn   ), // Sychronous active low reset.
.rng        (rng        ), // Extra randomness.
.rs1        (rs1        ), // RS1 as SMAX shares
.rs2        (rs2        ), // RS2 as SMAX shares
.rd         (result_and )  // RD as SMAX shares
);

genvar l;
generate for(l = 0; l < SMAX; l = l+1) begin : g_linear_ops // BEGIN GENERATE

//
// Bitwise or/xor/nor/xnor
// ------------------------------------------------------------

//
// Bitwise Linear operations - implement logic-and-not instructions by
// inverting the 0th share iff it's that kind of instruction.
if(l == 0) assign bitwise_rs2[l] = op_notrs2 ? ~rs2[l] : rs2[l];
else       assign bitwise_rs2[l] =                       rs2[l];

//
// OR - not dom and. Just invert the 0'th share.
if(l == 0) assign result_or[l] = ~result_and[l];
else       assign result_or[l] =  result_and[l];


//
// XOR - each share xor'd individually
assign result_xor[l] = rs1[l] ^ (op_mask_bool ? rng[l] : bitwise_rs2[l]);

//
// Shift and rotate
// ------------------------------------------------------------

//
// Shift and rotate based linear operations. Thing to shift/rotate in
// rs1. Shamt in dedicated signal.
wire  [2*XLEN-1:0] shift_input = {
    {op_rotate ? rs1[l] : {XLEN{1'b0}} },
    {            rs1[l]                }
};

// Reverse bits if shifting left.
wire  [2*XLEN-1:0] shift_value = op_left ? shift_input : {<<{shift_input}};

// Always shift right.
wire  [2*XLEN-1:0] shift_output= shift_value >> shamt;

// (un)reverse bits if shifting left.
wire  [2*XLEN-1:0] shift_result= op_left ? shift_output : {<<{shift_output}};
assign result_shift[l] = shift_result[XL:0];

//
// Add / subtract (arithmetic)
// ------------------------------------------------------------

wire        add_rhs_rng   = op_mask_arith || op_remask_arith;

wire [XL:0] arith_add_lhs =                    rs1[l] ;
wire [XL:0] arith_add_rhs = op_sub          ? ~rs2[l] :
                            add_rhs_rng     ?  rng[l] :
                                               rs2[l] ;

wire [XL:0] arith_add_cin = {{XL{1'b0}}, op_sub};

wire [XL:0] arith_add_out = arith_add_lhs + arith_add_rhs + arith_add_cin;
assign      result_aaddsub[l] = arith_add_out;

//
// Result multiplexing
// ------------------------------------------------------------

wire sel_result_xor = op_xor || op_mask_bool;
wire sel_result_add = op_addsub_arith || op_mask_arith || op_remask_arith;

assign rd[l]= 
    op_and              ? result_and[l]         :
    op_or               ? result_or [l]         :
    sel_result_xor      ? result_xor[l]         :
    sel_result_add      ? result_aaddsub[l]     :
    op_shfrot           ? result_shift[l]       :
                          {XLEN{1'b0}}          ;
    
end endgenerate // g_linear_ops -------------------------------- END GENERATE

assign ready = valid;

endmodule

