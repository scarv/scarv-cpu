
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
input  wire             op_ror   ,// Rotate right
input  wire             op_rol   ,// Rotate left
input  wire             op_pack  ,// Pack
input  wire             op_packh ,// "
input  wire             op_packu ,// "
input  wire             op_grev  ,// Generalized reverse
input  wire             op_shfl  ,// Shuffle
input  wire             op_unshfl,// Unshuffle
input  wire             op_xnor  ,// 
input  wire             op_orn   ,// 
input  wire             op_andn  ,// 
input  wire             op_clz   , // Count leading zeros
input  wire             op_ctz   , // Count trailing zeros
input  wire             op_gorc  , // Generalised OR combine
input  wire             op_max   , // Max
input  wire             op_maxu  , // Max (unsigned)
input  wire             op_min   , // Min
input  wire             op_minu  , // Min (unsigned)
input  wire             op_pcnt  , // Popcount
input  wire             op_sextb , // Sign extend byte
input  wire             op_sexth , // Sign extend halfword
input  wire             op_slo   , // Shift left ones
input  wire             op_sro   , // Shift right ones.
input  wire             op_xpermn, // Crossbar permutation: Nibbles
input  wire             op_xpermb, // Crossbar permutation: Bytes

output wire [   XL:0]   add_out , // Result of adding opr_a and opr_b
output wire             cmp_eq  , // Result of opr_a == opr_b
output wire             cmp_lt  , // Result of opr_a <  opr_b
output wire             cmp_ltu , // Result of opr_a <  opr_b

output wire [   XL:0]   result    // Operation result

);

