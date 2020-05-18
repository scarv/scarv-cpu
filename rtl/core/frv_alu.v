
//
// module: frv_alu 
//
//  ALU for the execute stage.
//  - add/sub/bitwise/shift
//
module frv_alu (

input               g_clk           , // global clock
input               g_resetn        , // synchronous reset

input               alu_valid       , // Stall this stage
input               alu_flush       , // flush the stage
output              alu_ready       , // stage ready to progress

input        [PW:0] alu_pw          , // Pack width specifer.
input               alu_op_pack     , // Bitmanip pack
input               alu_op_add      , // 
input               alu_op_sub      , // 
input               alu_op_xor      , // 
input               alu_op_or       , // 
input               alu_op_and      , // 
input               alu_op_shf      , // 
input               alu_op_rot      , // 
input               alu_op_shf_left , // 
input               alu_op_shf_arith, // 
input               alu_op_cmp      , // 
input               alu_op_unsigned , //

output wire         alu_lt          , // Is LHS < RHS?
output wire         alu_eq          , // Is LHS = RHS?
output wire  [XL:0] alu_add_result  , // Result of adding lhs,rhs.

input        [XL:0] alu_lhs         , // left hand operand
input        [XL:0] alu_rhs         , // right hand operand
output wire  [XL:0] alu_result        // result of the ALU operation

);

// Common core parameters and constants
`include "frv_common.vh"

assign alu_ready    = alu_valid;

//
// Pack width recode
//

// Recode the pack width signal in one-hot terms the xcrypto-rtl modules will
// understand.
wire [4:0] pw_d = {
    alu_pw == PW_2 ,
    alu_pw == PW_4 ,
    alu_pw == PW_8 ,
    alu_pw == PW_16,
    alu_pw == PW_32
};

//
// Adder
//


wire [XL:0] adder_result  ;

// Packed 2's complement adder/subtractor
p_addsub i_p_addsub (
.lhs    (alu_lhs        ), // Left hand input
.rhs    (alu_rhs        ), // Right hand input.
.pw     (pw_d           ), // Pack width to operate on
.sub    (alu_op_sub     ), // Subtract if set, else add.
.cin    (1'b0           ), // Carry in. Forced to 1 internally if `sub` set.
.c_en   (1'b1           ), // Global carry enable
.c_out  (               ), // Carry bits
.result (adder_result   )  // Result of the operation
);

assign alu_add_result       = adder_result[XL:0];

// TODO: Re-use subtraction operation results.
wire   alu_lt_signed        = $signed(alu_lhs) < $signed(alu_rhs);

wire   alu_lt_unsigned      = $unsigned(alu_lhs) < $unsigned(alu_rhs);

assign alu_lt               = alu_op_unsigned ? alu_lt_unsigned :
                                                alu_lt_signed   ;

assign alu_eq               = alu_lhs == alu_rhs;

//
// Shifter
//

wire [31:0] shift_out;
wire [ 4:0] shamt    = alu_rhs[4:0];

p_shfrot i_p_shfrot (
.crs1  (alu_lhs         ), // Source register 1
.shamt (shamt           ), // Shift amount (immediate or source register 2)
.pw    (pw_d            ), // Pack width to operate on
.shift (alu_op_shf      ), // Shift left/right
.rotate(alu_op_rot      ), // Rotate left/right
.left  ( alu_op_shf_left), // Shift/roate left
.right (!alu_op_shf_left), // Shift/rotate right
.result(shift_out       )  // Operation result
);

wire        shift_arith       = alu_op_shf_arith && alu_lhs[XL];
wire [XL:0] shift_arith_mask  = shift_arith ? ~(32'hFFFF_FFFF >> shamt) : 0;

wire [XL:0] shift_result      = shift_out | shift_arith_mask;

//
// Bitwise
//

wire [  XL:0] bw_lhs        = alu_lhs;
wire [  XL:0] bw_rhs        = alu_rhs;
wire [  XL:0] bw_result     = {XLEN{alu_op_xor}} & (bw_lhs ^ bw_rhs) |
                              {XLEN{alu_op_or }} & (bw_lhs | bw_rhs) |
                              {XLEN{alu_op_and}} & (bw_lhs & bw_rhs) ;

//
// Bitmanip pack
//

wire [XL:0] pack_result =  {alu_rhs[15:0], alu_lhs[15:0]};

//
// Result multiplexing
//

wire out_adder  = (alu_op_add || alu_op_sub) && !alu_op_cmp;
wire out_shift  = alu_op_shf || alu_op_rot ;
wire out_bw     = alu_op_xor || alu_op_or || alu_op_and;
wire out_cmp    = alu_op_cmp ;

assign alu_result = 
    out_adder ? adder_result[XL:0] :
    {XLEN{out_shift   }} & shift_result[XL:0]    |
    {XLEN{out_bw      }} & bw_result             | 
    {XLEN{out_cmp     }} & {31'b0, alu_lt}       |
    {XLEN{alu_op_pack }} & pack_result           ; 

endmodule

