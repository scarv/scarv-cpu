
`define SL(IDX) XLEN*IDX+:XLEN

//
// module: sme_crypto
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
module sme_crypto #(
parameter XLEN            = 32  ,
parameter SMAX            =  3    // Max number of hardware shares supported.
)(

input         g_clk     , // Global clock
input         g_clk_req , // Global clock request
input         g_resetn  , // Sychronous active low reset.

input  [ 3:0] smectl_d  , // Current number of shares to use.
input  [RW:0] rng       , // RNG outputs.

input         flush     , // Flush current operation, discard results.

input         valid     ,
output        ready     ,
input         op_aeses  ,
input         op_aesesm ,
input         op_aesds  ,
input         op_aesdsm ,

input  [ 1:0] bs        , // AES byte select.
input  [SW:0] rs1       , // RS1 as SMAX shares
input  [SW:0] rs2       , // RS2 as SMAX shares
        
output [SW:0] rd          // RD as SMAX shares

);

//
// Misc useful signals / parameters
// ------------------------------------------------------------

localparam AND_GATES = 34;

localparam RMAX  = SMAX*(SMAX-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;
localparam RW    = AND_GATES*RMAX-1;

localparam SM   = SMAX-1;
localparam XL   = XLEN-1;
localparam SW   = SMAX*XLEN-1;

wire        new_instr       = valid && ready;

assign      ready = valid && aes_any && aes_ready;

//
// Multiply by 2 in GF(2^8) modulo 8'h1b
function [7:0] xtime2;
    input [7:0] a;

    xtime2  = {a[6:0],1'b0} ^ (a[7] ? 8'h1b : 8'b0 );

endfunction

//
// Paired down multiply by X in GF(2^8)
function [7:0] xtimeN;
    input[7:0] a;
    input[3:0] b;

    xtimeN = 
        (b[0] ?                         a   : 0) ^
        (b[1] ? xtime2(                 a)  : 0) ^
        (b[2] ? xtime2(xtime2(          a)) : 0) ^
        (b[3] ? xtime2(xtime2(xtime2(   a))): 0) ;

endfunction

//
// AES Instructions
// ------------------------------------------------------------

logic[1:0] aes_ctr;
wire [1:0] n_aes_ctr= aes_ctr  + 1;
wire       aes_ready= aes_ctr == 3;

wire       aes_any  = valid && (
    op_aeses || op_aesesm || op_aesds || op_aesdsm );

wire       aes_dec  = op_aesds || op_aesdsm ;
wire       aes_mix  = op_aesesm|| op_aesdsm ;

wire [SMAX*8-1:0] aes_sbox_in ;
wire [SMAX*8-1:0] aes_sbox_out;

wire [SW:0] aes_result;

assign rd = aes_result;

wire   aes_flush = new_instr;

genvar a;
generate for(a=0; a < SMAX; a=a+1) begin : g_aes

    wire [XL:0] rs2_a = rs2[`SL(a)];

    assign aes_sbox_in[a*8+:8] =
        bs == 2'd0 ? rs2_a[ 7: 0]  :
        bs == 2'd1 ? rs2_a[15: 8]  :
        bs == 2'd2 ? rs2_a[23:16]  :
      /*bs == 2'd3*/ rs2_a[31:24]  ;


    wire [7:0] aes_sbox_out_a = aes_sbox_out[a*8+:8];

    wire [7:0] mix_b3 =           xtimeN(aes_sbox_out_a, aes_dec ? 11 : 3)   ;
    wire [7:0] mix_b2 = aes_dec ? xtimeN(aes_sbox_out_a, 13) : aes_sbox_out_a;
    wire [7:0] mix_b1 = aes_dec ? xtimeN(aes_sbox_out_a,  9) : aes_sbox_out_a;
    wire [7:0] mix_b0 =           xtimeN(aes_sbox_out_a, aes_dec ? 14 : 2)   ;

    wire [31:0] result_mix  = {mix_b3, mix_b2, mix_b1, mix_b0};

    wire [31:0] result      = aes_mix ? result_mix : {24'b0, aes_sbox_out_a};

    wire [31:0] rotated     =
        bs == 2'd0 ? {result                      } :
        bs == 2'd1 ? {result[23:0], result[31:24] } :
        bs == 2'd2 ? {result[15:0], result[31:16] } :
     /* bs == 2'd3*/ {result[ 7:0], result[31: 8] } ;

    assign aes_result[`SL(a)] = rotated ^ rs1[`SL(a)];

end endgenerate

always @(posedge g_clk) begin
    if(!g_resetn || flush || new_instr) begin
        aes_ctr <= 2'b0;
    end else if(aes_any && !aes_ready) begin
        aes_ctr <= n_aes_ctr;
    end
end

sme_sbox_aes #(
.SMAX(SMAX)
) i_sbox (
.g_clk   (g_clk         ), // Global clock
.g_resetn(g_resetn      ), // Sychronous active low reset.
.en      (aes_any       ), // Operation enable.
.flush   (aes_flush     ), // Flush SBox state bits.
.dec     (aes_dec       ), // Decrypt
.rng     (rng           ), // Random bits
.sbox_in (aes_sbox_in   ), // SMAX share input
.sbox_out(aes_sbox_out  )  // SMAX share output
);

endmodule

`undef SL

