
//
// module: frv_masked_shuffle
//
//  Performs a permutation of a 32-bit word. Used to shuffle one
//  share of each input/result of a masked operation.
//  This mitigates accidental un-masking through muxing.
//
module frv_masked_shuffle #(
parameter LEN=32
)(
input  wire [LEN-1:0] i ,
input  wire           en,
output wire [LEN-1:0] o
);

(* keep = "true" *) wire [LEN-1:0] shuffled;

genvar J;
generate for (J = 0; J < LEN; J = J+1) begin
    assign shuffled[J] = i[(LEN-1)-J];
end endgenerate

(* keep = "true" *) wire [31:0] out = en ? shuffled : i;

assign o = out;

endmodule


//
// module: frv_masked_alu
//
//  Responsible for performing masking operations.
//
module frv_masked_alu (

input  wire        g_clk            , // Global clock
input  wire        g_resetn         , // Synchronous, active low reset.

input  wire        valid            , // Inputs valid
input  wire        flush            , // Flush the masked ALU.

input  wire        op_b2a           , // Binary to arithmetic mask covert
input  wire        op_a2b           , // Arithmetic to binary mask convert
input  wire        op_b_mask        , // Binary mask
input  wire        op_b_remask      , // Binary remask
input  wire        op_a_mask        , // Arithmetic mask
input  wire        op_a_remask      , // Arithmetic remask
input  wire        op_b_not         , // Binary masked not
input  wire        op_b_and         , // Binary masked and
input  wire        op_b_ior         , // Binary masked or
input  wire        op_b_xor         , // Binary masked xor
input  wire        op_b_add         , // Binary masked addition
input  wire        op_b_sub         , // Binary masked subtraction
input  wire        op_b_srli        , // Shift right, shamt in msk_rs2_s0
input  wire        op_b_slli        , // Shift left, shamt in msk_rs2_s0
input  wire        op_b_rori        , // Shift right, shamt in msk_rs2_s0

input  wire        prng_update      , // Force the PRNG to update.

input  wire [XL:0] rs1_s0           , // RS1 Share 0
input  wire [XL:0] rs1_s1           , // RS1 Share 1
input  wire [XL:0] rs2_s0           , // RS2 Share 0
input  wire [XL:0] rs2_s1           , // RS2 Share 1

output wire        ready            , // Outputs ready
output wire [XL:0] mask             , // The mask, used for verification only.
output wire [XL:0] rd_s0            , // Output share 0
output wire [XL:0] rd_s1              // Output share 1

);

