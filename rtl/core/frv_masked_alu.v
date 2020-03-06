
//
// module: frv_masked_alu
//
//  Implements all of the masked ALU functionality.
//
module frv_masked_alu (

input  wire        g_clk            , // Global clock
input  wire        g_resetn         , // Synchronous, active low reset.

input  wire        valid            , // Inputs valid

input  wire        op_b2a           , // Binary to arithmetic mask covert
input  wire        op_a2b           , // Arithmetic to binary mask convert
input  wire        op_b_mask        , // Binary mask
input  wire        op_b_unmask      , // Binary unmask
input  wire        op_b_remask      , // Binary remask
input  wire        op_a_mask        , // Arithmetic mask
input  wire        op_a_unmask      , // Arithmetic unmask
input  wire        op_a_remask      , // Arithmetic remask
input  wire        op_b_not         , // Binary masked not
input  wire        op_b_and         , // Binary masked and
input  wire        op_b_ior         , // Binary masked or
input  wire        op_b_xor         , // Binary masked xor
input  wire        op_b_add         , // Binary masked addition
input  wire        op_b_sub         , // Binary masked subtraction

input  wire [XL:0] rs1_s0           , // RS1 Share 0
input  wire [XL:0] rs1_s1           , // RS1 Share 1
input  wire [XL:0] rs2_s0           , // RS2 Share 0
input  wire [XL:0] rs2_s1           , // RS2 Share 1

output wire        ready            , // Outputs ready
output wire [XL:0] rd_s0            , // Output share 0
output wire [XL:0] rd_s1              // Output share 1

);

// Common core parameters and constants
`include "frv_common.vh"

//
// Temporary constant mask
localparam MASK = 32'hABCD_0123;

//
// Binary Mask
// ------------------------------------------------------------
wire [XL:0] result_b_mask_s0    = MASK ^ rs1_s0;
wire [XL:0] result_b_mask_s1    = MASK         ;

//
// Binary Unmask
// ------------------------------------------------------------

//
// All of these keep attributes are needed to stop the synthesiser
// optimising them away. We *must* gate the inputs to the unmask operation,
// otherwise we will implicitly unmask the rs1 input each time.

(* keep *)
wire [XL:0] b_unmask_s0_gated   = rs1_s0 & {XLEN{op_b_unmask}};
(* keep *)
wire [XL:0] b_unmask_s1_gated   = rs1_s1 & {XLEN{op_b_unmask}};

(* keep *)
wire [XL:0] result_b_unmask_s0  = b_unmask_s0_gated ^ b_unmask_s1_gated;
(* keep *)


//
// Binary AND
// ------------------------------------------------------------

wire [XL:0] result_b_and_s1     = (rs1_s1 & rs2_s1) ^ (rs1_s1 | ~rs2_s0);
wire [XL:0] result_b_and_s0     = (rs1_s0 & rs2_s1) ^ (rs1_s0 | ~rs2_s0);

//
// Nieve result multiplexing.
// ------------------------------------------------------------

assign rd_s0 =
    {XLEN{op_b_mask     }} & result_b_mask_s0   |
    {XLEN{op_b_unmask   }} & result_b_unmask_s0 |
    {XLEN{op_b_and      }} & result_b_and_s0    ;

assign rd_s1 =
    {XLEN{op_b_mask     }} & result_b_mask_s1   |
    {XLEN{op_b_and      }} & result_b_and_s1    ;

//
// Randomly report readiness for now to check we can handle delays.
assign ready = ($random & 32'b11) == 32'b0 ? valid : 1'b0;

endmodule
