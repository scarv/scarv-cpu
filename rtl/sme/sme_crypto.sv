
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
input  [XL:0] rng[RM:0] , // RNG outputs.

input         flush     , // Flush current operation, discard results.

input         valid     ,
output        ready     ,
input         op_aeses  ,
input         op_aesesm ,
input         op_aesds  ,
input         op_aesdsm ,

input  [ 1:0] bs        , // AES byte select.
input  [XL:0] rs1 [SM:0], // RS1 as SMAX shares
input  [XL:0] rs2 [SM:0], // RS2 as SMAX shares
        
output [XL:0] rd  [SM:0]  // RD as SMAX shares

);

//
// Misc useful signals / parameters
// ------------------------------------------------------------

localparam RMAX  = SMAX+SMAX*(SMAX-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;

localparam SM   = SMAX-1;
localparam XL   = XLEN-1;

wire        new_instr       = valid && ready;

assign      ready = valid && aes_any && aes_ready;

`define DBG(W,VAR) wire[W:0] dbg_``VAR = VAR[0]^VAR[1]^VAR[2]^VAR[3];

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

wire [7:0] aes_sbox_in  [SM:0];
wire [7:0] aes_sbox_out [SM:0];

`DBG(31,rs1)
`DBG(31,rs2)
`DBG(7,aes_sbox_in)
`DBG(7,aes_sbox_out)
`DBG(31,aes_result)

wire [XL:0] aes_result[SM:0];

assign rd = aes_result;

genvar a;
generate for(a=0; a < SMAX; a=a+1) begin : g_aes

    assign aes_sbox_in[a] = bs == 2'd0 ? rs2[a][ 7: 0]  :
                            bs == 2'd1 ? rs2[a][15: 8]  :
                            bs == 2'd2 ? rs2[a][23:16]  :
                          /*bs == 2'd3*/ rs2[a][31:24]  ;

    wire [7:0] mix_b3 =           xtimeN(aes_sbox_out[a], aes_dec ? 11 : 3)  ;
    wire [7:0] mix_b2 = aes_dec ? xtimeN(aes_sbox_out[a], 13) : aes_sbox_out[a];
    wire [7:0] mix_b1 = aes_dec ? xtimeN(aes_sbox_out[a],  9) : aes_sbox_out[a];
    wire [7:0] mix_b0 =           xtimeN(aes_sbox_out[a], aes_dec ? 14 : 2)  ;

    wire [31:0] result_mix  = {mix_b3, mix_b2, mix_b1, mix_b0};

    wire [31:0] result      = aes_mix ? result_mix : {24'b0, aes_sbox_out[a]};

    wire [31:0] rotated     =
        bs == 2'd0 ? {result                      } :
        bs == 2'd1 ? {result[23:0], result[31:24] } :
        bs == 2'd2 ? {result[15:0], result[31:16] } :
     /* bs == 2'd3*/ {result[ 7:0], result[31: 8] } ;

    assign aes_result[a] = rotated ^ rs1[a];

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
.dec     (aes_dec       ), // Decrypt
.rng     (rng           ), // Random bits
.sbox_in (aes_sbox_in   ), // SMAX share input
.sbox_out(aes_sbox_out  )  // SMAX share output
);

`undef DBG
endmodule
