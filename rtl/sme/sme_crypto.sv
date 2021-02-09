
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
input  [XL:0] rng[SM:0] , // RNG outputs.

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

localparam SM   = SMAX-1;
localparam XL   = XLEN-1;

wire        new_instr       = valid && ready;

assign      ready = valid && aes_any && aes_ready;

`define DBG(W,VAR) wire[W:0] dbg_``VAR = VAR[0]^VAR[1]^VAR[2];

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

    assign aes_sbox_in[a] = bs == 0 ? rs2[a][ 7: 0]  :
                            bs == 1 ? rs2[a][15: 8]  :
                            bs == 2 ? rs2[a][23:16]  :
                          /*bs == 3*/ rs2[a][31:24]  ;

    assign aes_result[a] = rs1[a] ^ (
        {24'b0, aes_sbox_out[a]} << {bs, 3'b0} |
        {24'b0, aes_sbox_out[a]} >> {bs, 3'b0} 
    );

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

endmodule