// Common core parameters and constants
`include "frv_common.vh"

//
// Masking ISE - Use a TRNG (1) or a PRNG (0)
parameter MASKING_ISE_TRNG    = 1'b0;

// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b1;

// Use a fast implementaiton of the masking ISE instructions.
parameter MASKING_ISE_FAST    = 1'b1;

// PRNG for masking, mask refreshing
wire          prng_req;
reg  [31:0]   prng;
wire        n_prng_lsb = prng[31] ~^ prng[21] ~^ prng[ 1] ~^ prng[ 0];
wire [31:0] n_prng     = {prng[31-1:0], n_prng_lsb};
// Process for updating the LFSR.
always @(posedge g_clk) begin
    if(!g_resetn)      prng <= 32'h6789ABCD;
    else if(prng_req || prng_update)  prng <= n_prng;
end
assign prng_req = ready;

wire [XL:0] gs_0;
wire [XL:0] mxor0, mxor1;
wire [XL:0] mand0, mand1;
wire [XL:0] madd0, madd1;

wire [ 2:0] seq_cnt;
wire        addsub_ena;
wire 	    mlogic_ena;

// Boolean masked IOR and SUB by controlling the complement of the operands.
wire [XL:0] s_a1; // signed(rs2_s1)
wire [XL:0] s_b1; // signed(rs1_s1)
assign s_a1 = (op_b_ior          ) ? ~rs1_s1: rs1_s1;
assign s_b1 = (op_b_ior||op_b_sub) ? ~rs2_s1: rs2_s1;

// Boolean masked NOT by masking second operand of XOR
wire [XL:0] n_b0, n_b1;
assign n_b0 = (op_b_not)? {XLEN{1'b0}}: rs2_s0;
assign n_b1 = (op_b_not)? {XLEN{1'b0}}: s_b1;

// Boolean masking to arithmetic masking by reusing the boolean masked add/sub
//a0^a1 = s0-s1
//(a^x ^ x) + (b^y ^y) = (a+b)^z ^ z
//=>
//a^x = a0; x=a1;     b^y = r ; y=0
//s0=(a-b)^z ^ z;     s1  = r
wire [XL:0] b2a_b0;
assign      b2a_b0 = prng; 

// Arithmetic masking to boolean masking by reusing the boolean masked add/sub
//a0-a1 = s0^s1
//(a^x ^ x) - (b^y ^y) = (a-b)^z ^ z
//=>
//a^x = a0; x=0;      b^y =-a1; y=0
//s0  = (a-b)^z;      s1  = z
wire [XL:0] a2b_b0;
assign      a2b_b0 = ~rs1_s1; 

// Boolean masked logic 
wire [XL:0] op_a0, op_a1, op_b0, op_b1;

assign op_a0 = rs1_s0;

assign op_a1 = op_b2a ? rs1_s1      :
               op_a2b ? {XLEN{1'b0}}:
                        s_a1        ;

assign op_b0 = op_b2a ? b2a_b0      :
               op_a2b ? a2b_b0      :
                        n_b0        ;

assign op_b1 = op_b2a || op_a2b ? {XLEN{1'b0}}: n_b1; 

wire mlogic_rdy;
msklogic #(
    .MASKING_ISE_TI(MASKING_ISE_TI)
) msklogic_ins (
    .g_resetn(  g_resetn),
    .g_clk(     g_clk), 
    .ena(       mlogic_ena), 
    .i_gs(      n_prng), 
    .i_a0(      op_a0), 
    .i_a1(      op_a1), 
    .i_b0(      op_b0),
    .i_b1(      op_b1), 
    .o_xor0(    mxor0),
    .o_xor1(    mxor1), 
    .o_and0(    mand0),
    .o_and1(    mand1),  
    .o_gs(      gs_0),
    .rdy(       mlogic_rdy)
);

// Boolean masked add/sub
wire        madd_rdy;
mskaddsub   
#(  .MASKING_ISE_TI(MASKING_ISE_TI))
mskaddsub_ins(
    .g_resetn(  g_resetn),
    .g_clk(     g_clk),    
    .flush(     flush),
    .ena(       addsub_ena), 
    .sub(       op_b_sub|op_a2b),
    .i_gs(      gs_0), 
    .mxor0(     mxor0),
    .mxor1(     mxor1), 
    .mand0(     mand0),
    .mand1(     mand1),  
    .o_s0(      madd0), 
    .o_s1(      madd1), 
    .rdy(       madd_rdy));

// Control unit for Boolean masked calculations
wire dologic     = (!flush) && (op_b_not || op_b_xor || op_b_and || op_b_ior);
wire op_b_addsub = (!flush) && (op_b_add || op_b_sub || op_b2a   || op_a2b  );

mskalu_ctl mskaluctl_ins (
    .g_resetn   (g_resetn               ),
    .g_clk      (g_clk                  ),
    .flush      (flush                  ),
    .valid      (valid                  ),
    .dologic    (dologic||op_b_addsub   ), 
    .doaddsub   (op_b_addsub            ), 
    .mlogic_rdy (mlogic_rdy             ),
    .madd_rdy   (madd_rdy               ),
    .mlogic_ena (mlogic_ena             ), 
    .addsub_ena (addsub_ena             )
);

// Boolean masked shift/rotate

wire dosrl   = op_b_srli;
wire dosll   = op_b_slli;
wire doror   = op_b_rori;

// Share 0 input gets reversed, so pick shamt from high 5 bits of rs2_s0
wire [4:0] shamt = rs2_s0[4:0];
    //doshr ? {rs2_s0[27],rs2_s0[28],rs2_s0[29],rs2_s0[30],rs2_s0[31]} : 5'b0;

wire doshr   = op_b_srli || op_b_slli || op_b_rori;
wire shr_rdy = doshr;

wire [XL:0]  mshr0, mshr1;
shfrot shfrpt_ins0(
    .s(      rs1_s0     ), 
    .shamt(  shamt      ), // Shift amount 
    .rp (    prng       ), // random padding
    .srli(op_b_srli     ), // Shift  right
    .slli(op_b_slli     ), // Shift  left
    .rori(op_b_rori     ), // Rotate right
    .r(      mshr0      )  
);

shfrot shfrpt_ins1(
    .s(      rs1_s1     ), 
    .shamt(  shamt      ), // Shift amount 
    .rp (    prng       ), // random padding
    .srli(op_b_srli     ), // Shift  right
    .slli(op_b_slli     ), // Shift  left
    .rori(op_b_rori     ), // Rotate right
    .r(      mshr1      )  
);

// Boolean masking and remasking
wire opmask = (!flush) & (op_b_mask   || op_a_mask  );   //masking operation
wire remask = (!flush) & (op_b_remask || op_a_remask);
wire b_mask = (!flush) & (op_b_mask   || op_b_remask);

wire [XL:0] rmask0, rmask1;
wire        msk_rdy;

generate 
    if (MASKING_ISE_TI == 1'b1) begin : masking_TI

        wire [XL:0] am_a0 = rs1_s0 + prng;
        wire [XL:0] bm_a0 = rs1_s0 ^ prng; 

        reg  [XL:0] m_a0_reg;
        always @(posedge g_clk) 
            if (!g_resetn)          m_a0_reg <= {XLEN{1'b0}};
            else if (opmask|remask) m_a0_reg <= (b_mask)? bm_a0 : am_a0;

        wire [XL:0] xm_a0 = m_a0_reg;

        wire [XL:0] arm_a0 = xm_a0 - rs1_s1;
        wire [XL:0] brm_a0 = xm_a0 ^ rs1_s1;

        assign      rmask0 = (opmask)? m_a0_reg: (b_mask)? brm_a0 : arm_a0; 
        assign      rmask1 = (opmask | remask)? prng : {XLEN{1'b0}};

        wire domask = opmask | remask;
        reg  mask_done;
        always @(posedge g_clk) 
            if (!g_resetn)                {mask_done} <= 1'd0;
            else if (domask & ~mask_done) {mask_done} <= 1'b1;
            else                          {mask_done} <= 1'd0;
        assign msk_rdy = mask_done;

    end else begin                    : masking_non_TI

        wire [XL:0] am_s0 =             rs1_s0 + prng;
        wire [XL:0] am_s1 = (remask) ? (rs1_s1 + prng): prng;
        wire [XL:0] bm_s0 =             rs1_s0 ^ prng;
        wire [XL:0] bm_s1 = (remask) ? (rs1_s1 ^ prng): prng;

        assign rmask0  = b_mask ? bm_s0 : am_s0 ;
        assign rmask1  = b_mask ? bm_s1 : am_s1 ;
        assign msk_rdy = opmask | remask ;
    end
endgenerate

//gather and multiplexing results
assign rd_s0 = {XLEN{op_b_not}} &  mxor0 |
               {XLEN{op_b_xor}} &  mxor0 |
               {XLEN{op_b_and}} &  mand0 |
               {XLEN{op_b_ior}} &  mand0 |
               {XLEN{op_b_add}} &  madd0 |
               {XLEN{op_b_sub}} &  madd0 |
               {XLEN{op_a2b  }} &  madd0 |
               {XLEN{op_b2a  }} &  32'b0 | // FIXME (madd0^madd1) |
               {XLEN{doshr   }} &  mshr0 |
               {XLEN{msk_rdy }} &  rmask0;

assign rd_s1 = {XLEN{op_b_not}} & ~mxor1 |
               {XLEN{op_b_xor}} &  mxor1 |
               {XLEN{op_b_and}} &  mand1 |
               {XLEN{op_b_ior}} & ~mand1 |
               {XLEN{op_b_add}} &  madd1 |
               {XLEN{op_b_sub}} &  madd1 |
               {XLEN{op_a2b  }} &  madd1 |
               {XLEN{op_b2a  }} &  prng  |
               {XLEN{doshr   }} &  mshr1 |
               {XLEN{msk_rdy }} &  rmask1;

assign ready = (dologic && mlogic_rdy) || madd_rdy || msk_rdy || shr_rdy;
assign mask  = prng;

endmodule


module mskalu_ctl(
input  wire      g_resetn, g_clk, flush,
input  wire      valid,
input  wire      dologic, doaddsub, mlogic_rdy, madd_rdy, 
output wire      mlogic_ena,
output wire      addsub_ena
);

localparam S_IDL = 2'b00;
localparam S_LOG = 2'b01;        //executing logical    instructions
localparam S_ART = 2'b10;        //executing arithmetic instructions

wire dologic_valid  = dologic && valid;
wire doaddsub_valid = doaddsub&& valid;

reg [1:0] ctl_state;
always @(posedge g_clk) begin
  if (!g_resetn)    ctl_state <= S_IDL;
  else if (flush)   ctl_state <= S_IDL;
  else begin
    case (ctl_state)
        S_IDL :     ctl_state <= 
                            (dologic_valid) ? 
                           ((mlogic_rdy)    ? 
                           ((doaddsub_valid)? S_ART : S_IDL)
                                                    : S_LOG) 
                                                    : S_IDL; 
        S_LOG :     ctl_state <= (doaddsub_valid)?  S_ART : S_IDL;
        S_ART :     ctl_state <= (madd_rdy)?  S_IDL : S_ART;
        default:    ctl_state <= S_IDL;
    endcase	
  end					
end
assign    mlogic_ena =  dologic_valid  && (ctl_state == S_IDL);
assign    addsub_ena =  doaddsub_valid && ((mlogic_rdy && (ctl_state == S_IDL)) | (ctl_state != S_IDL));

endmodule

// Shift/rotate module to operate on each sharing with random pading
module shfrot(
input  [31:0] s    , // input share
input  [ 4:0] shamt, // Shift amount 
input  [31:0] rp   , // random padding
input         srli , // Shift  right
input         slli , // Shift  left
input         rori , // Rotate right

output [31:0] r      // ouput share
);

wire left = slli;
wire right= srli | rori;

wire [31:0] l0 =  s;

wire [31:0]  l1;
wire [31:0]  l2;
wire [31:0]  l4;
wire [31:0]  l8;
wire [31:0] l16;

wire         l1_rpr = (rori)? l0[   0] : rp[    0];
wire [ 1:0]  l2_rpr = (rori)? l1[ 1:0] : rp[ 2: 1];
wire [ 3:0]  l4_rpr = (rori)? l2[ 3:0] : rp[ 6: 3];
wire [ 7:0]  l8_rpr = (rori)? l4[ 7:0] : rp[14: 7];
wire [15:0] l16_rpr = (rori)? l8[15:0] : rp[30:15];
//
// Level 1 code - shift/rotate by 1.
wire [31:0] l1_left  = {l0[30:0], rp[31]};
wire [31:0] l1_right = {l1_rpr  , l0[31:1]};
  
wire l1_l  = left  && shamt[0];
wire l1_r  = right && shamt[0];
wire l1_n  =         !shamt[0];

assign l1  = {32{l1_l}} & l1_left  |
             {32{l1_r}} & l1_right |
             {32{l1_n}} & l0       ;

// Level 2 code - shift/rotate by 2..
wire [31:0] l2_left  = {l1[29:0], rp[30:29]};
wire [31:0] l2_right = {l2_rpr  , l1[31: 2]};
  
wire l2_l  = left  && shamt[1];
wire l2_r  = right && shamt[1];
wire l2_n  =         !shamt[1];

assign l2  = {32{l2_l}} & l2_left  |
             {32{l2_r}} & l2_right |
             {32{l2_n}} & l1       ;

// Level 3 code - shift/rotate by 4.
wire [31:0] l4_left  = {l2[27:0], rp[28:25]};
wire [31:0] l4_right = {l4_rpr  , l2[31: 4]};
  
wire l4_l  = left  && shamt[2];
wire l4_r  = right && shamt[2];
wire l4_n  =         !shamt[2];
assign l4  = {32{l4_l}} & l4_left  |
             {32{l4_r}} & l4_right |
             {32{l4_n}} & l2       ;

// Level 4 code - shift/rotate by 8.
wire [31:0] l8_left  = {l4[23:0], rp[24:17]};
wire [31:0] l8_right = {l8_rpr  , l4[31: 8]};
  
wire l8_l  = left  && shamt[3];
wire l8_r  = right && shamt[3];
wire l8_n  =         !shamt[3];

assign l8  = {32{l8_l}} & l8_left  |
             {32{l8_r}} & l8_right |
             {32{l8_n}} & l4       ;

// Level 5 code - shift/rotate by 16.
wire [31:0] l16_left  = {l8[15:0], rp[16: 1]};
wire [31:0] l16_right = {l16_rpr , l8[31:16]};
  
wire l16_l  = left  && shamt[4];
wire l16_r  = right && shamt[4];
wire l16_n  =         !shamt[4];

assign l16  = {32{l16_l}} & l16_left  |
              {32{l16_r}} & l16_right |
              {32{l16_n}} & l8        ;

// output
assign r = l16;

endmodule


module msklogic(
  input wire         g_resetn, g_clk, ena, 
  input wire  [31:0] i_gs,
  input wire  [31:0] i_a0,  i_a1, 
  input wire  [31:0] i_b0,  i_b1,
  output wire [31:0] o_xor0, o_xor1,
  output wire [31:0] o_and0, o_and1,
  output wire [31:0] o_gs,
  output wire        rdy
);

// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b0;

(* keep="true" *) 
wire [31:0] gs;
assign      gs = i_gs; 
assign    o_gs = i_a1; 

genvar i;
generate 
    for (i=0;i<32;i=i+1) begin : gen_pg_s1
    (* keep_hierarchy="yes" *)
    pg 
    #(  .MASKING_ISE_TI(MASKING_ISE_TI)) 
    pg_ins(
        .g_resetn(  g_resetn),
        .g_clk(     g_clk),
        .ena(       ena), 
        .i_gs(      gs[i]), 
        .i_a0(      i_a0[i]), 
        .i_a1(      i_a1[i]),  
        .i_b0(      i_b0[i]), 
        .i_b1(      i_b1[i]),  
        .o_p0(      o_xor0[i]), 
        .o_p1(      o_xor1[i]),  
        .o_g0(      o_and0[i]), 
        .o_g1(      o_and1[i]));
end
endgenerate

generate 
    if (MASKING_ISE_TI == 1'b1) begin: masking_TI
        FF_Nb  ff_msklogic_rdy(.g_resetn(g_resetn), .g_clk(g_clk), .ena(1'b1), .din(ena), .dout(rdy));
    end else begin                   : masking_non_TI
        assign rdy = ena;
    end
endgenerate
endmodule

module mskaddsub(
    input wire         g_resetn, g_clk, flush, ena,
    input wire         sub,  // active to perform a-b
    input wire  [31:0] i_gs,
    input wire  [31:0] mxor0, mxor1,
    input wire  [31:0] mand0, mand1,
    output wire [31:0] o_s0, o_s1,
    output wire        rdy
);

// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b0;

wire [31:0] gs;
wire [31:0] p0, p1;
wire [31:0] g0, g1;

wire [31:0] gs_i;
wire [31:0] p0_i, p1_i;
wire [31:0] g0_i, g1_i;

reg  [ 2:0] seq_cnt;
always @(posedge g_clk)
  if (!g_resetn)    seq_cnt <=3'd1;
  else if (flush)   seq_cnt <=3'd1;
  else if (rdy)     seq_cnt <=3'd1;
  else if (ena)     seq_cnt <=seq_cnt + 1'b1;

wire ini = ena && (seq_cnt == 3'd1);

wire [31:0] o_s0_gated;
wire [31:0] o_s1_gated;

assign o_s0 = (rdy || seq_cnt == 3'd1) ? o_s0_gated : 32'b0;
assign o_s1 = (rdy || seq_cnt == 3'd1) ? o_s1_gated : 32'b0;

assign gs_i = (ini)?   i_gs : gs;
assign p0_i = (ini)?   mxor0: p0;
assign p1_i = (ini)?   mxor1: p1;
assign g0_i = (ini)?   mand0: g0;
assign g1_i = (ini)?   mand1: g1;
seq_process 
#(  .MASKING_ISE_TI(MASKING_ISE_TI))
seqproc_ins(
    .g_resetn(  g_resetn),
    .g_clk(     g_clk),
    .ena(       ena), 
    .sub(       sub), 
    .i_gs(      gs_i), 
    .seq(       seq_cnt),  
    .i_pk0(     p0_i),
    .i_pk1(     p1_i),  
    .i_gk0(     g0_i),
    .i_gk1(     g1_i),   
    .o_pk0(     p0),
    .o_pk1(     p1), 
    .o_gk0(     g0),
    .o_gk1(     g1),  
    .o_gs(      gs));

postprocess posproc_ins(
    .sub(       sub),
    .i_pk0(     mxor0),
    .i_pk1(     mxor1), 
    .i_gk0(     g0),
    .i_gk1(     g1),
    .o_s0(      o_s0_gated),
    .o_s1(      o_s1_gated));

assign rdy = (seq_cnt==3'd6);
endmodule

module seq_process(
  input wire         g_resetn, g_clk, ena,
  input wire         sub,
  input wire  [31:0] i_gs,
  input wire  [ 2:0] seq,

  input wire  [31:0] i_pk0, i_pk1,
  input wire  [31:0] i_gk0, i_gk1,
  output wire [31:0] o_pk0, o_pk1,
  output wire [31:0] o_gk0, o_gk1,

  output wire [31:0] o_gs
);

// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b0;

(* keep="true" *)  
wire [31:0] gs;
assign      gs = i_gs;
assign    o_gs = i_pk0;

reg [31:0] gkj0, gkj1;
reg [31:0] pkj0, pkj1;

always @(*) begin
  case (seq)
      3'b001: begin
                  gkj0 = {i_gk0[30:0],1'd0};
                  gkj1 = {i_gk1[30:0],sub};
                  pkj0 = {i_pk0[30:0],1'd0};
                  pkj1 = {i_pk1[30:0],1'd0};
               end
      3'b010 : begin
                  gkj0 = {i_gk0[29:0],2'd0};
                  gkj1 = {i_gk1[29:0],sub,1'd0};                  
                  pkj0 = {i_pk0[29:0],2'd0};
                  pkj1 = {i_pk1[29:0],2'd0};
               end
      3'b011 : begin
                  gkj0 = {i_gk0[27:0],4'd0};
                  gkj1 = {i_gk1[27:0], sub, 3'd0};                  
                  pkj0 = {i_pk0[27:0],4'd0};
                  pkj1 = {i_pk1[27:0],4'd0};
               end
      3'b100 : begin
                  gkj0 = {i_gk0[23:0],8'd0};
                  gkj1 = {i_gk1[23:0],sub, 7'd0};                  
                  pkj0 = {i_pk0[23:0],8'd0};
                  pkj1 = {i_pk1[23:0],8'd0};
               end
      3'b101 : begin
                  gkj0 = {i_gk0[15:0],16'd0};
                  gkj1 = {i_gk1[15:0],sub,15'd0};                  
                  pkj0 = {32'd0};
                  pkj1 = {32'd0};
               end
      default: begin
                  gkj0 = {32'd0};
                  gkj1 = {32'd0};                  
                  pkj0 = {32'd0};
                  pkj1 = {32'd0};
               end
   endcase
end

generate genvar i;
for (i=0;i<32;i=i+1) begin : gen_black_s1
    (* keep_hierarchy="yes" *)	
    pk_gk 
    #(  .MASKING_ISE_TI(MASKING_ISE_TI)) 
    pkgk_ins(
        .g_resetn(  g_resetn),
        .g_clk(     g_clk),
        .ena(       ena), 
        .i_gs(      gs[i]),  
        .i_pj0(     pkj0[i]),
        .i_pj1(     pkj1[i]),
        .i_gj0(     gkj0[i]),
        .i_gj1(     gkj1[i]),
        .i_pk0(     i_pk0[i]),
        .i_pk1(     i_pk1[i]),
        .i_gk0(     i_gk0[i]),
        .i_gk1(     i_gk1[i]),  
        .o_g0(      o_gk0[i]),
        .o_g1(      o_gk1[i]),
        .o_p0(      o_pk0[i]),
        .o_p1(      o_pk1[i]));
end
endgenerate 
endmodule

module postprocess(
  input wire         sub,
  input wire  [31:0] i_pk0, i_pk1,
  input wire  [31:0] i_gk0, i_gk1,
  output wire [31:0] o_s0 , o_s1
);
assign o_s0 = i_pk0 ^ {i_gk0[30:0],1'b0};
assign o_s1 = i_pk1 ^ {i_gk1[30:0],sub};
endmodule


module pg(
  input wire  g_resetn, g_clk, ena,
  input wire  i_gs,
  input wire  i_a0, i_a1,
  input wire  i_b0, i_b1,
  output wire o_p0, o_p1,
  output wire o_g0, o_g1
);
// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b0;

generate 
    if (MASKING_ISE_TI == 1'b1) begin : masking_TI
        wire p0 = i_a0 ^ i_b0;
        wire p1 = i_a1 ^ i_b1;

        FF_Nb  ff_p0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(p0), .dout(o_p0));
        FF_Nb  ff_p1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(p1), .dout(o_p1));

        wire i_t0 = i_gs ^ (i_a0 & i_b0);
        wire i_t1 = i_gs ^ (i_a0 & i_b1);
        wire i_t2 = (i_a1 & i_b0);
        wire i_t3 = (i_a1 & i_b1);

        wire t0,t1;
        wire t2,t3;
        FF_Nb  ff_t0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_t0), .dout(t0));
        FF_Nb  ff_t1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_t1), .dout(t1));
        FF_Nb  ff_t2(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_t2), .dout(t2));
        FF_Nb  ff_t3(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_t3), .dout(t3));

        assign o_g0 = t0 ^ t2;
        assign o_g1 = t1 ^ t3;
    end else begin                    : masking_non_TI
        assign o_p0 = i_a0 ^ i_b0;
        assign o_p1 = i_a1 ^ i_b1;  
    
        assign o_g0 = i_gs ^ (i_a0 & i_b1) ^ (i_a0 | ~i_b0);
        assign o_g1 = i_gs ^ (i_a1 & i_b1) ^ (i_a1 | ~i_b0);  
    end
endgenerate
endmodule

module pk_gk(
  input wire  g_resetn, g_clk, ena,
  input wire  i_gs,
  input wire  i_pj0, i_pj1,
  input wire  i_gj0, i_gj1,
  input wire  i_pk0, i_pk1,
  input wire  i_gk0, i_gk1,
  output wire o_g0, o_g1,
  output wire o_p0, o_p1
);
// Masking ISE - Use a Threshold Implementation (1) or non-TI (0)
parameter MASKING_ISE_TI      = 1'b0;

generate 
    if (MASKING_ISE_TI == 1'b1) begin : masking_TI
        wire i_tg0 = i_gk0 ^ (i_gj0 & i_pk0);
        wire i_tg1 = i_gk1 ^ (i_gj1 & i_pk0);
        wire i_tg2 =         (i_gj0 & i_pk1);
        wire i_tg3 =         (i_gj1 & i_pk1);

        wire tg0,tg1;
        wire tg2,tg3;
        FF_Nb  ff_tg0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tg0), .dout(tg0));
        FF_Nb  ff_tg1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tg1), .dout(tg1));
        FF_Nb  ff_tg2(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tg2), .dout(tg2));
        FF_Nb  ff_tg3(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tg3), .dout(tg3));

        assign o_g0 = tg0 ^ tg2;
        assign o_g1 = tg1 ^ tg3;

        wire i_tp0 = i_gs ^ (i_pk0 & i_pj0);
        wire i_tp1 = i_gs ^ (i_pk0 & i_pj1);
        wire i_tp2 =        (i_pk1 & i_pj0);
        wire i_tp3 =        (i_pk1 & i_pj1);

        wire tp0,tp1;
        wire tp2,tp3;
        FF_Nb  ff_tp0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tp0), .dout(tp0));
        FF_Nb  ff_tp1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tp1), .dout(tp1));
        FF_Nb  ff_tp2(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tp2), .dout(tp2));
        FF_Nb  ff_tp3(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(i_tp3), .dout(tp3));
        assign o_p0 = tp0 ^ tp2;
        assign o_p1 = tp1 ^ tp3;
    end else begin                    : masking_non_TI
        wire pk0 = i_gs  ^ (i_pk0 & i_pj1) ^ (i_pk0 | ~i_pj0);
        wire pk1 = i_gs  ^ (i_pk1 & i_pj1) ^ (i_pk1 | ~i_pj0);  
        FF_Nb  ff_pk0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(pk0), .dout(o_p0));
        FF_Nb  ff_pk1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(pk1), .dout(o_p1));

        wire gk0 = i_gk0 ^ (i_gj0 & i_pk1) ^ (i_gj0 | ~i_pk0);
        wire gk1 = i_gk1 ^ (i_gj1 & i_pk1) ^ (i_gj1 | ~i_pk0);
        FF_Nb  ff_gk0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(gk0), .dout(o_g0));
        FF_Nb  ff_gk1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(gk1), .dout(o_g1));    
    end
endgenerate
endmodule

module FF_Nb #(parameter Nb=1) (
  input wire  g_resetn, g_clk,
  input wire  ena,
  input wire  [Nb-1:0] din,
  output reg  [Nb-1:0] dout
);

always @(posedge g_clk) begin
  if (!g_resetn)    dout <= {Nb{1'b0}};
  else if (ena)     dout <= din;
end

endmodule