// Common core parameters and constants
`include "frv_common.svh"

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
// SLT / SLTU / MIN[u] / MAX[u]
// TODO: Gate inputs to comparators when not in use.
// ------------------------------------------------------------

wire        slt_signed      = $signed(opr_a) < $signed(opr_b);

wire        slt_unsigned    = $unsigned(opr_a) < $unsigned(opr_b);

wire        slt_lsbu        = slt_unsigned ;

wire        slt_lsb         = slt_signed   ;

assign      cmp_ltu         = slt_lsbu;
assign      cmp_lt          = slt_lsb;

wire [XL:0] slt_result      = {{XL{1'b0}}, op_slt ? slt_lsb : slt_lsbu};

wire        min_any         = op_minu || op_min  ;
wire        max_any         = op_maxu || op_max  ;

wire        minmax_selbit   = op_maxu || op_minu ? slt_unsigned : 
                                                   slt_signed   ;

wire [XL:0] result_min      =  minmax_selbit ? opr_a : opr_b;
wire [XL:0] result_max      = !minmax_selbit ? opr_a : opr_b;

//
// Sign Extension: sextb, sexth
// ------------------------------------------------------------

// Gate sign bits by their operation to prevent extra toggling.
wire        signbit_b       = opr_a[ 7] && op_sextb;
wire        signbit_h       = opr_a[15] && op_sexth;

wire [15:0] sign_upperhalf  = {16{signbit_b || signbit_h}};
wire [ 7:0] sign_byte1      = { 8{signbit_b             }};

wire [XL:0] sign_result     = {sign_upperhalf,
                               op_sextb ? sign_byte1 : opr_a[15:8],
                               opr_a[7:0]};

wire        sign_any        = op_sextb || op_sexth;

//
// Bitwise Operations
// ------------------------------------------------------------

wire [XL:0] opr_b_n         = op_xnor || op_orn || op_andn ? ~opr_b : opr_b;

wire [XL:0] xor_output      = opr_a ^ opr_b_n;
wire [XL:0]  or_output      = opr_a | opr_b_n;
wire [XL:0] and_output      = opr_a & opr_b_n;

wire [XL:0] bitwise_result  = {XLEN{op_xor || op_xnor}} &  xor_output |
                              {XLEN{op_or  || op_orn }} &   or_output |
                              {XLEN{op_and || op_andn}} &  and_output ;
//
// Pack*
// ------------------------------------------------------------

wire [XL:0] pack_output     = {       opr_b[15: 0], opr_a[15: 0]};
wire [XL:0] packu_output    = {       opr_b[31:16], opr_a[31:16]};
wire [XL:0] packh_output    = {16'b0, opr_b[ 7: 0], opr_a[ 7: 0]};

wire [XL:0] pack_result     = {XLEN{op_pack }} & pack_output    |
                              {XLEN{op_packh}} & packh_output   |
                              {XLEN{op_packu}} & packu_output   ;

//
// Popcount
// ------------------------------------------------------------

wire [31:0] pcnt_in = opr_a;
wire [ 1:0] pcnt_s1 [15:0];
wire [ 2:0] pcnt_s2 [ 7:0];
wire [ 3:0] pcnt_s3 [ 3:0];

genvar p1; // Count set bits in each adjacent bit pair.
generate for(p1 = 0; p1 < 16; p1 = p1 +1 ) begin
    wire [1:0] bits = pcnt_in[p1*2+:2];
    assign pcnt_s1[p1] = {
        bits[0] && bits[1],
        bits[0]  ^ bits[1]
    };
end endgenerate

genvar p2; // Sum bit pair counts into 8 3-bit elements.
generate for(p2 = 0; p2 < 8; p2 = p2 + 1) begin
    wire [1:0] bl = pcnt_s1[2*p2 + 0];
    wire [1:0] br = pcnt_s1[2*p2 + 1];
    assign pcnt_s2[p2][0] = bl[0] ^  br[0];
    assign pcnt_s2[p2][1] =(bl[0] && br[0]) || (bl[1] ^ br[1]);
    assign pcnt_s2[p2][2] = bl[1] && br[1];
end endgenerate

genvar p3; // Sum adjacent 3-bit elements into 4 4-bit elements.
generate for(p3 = 0; p3 < 4; p3 = p3 + 1) begin
    assign pcnt_s3[p3] = pcnt_s2[2*p3 + 0] + pcnt_s2[2*p3 + 1];
end endgenerate

// Sum the 4 4-bit elements together.
wire [ 5:0] pcnt_count  = {2'b00,pcnt_s3[0]}  + 
                          {2'b00,pcnt_s3[1]}  +
                          {2'b00,pcnt_s3[2]}  +
                          {2'b00,pcnt_s3[3]}  ;

wire [XL:0] pcnt_result = {26'b0, pcnt_count};

//
// Count leading/trailing zeros
// ------------------------------------------------------------

function [2:0] clz4;
    input [3:0] bits;
    casez(bits)
        4'b1???: clz4 = 3'd0;
        4'b01??: clz4 = 3'd1;
        4'b001?: clz4 = 3'd2;
        4'b0001: clz4 = 3'd3;
        4'b0000: clz4 = 3'd4;
    endcase
endfunction

function [3:0] clz8;
    input [7:0] bits;
    reg [2:0] hn, ln;
    hn = clz4(bits[7:4]);
    ln = clz4(bits[3:0]);
    clz8 = hn == 3'd4 ? 4'd4 + ln : {1'b0,hn};
endfunction

function [4:0] clz16;
    input [15:0] bits;
    reg [3:0] hn, ln;
    hn = clz8(bits[15: 8]);
    ln = clz8(bits[ 7: 0]);
    clz16 = hn == 4'd8 ? 4'd8 + ln : {1'b0,hn};
endfunction

function [5:0] clz32;
    input [31:0] bits;
    reg [4:0] hn, ln;
    hn = clz16(bits[31:16]);
    ln = clz16(bits[15: 0]);
    clz32 = hn == 5'd16 ? 5'd16 + ln : {1'b0,hn};
endfunction

wire [XL:0] ctz_in;
genvar c;
generate for(c = 0; c < XLEN; c = c+1) begin
assign ctz_in[c] = opr_a[XL-c];
end endgenerate

wire        cz_any    = op_clz || op_ctz;

wire [XL:0] clz_in    = op_clz ? opr_a         :
                        op_ctz ? ctz_in        :
                                 {XLEN{1'b0}}  ;

wire [XL:0] result_cz ;

assign      result_cz = {26'b0,clz32(clz_in)};

//
// Shifts and rotates
// ------------------------------------------------------------

wire [XL:0] shift_in_r  = opr_a;
wire [XL:0] shift_in_l  ;

wire        shift_abit  = opr_a[XL] || op_slo || op_sro;

wire        sr_ones     = op_slo || op_sro || op_sra ;
wire        sr_left     = op_sll || op_rol || op_slo ;
wire        sr_right    = op_srl || op_ror || op_sro || op_sra;
wire        rotate      = op_rol || op_ror ;

localparam SW = (XLEN*2) - 1;

wire [XL:0] shift_in_lo = sr_left ? shift_in_l : shift_in_r;

wire [XL:0] shift_in_hi = rotate  ? (shift_in_lo     )  :
                          sr_ones ? {XLEN{shift_abit}}  :
                                     32'b0              ;

wire [SW:0] shift_in    = {shift_in_hi, shift_in_lo     };

wire [SW:0] shift_out   = shift_in    >> shamt          ;
wire [XL:0] shift_out_r = shift_out[XL:0]               ;
wire [XL:0] shift_out_l ;

genvar i;
generate for(i = 0; i < XLEN; i = i + 1) begin
    assign shift_in_l [i] = shift_in_r [XL-i];
    assign shift_out_l[i] = shift_out_r[XL-i];
end endgenerate

wire [XL:0] shift_result=
    {XLEN{sr_left }} &  shift_out_l |
    {XLEN{sr_right}} &  shift_out_r ;

//
// GREV / GORC
// ------------------------------------------------------------

// Control bits for grev and [un]shfl
wire [ 4:0] ctrl       = opr_b[4:0];

// Result for GREV or GORC
reg  [XL:0] grev_result;

wire        grev_gorc = op_grev || op_gorc;

`define GREV_STEP(M1, M2, CTRL, SHF)                                        \
  grev_result = (op_gorc ? grev_result : {XLEN{1'b0}}) | (                  \
    ctrl[CTRL] ? ((grev_result & M1) << SHF) | ((grev_result & M2) >> SHF) :\
                   grev_result                                            );

always @(*) begin
    grev_result = opr_a;
    `GREV_STEP(32'h55555555, 32'hAAAAAAAA, 0,  1)
    `GREV_STEP(32'h33333333, 32'hCCCCCCCC, 1,  2)
    `GREV_STEP(32'h0F0F0F0F, 32'hF0F0F0F0, 2,  4)
    `GREV_STEP(32'h00FF00FF, 32'hFF00FF00, 3,  8)
    `GREV_STEP(32'h0000FFFF, 32'hFFFF0000, 4, 16)
end

`undef GREV_STEP

//
// SHFL and UNSHFL
// ------------------------------------------------------------

`define SHFL_STEP(CTRL,SRC, ML, MR, N)                                      \
  SRC    =                                                                  \
    ctrl[CTRL] ? ((SRC  & ~(ML|MR)) | ((SRC << N) & ML) | ((SRC>>N) & MR)) :\
                   SRC

reg  [XL:0] shfl_result  ;
reg  [XL:0] unshfl_result;

always @(*) begin
    shfl_result = opr_a;
    `SHFL_STEP(3, shfl_result, 32'h00FF0000, 32'h0000FF00, 8);
    `SHFL_STEP(2, shfl_result, 32'h0F000F00, 32'h00F000F0, 4);
    `SHFL_STEP(1, shfl_result, 32'h30303030, 32'h0C0C0C0C, 2);
    `SHFL_STEP(0, shfl_result, 32'h44444444, 32'h22222222, 1);
    
    unshfl_result = opr_a;
    `SHFL_STEP(0, unshfl_result, 32'h44444444, 32'h22222222, 1);
    `SHFL_STEP(1, unshfl_result, 32'h30303030, 32'h0C0C0C0C, 2);
    `SHFL_STEP(2, unshfl_result, 32'h0F000F00, 32'h00F000F0, 4);
    `SHFL_STEP(3, unshfl_result, 32'h00FF0000, 32'h0000FF00, 8);
end


`undef SHFL_STEP

//
// Crossbar permutations: xperm.*
// ------------------------------------------------------------

function [31:0] xperm_n;
    input [31:0] rs1, rs2;
    integer i;
    reg [ 3:0] pos;
    reg [31:0] sel;
    xperm_n = 32'b0;
    for(i = 0; i < 32; i = i + 4) begin
        pos = rs2[i+:4];
        sel = rs1 >> {pos[3:0],2'b00};
        xperm_n[i+:4] = pos < 8 ? sel[3:0] : 4'b0000;
    end
endfunction

function [31:0] xperm_b;
    input [31:0] rs1, rs2;
    integer i;
    reg [ 7:0] pos;
    reg [31:0] sel;
    xperm_b = 32'b0;
    for(i = 0; i < 32; i = i + 8) begin
        pos = rs2[i+:8];
        sel = rs1 >> {pos[1:0],3'b000};
        xperm_b[i+:8] = pos < 4 ? sel[7:0] : 8'b0000;
    end
endfunction

wire xperm_any          = op_xpermn || op_xpermb ;
wire [31:0] xperm_result= 
    {32{op_xpermn}} & xperm_n(opr_a, opr_b) |
    {32{op_xpermb}} & xperm_b(opr_a, opr_b) ;

//
// Result multiplexing
// ------------------------------------------------------------

wire sel_addsub = op_add || op_sub  ;
wire sel_slt    = op_slt || op_sltu ;
wire sel_shift  = op_sll || op_sra  || op_srl || rotate || op_slo || op_sro;

assign result =
                         bitwise_result             |
                         pack_result                |
    {XLEN{cz_any    }} & result_cz                  |
    {XLEN{op_pcnt   }} & pcnt_result                |
    {XLEN{sign_any  }} & sign_result                |
    {XLEN{max_any   }} & result_max                 |
    {XLEN{min_any   }} & result_min                 |
    {XLEN{grev_gorc }} & grev_result                |
    {XLEN{op_shfl   }} & shfl_result                |
    {XLEN{op_unshfl }} & unshfl_result              |
    {XLEN{sel_addsub}} & addsub_result              |
    {XLEN{sel_slt   }} & slt_result                 |
    {XLEN{sel_shift }} & shift_result               |
    {XLEN{xperm_any }} & xperm_result               ;

endmodule

