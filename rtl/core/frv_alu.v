
//
// module: frv_alu 
//
//  ALU for the execute stage.
//  - add/sub/bitwise/shift
//
module frv_alu (

input  wire [   XL:0]   opr_a   , // Input operand A
input  wire [   XL:0]   opr_b   , // Input operand B
input  wire [    4:0]   shamt   , // Shift amount.

input  wire             op_add  , // Select output of adder
input  wire             op_sub  , // Subtract opr_a from opr_b else add
input  wire             op_xor  , // Select XOR operation result
input  wire             op_or   , // Select OR
input  wire             op_and  , //        AND
input  wire             op_slt  , // Set less than
input  wire             op_sltu , //                Unsigned
input  wire             op_srl  , // Shift right logical
input  wire             op_sll  , // Shift left logical
input  wire             op_sra  , // Shift right arithmetic

output wire [   XL:0]   add_out , // Result of adding opr_a and opr_b
output wire             cmp_eq  , // Result of opr_a == opr_b
output wire             cmp_lt  , // Result of opr_a <  opr_b
output wire             cmp_ltu , // Result of opr_a <  opr_b

output wire [   XL:0]   result    // Operation result

);

// Common core parameters and constants
`include "frv_common.vh"

//
// Miscellaneous
// ------------------------------------------------------------

assign cmp_eq               = opr_a == opr_b;

//
// Add / Sub
// ------------------------------------------------------------

wire [XL:0] addsub_rhs      = op_sub ? ~opr_b : opr_b               ;

wire [XL:0] addsub_result   = opr_a + addsub_rhs + {{XL{1'b0}},op_sub};
assign      add_out         = addsub_result                         ;

//
// SLT / SLTU
// TODO: Re-use addsub for SLT comparison.
// ------------------------------------------------------------

wire        slt_signed      = $signed(opr_a) < $signed(opr_b);

wire        slt_unsigned    = $unsigned(opr_a) < $unsigned(opr_b);

wire        slt_lsbu        = slt_unsigned ;

wire        slt_lsb         = slt_signed   ;

assign      cmp_ltu         = slt_lsbu;
assign      cmp_lt          = slt_lsb;

wire [XL:0] slt_result      = {{XL{1'b0}}, op_slt ? slt_lsb : slt_lsbu};

//
// Bitwise Operations
// ------------------------------------------------------------

wire [XL:0] xor_output      = opr_a ^ opr_b;
wire [XL:0]  or_output      = opr_a | opr_b;
wire [XL:0] and_output      = opr_a & opr_b;

wire [XL:0] bitwise_result  = {XLEN{op_xor}} & xor_output |
                              {XLEN{op_or }} &  or_output |
                              {XLEN{op_and}} & and_output ;

//
// Shifts
// ------------------------------------------------------------

wire [XL:0] shift_in_r  = opr_a;
wire [XL:0] shift_in_l  ;

wire [XL:0] shift_in    = op_sll ? shift_in_l : shift_in_r;

wire [XL:0] shift_out_r = shift_in    >> shamt          ;
wire [XL:0] shift_out_l ;

wire        shift_abit  = opr_a[XL];
wire [XL:0] shift_amask = shift_abit ? ~({XLEN{1'b1}} >> shamt):
                                         {XLEN{1'b0}}          ;

genvar i;
generate for(i = 0; i < XLEN; i = i + 1) begin
    assign shift_in_l [i] = shift_in_r [XL-i];
    assign shift_out_l[i] = shift_out_r[XL-i];
end endgenerate

wire [XL:0] shift_sra   = shift_out_r | shift_amask;

wire [XL:0] shift_result=
    {XLEN{op_sll}} &  shift_out_l        |
    {XLEN{op_srl}} &  shift_out_r        |
    {XLEN{op_sra}} &  shift_sra          ;


//
// Result multiplexing
// ------------------------------------------------------------

wire sel_addsub = op_add || op_sub  ;
wire sel_slt    = op_slt || op_sltu ;
wire sel_shift  = op_sll || op_sra  || op_srl;

assign result =
                         bitwise_result             |
    {XLEN{sel_addsub}} & addsub_result              |
    {XLEN{sel_slt   }} & slt_result                 |
    {XLEN{sel_shift }} & shift_result               ;

endmodule

