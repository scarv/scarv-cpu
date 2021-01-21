
//
// Single flip flop used by masked ALU modules etc.
//
module FF_Nb #(parameter Nb=1, parameter EDG=1) (
  input wire  g_resetn, g_clk,
  input wire  ena,
  input wire  [Nb-1:0] din,
  output reg  [Nb-1:0] dout
);

generate 
  if (EDG == 1'b1) begin : posedge_ff
    always @(posedge g_clk) begin
      if (!g_resetn)    dout <= {Nb{1'b0}};
      else if (ena)     dout <= din;
    end
  end else begin         : negedge_ff
    always @(negedge g_clk) begin
      if (!g_resetn)    dout <= {Nb{1'b0}};
      else if (ena)     dout <= din;
    end
  end
endgenerate

endmodule


//
// module frv_masked_alu
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
input  wire        op_a_add         , // Masked arithmetic add
input  wire        op_a_sub         , // Masked arithmetic subtract.
input  wire        op_f_mul         , // Finite field multiply
input  wire        op_f_aff         , // Affine transform
input  wire        op_f_sqr         , // Squaring

input  wire        prng_update      , // Force the PRNG to update.

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
// Masking ISE - Use a TRNG (1) or a PRNG (0)
parameter MASKING_ISE_TRNG    = 1'b0;

// Masking ISE - Use a DOM Implementation (1) or not (0)
parameter MASKING_ISE_DOM      = 1'b1;

// Enable finite-field instructions (or not).
parameter ENABLE_FAFF = 1;
parameter ENABLE_FMUL = 1;

// Enable the binary masked add/sub instructions
parameter ENABLE_BARITH = 1;

//
// PRNG LFSRs for new masks.
// ------------------------------------------------------------

wire [XL:0]   prng0 ;
wire [XL:0]   prng1 ;
wire [XL:0] n_prng0 ;
wire [XL:0] n_prng1 ;

frv_lfsr32 #(
.RESET_VALUE(32'h6789ABCD)
) i_lfsr32_0(
.g_clk      (g_clk      ), // Clock to update PRNG
.g_resetn   (g_resetn   ), // Syncrhonous active low reset.
.update     (prng_update), // Update PRNG with new value.
.extra_tap  (1'b0       ), // Additional seed bit, possibly from TRNG.
.prng       (prng0      ), // Current PRNG value.
.n_prng     (n_prng0    )  // Next    PRNG value.
);

frv_lfsr32 #(
.RESET_VALUE(32'h87654321)
) i_lfsr32_1(
.g_clk      (g_clk      ), // Clock to update PRNG
.g_resetn   (g_resetn   ), // Syncrhonous active low reset.
.update     (prng_update), // Update PRNG with new value.
.extra_tap  (1'b0       ), // Additional seed bit, possibly from TRNG.
.prng       (prng1      ), // Current PRNG value.
.n_prng     (n_prng1    )  // Next    PRNG value.
);

//
// Operand Setup
// ------------------------------------------------------------

wire        nrs2_opt = (op_b_ior || op_b_sub);
wire [XL:0] op_a0, op_a1, op_b0, op_b1;

assign op_a0 =  rs1_s0;
assign op_a1 =  op_b_ior ?~rs1_s1       :
                op_b2a   ? rs1_s1       :
                op_a2b   ? {XLEN{1'b0}} :
                           rs1_s1       ;

assign op_b0 =  {XLEN{!(op_b2a || op_a2b)}} & rs2_s0;

assign op_b1 =  nrs2_opt ?~rs2_s1       :
                op_b2a   ? b2a_b1       : 
                op_a2b   ?~rs1_s1       :
                           rs2_s1       ; 

//
// Bitwise Operations.
// ------------------------------------------------------------

wire [XL:0] mxor0, mxor1;
wire [XL:0] mand0, mand1;
wire [XL:0] mior0, mior1;
wire [XL:0] mnot0, mnot1;

wire 	    mlogic_ena = valid && (dologic || op_b_addsub) && !ctrl_do_arith;
wire        mlogic_rdy;

// BOOL XOR; BOOL AND: Boolean masked logic executes BoolXor; BoolAnd;
frv_masked_bitwise
#(  .MASKING_ISE_DOM(MASKING_ISE_DOM)) 
msklogic_ins (
.g_resetn   (g_resetn   ),
.g_clk      (g_clk      ), 
.ena        (mlogic_ena ), 
.i_remask0  (prng0      ), 
.i_remask1  (prng1      ), 
.i_a0       (op_a0      ), 
.i_a1       (op_a1      ), 
.i_b0       (op_b0      ),
.i_b1       (op_b1      ), 
.o_xor0     (mxor0      ),
.o_xor1     (mxor1      ), 
.o_and0     (mand0      ),
.o_and1     (mand1      ),  
.o_ior0     (mior0      ),
.o_ior1     (mior1      ),  
.o_not0     (mnot0      ),
.o_not1     (mnot1      ),  
.rdy        (mlogic_rdy )
);

//
// Binary -> Arithmetic re-masking Operations.
// ------------------------------------------------------------

// B2A PRE: reuse the boolean masked add/sub to execute Boolean masking to arithmetic masking instruction
// Expected:rs0 ^ rs1 = rd0 - rd1
// BoolAdd: (a0 ^ a1) + (b0 ^ b1) = (a+b)^z ^ z st. s = a+b
//=>
// a0 = rs0;  a1=rs1;     b0 = prng ; b1=0
//rd0 = s0 ^ s1;         rd1 = prng
wire [XL:0] b2a_a0 = rs1_s0;
wire [XL:0] b2a_b0 = {XLEN{1'b0}};

// keep b2a_b1 unchanging during B2A process
wire [XL:0] b2a_b1;
wire [XL:0] b2a_b1_lat;
wire        b2a_ini = op_b2a && mlogic_ena;

FF_Nb #(.Nb(XLEN)) ff_b2a_b1(
    .g_resetn(g_resetn  ), 
    .g_clk(   g_clk     ), 
    .ena(     b2a_ini   ), 
    .din(     b2a_b1    ), 
    .dout(    b2a_b1_lat)
);

wire [XL:0] b2a_gs = n_prng0 ^ n_prng1;
assign      b2a_b1 = mlogic_ena ? b2a_gs : b2a_b1_lat;


// B2A POST: calculate the ouput of Bool2Arith from the output of BoolAdd 
// calculate output only if the b2a instruction is executed
// to avoid unintentionally unmasking the output of masked add/sub module
wire op_b2a_latched;  //prevent any glitches on the op_b2a  

FF_Nb ff_dob2a(
.g_resetn(g_resetn      ), 
.g_clk(   g_clk         ), 
.ena(     valid         ), 
.din(     op_b2a        ), 
.dout(    op_b2a_latched)
);

wire [XL:0] madd0_gated = op_b2a_latched ? madd0 : prng0;
wire [XL:0] madd1_gated = op_b2a_latched ? madd1 : prng0;
wire [XL:0] mb2a0       = madd0_gated ^ madd1_gated;   
wire [XL:0] mb2a1       = b2a_b1;

//
// Arithmetic Operations.
// ------------------------------------------------------------

// A2B PRE: reuse the boolean masked add/sub to execute arithmetic masking to Boolean masking instruction
// expected:rs0 - rs1 = rd0 ^ rd1
// BoolSub: (a0 ^ a1) - (b0 ^ b1) = s0 ^ s1  st. s = a-b  
//=>
// a0 = rs0;  a1= 0;      b0 = prng; b1= rs1 ^ prng
//rd0 = s0;              rd1 = s1


wire [XL:0] madd0, madd1;

wire        addsub_ena;
wire        madd_rdy;

// SUB OPT: execute the operations at line 5 & 6 in the BoolSub algorithm.
wire        sub     =  op_b_sub || op_a2b;
wire        u_0     =  mand0[0] ^ (mxor0[0] && sub);
wire        u_1     =  mand1[0] ^ (mxor1[0] && sub);
wire [XL:0] s_mand0 = {mand0[XL:1],u_0};
wire [XL:0] s_mand1 = {mand1[XL:1],u_1};

generate if(ENABLE_BARITH) begin : masked_barith_enabled

// BOOL ADD/SUB ITERATION and BOOL ADD/SUB POST 
frv_masked_barith
#(  .MASKING_ISE_DOM(MASKING_ISE_DOM))
mskaddsub_ins(
.g_resetn   (g_resetn   ),
.g_clk      (g_clk      ),    
.flush      (flush      ),
.ena        (addsub_ena ), 
.sub        (sub        ),
.i_gs0      (n_prng0    ), 
.i_gs1      (n_prng1    ), 
.mxor0      (mxor0      ),
.mxor1      (mxor1      ), 
.mand0      (s_mand0    ),
.mand1      (s_mand1    ),  
.o_s0       (madd0      ), 
.o_s1       (madd1      ), 
.rdy        (madd_rdy   )
);

end else begin : masked_barith_disabled

assign madd0    = 32'b0;
assign madd1    = 32'b0;
assign madd_rdy = addsub_ena;

end endgenerate

//
// Shift and rotate operations.
// ------------------------------------------------------------

wire [ 4:0] shamt   = rs2_s0[4:0];

wire        op_shr  = op_b_srli || op_b_slli || op_b_rori;
wire        shr_rdy = valid & op_shr;

// Result shares of shift/rotate operations.
wire [XL:0]  mshr0, mshr1;

// Shifter for share 0
frv_masked_shfrot shfrpt_ins0(
.s      (rs1_s0     ), 
.shamt  (shamt      ), // Shift amount 
.rp     (prng0      ), // random padding
.srli   (op_b_srli  ), // Shift  right
.slli   (op_b_slli  ), // Shift  left
.rori   (op_b_rori  ), // Rotate right
.r      (mshr0      )  
);

// Shifter for share 1
frv_masked_shfrot shfrpt_ins1(
.s      (rs1_s1     ), 
.shamt  (shamt      ), // Shift amount 
.rp     (prng0      ), // random padding
.srli   (op_b_srli  ), // Shift  right
.slli   (op_b_slli  ), // Shift  left
.rori   (op_b_rori  ), // Rotate right
.r      (mshr1      )  
);

//
// MASK	/ REMASK: Boolean masking and remasking
// ------------------------------------------------------------

wire opmask = !flush && op_b_mask;   //masking operation
wire remask = !flush && op_b_remask;

wire op_msk = opmask || remask;
wire [XL:0] rmask0, rmask1;
wire        msk_rdy;

assign rmask0  = prng0 ^ rs1_s0;
assign rmask1  = prng0 ^ ({XLEN{remask}} & rs1_s1);
assign msk_rdy = valid & op_msk;

//
// ARITH ADD/SUB: arithmetic masked add and subtraction 
// ------------------------------------------------------------

wire [XL:0]  amsk0, amsk1;
frv_masked_arith arithmask_ins(
.i_a0   (rs1_s0     ),
.i_a1   (rs1_s1     ),
.i_b0   (rs2_s0     ),
.i_b1   (rs2_s1     ),
.i_gs   (prng0      ),
.mask   (op_a_mask  ),
.remask (op_a_remask),
.doadd  (op_a_add   ),
.dosub  (op_a_sub   ),
.o_r0   (amsk0      ),
.o_r1   (amsk1      )
);

wire         op_amsk  = op_a_mask || op_a_remask ||op_a_add || op_a_sub;
wire         amsk_rdy = valid & op_amsk;

//
// FAFF: Boolean masked affine transformation in field gf(2^8) for AES
// ------------------------------------------------------------

wire [XL:0]  mfaff0, mfaff1;
wire [XL:0]  mfmul0, mfmul1;

generate if (ENABLE_FAFF) begin : FAFF_ENABLED
frv_masked_faff makfaff_ins(	
.i_a0(rs1_s0            ),
.i_a1(rs1_s1            ),
.i_mt({rs2_s1, rs2_s0}  ),
.i_gs(prng0             ),
.o_r0(mfaff0            ),
.o_r1(mfaff1            )
); 
end else begin : FAFF_DISABLED
    assign mfaff0 = 32'b0;
    assign mfaff1 = 32'b0;
end endgenerate

//
// FMUL: Boolean masked multiplication in field gf(2^8) for AES
// ------------------------------------------------------------

generate if(ENABLE_FMUL) begin: FMUL_ENABLED

wire mskfmul_ena=op_f_mul || op_f_sqr;
frv_masked_fmul #(
.MASKING_ISE_DOM(MASKING_ISE_DOM)
)  mskfmul_ins (	
.g_resetn   (g_resetn   ),
.g_clk      (g_clk      ), 
.ena        (mskfmul_ena), 
.i_a0       (rs1_s0     ),
.i_a1       (rs1_s1     ),
.i_b0       (rs2_s0     ),
.i_b1       (rs2_s1     ),
.i_sqr      (op_f_sqr   ),
.i_gs       (prng0      ),
.o_r0       (mfmul0     ),
.o_r1       (mfmul1     )
);
end else begin : FMUL_DISABLED
    assign mfmul0 = 32'b0;
    assign mfmul1 = 32'b0;
end endgenerate

wire mskfield_rdy = valid && (op_f_mul|| op_f_aff || op_f_sqr);

//
// Masked ALU Control
// ------------------------------------------------------------

// Control unit for Boolean masked calculations
wire dologic     = !flush && (op_b_xor || op_b_and || op_b_ior || op_b_not  );
wire op_b_addsub = !flush && (op_b_add || op_b_sub || op_b2a   || op_a2b    );

reg  ctrl_do_arith;

assign addsub_ena   = valid &&             op_b_addsub ;

always @(posedge g_clk) begin
    if(!g_resetn || (valid && ready)) begin
        ctrl_do_arith   <= 1'b0;
    end else if(valid) begin
        ctrl_do_arith   <= dologic || op_b_addsub;
    end
end

//
// OUTPUT MUX: gather and multiplexing results
// ------------------------------------------------------------

assign rd_s0 = {XLEN{op_b_not}} &  mnot0 |
               {XLEN{op_b_xor}} &  mxor0 |
               {XLEN{op_b_and}} &  mand0 |
               {XLEN{op_b_ior}} &  mior0 |
               {XLEN{op_shr  }} &  mshr0 |
               {XLEN{op_b_add}} &  madd0 |
               {XLEN{op_b_sub}} &  madd0 |
               {XLEN{op_a2b  }} &  madd0 |
               {XLEN{op_b2a  }} &  mb2a0 | 
               {XLEN{op_msk  }} &  rmask0|
               {XLEN{op_amsk }} &  amsk0 |
               {XLEN{op_f_mul}} &  mfmul0|
               {XLEN{op_f_sqr}} &  mfmul0|
               {XLEN{op_f_aff}} &  mfaff0;

assign rd_s1 = {XLEN{op_b_not}} &  mnot1 |
               {XLEN{op_b_xor}} &  mxor1 |
               {XLEN{op_b_and}} &  mand1 |
               {XLEN{op_b_ior}} &  mior1 |
               {XLEN{op_shr  }} &  mshr1 |
               {XLEN{op_b_add}} &  madd1 |
               {XLEN{op_b_sub}} &  madd1 |
               {XLEN{op_a2b  }} &  madd1 |
               {XLEN{op_b2a  }} &  mb2a1 |
               {XLEN{op_msk  }} &  rmask1|
               {XLEN{op_amsk }} &  amsk1 |
               {XLEN{op_f_mul}} &  mfmul1|
               {XLEN{op_f_sqr}} &  mfmul1|
               {XLEN{op_f_aff}} &  mfaff1;

assign ready =             (dologic && mlogic_rdy) ||
               madd_rdy || shr_rdy || msk_rdy      ||
               amsk_rdy || mskfield_rdy;

endmodule


