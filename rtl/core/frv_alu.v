
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

input               alu_op_add      , // 
input               alu_op_sub      , // 
input               alu_op_xor      , // 
input               alu_op_or       , // 
input               alu_op_and      , // 
input               alu_op_shf      , // 
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
// Adder
//

wire [  XL:0] adder_lhs     = alu_lhs    ;
wire [  XL:0] adder_rhs     = alu_op_sub ? ~alu_rhs : alu_rhs;
wire [  XL:0] adder_ci      = {{XL{1'b0}},alu_op_sub};

wire [XLEN:0] adder_result  = adder_lhs + adder_rhs + adder_ci;

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

wire            shift_arith   = alu_op_shf_arith && alu_lhs[XL];
wire [2*XLEN-1:0] shift_lhs     = {{XLEN{shift_arith}} , alu_lhs} ;
wire [     4:0] shift_rhs     = alu_rhs[4:0]  ;

wire [2*XLEN-1:0] shift_result  = alu_op_shf_left ? shift_lhs << shift_rhs :
                                                  shift_lhs >> shift_rhs ;

//
// Bitwise
//

wire [  XL:0] bw_lhs        = alu_lhs;
wire [  XL:0] bw_rhs        = alu_rhs;
wire [  XL:0] bw_result     = {XLEN{alu_op_xor}} & (bw_lhs ^ bw_rhs) |
                              {XLEN{alu_op_or }} & (bw_lhs | bw_rhs) |
                              {XLEN{alu_op_and}} & (bw_lhs & bw_rhs) ;

//
// Result multiplexing
//

wire out_adder  = (alu_op_add || alu_op_sub) && !alu_op_cmp;
wire out_shift  = alu_op_shf ;
wire out_bw     = alu_op_xor || alu_op_or || alu_op_and;
wire out_cmp    = alu_op_cmp ;

assign alu_result = 
    out_adder ? adder_result[XL:0] :
    {XLEN{out_shift}} & shift_result[XL:0]    |
    {XLEN{out_bw   }} & bw_result             | 
    {XLEN{out_cmp  }} & {31'b0, alu_lt}       ; 

endmodule

