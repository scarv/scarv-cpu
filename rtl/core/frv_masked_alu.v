module frv_masked_alu (
//    input              rst, clk, val,
//    input       [2:0]  opt,  // operation 0:XOR; 1:And; 2:OR; 3:ADD; 4:SUB
//    input              i_gs,
////  input       [31:0] i_gs,
//    input       [31:0] i_a0, i_a1,
//    input       [31:0] i_b0, i_b1,
//    output reg  [31:0] o_s0, o_s1,
//    output reg         rdy
//);
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
output wire [XL:0] mask             , // The mask, used for verification only.
output wire [XL:0] rd_s0            , // Output share 0
output wire [XL:0] rd_s1              // Output share 1

);

`include "frv_common.vh"

wire [XL:0] i_a0, i_a1;
wire [XL:0] i_b0, i_b1;
reg  [XL:0] o_s0, o_s1;

assign i_a0 = rs1_s0;
assign i_a1 = rs1_s1;

assign i_b0 = rs2_s0;
assign i_b1 = rs2_s1;

wire [XL:0] gs_0;
wire [XL:0] mxor0, mxor1;
wire [XL:0] mand0, mand1;
wire [XL:0] madd0, madd1;

wire [ 2:0] seq_cnt;
wire        addsub_ena, addsub_ini;
wire 	    mlogic_ena;

// decode 
wire donot = op_b_not;
wire doxor = op_b_xor;
wire doand = op_b_and;
wire doior = op_b_ior;
wire doadd = op_b_add;
wire dosub = op_b_sub;

wire dob2a = op_b2a;
wire doa2b = op_a2b;

// prng for masking, mask refreshing
wire          prng_req;
reg  [31:0]   prng;
wire        n_prng_lsb = prng[31] ~^ prng[21] ~^ prng[ 1] ~^ prng[ 0];
wire [31:0] n_prng     = {prng[31-1:0], n_prng_lsb};
// Process for updating the LFSR.
always @(posedge g_clk) begin
    if(!g_resetn)      prng <= 32'h6789ABCD;
    else if(prng_req)  prng <= n_prng;
end
assign prng_req = ready;
//boolean masking ior and subtract by controlling the complement of the operands.
wire [XL:0] s_a1; // signed(i_b1)
wire [XL:0] s_b1; // signed(i_a1)
assign s_a1 = (doior )? ~i_a1: i_a1;
assign s_b1 = (doior | dosub)? ~i_b1: i_b1;

//boolean masking not by masking second operand of xor
wire [XL:0] n_b0, n_b1;
assign n_b0 = (donot)? {XLEN{1'b0}}: i_b0;
assign n_b1 = (donot)? {XLEN{1'b0}}: s_b1;

//boolean mask to arithmatic mask by reusing of boolean masking add/sub
//a0^a1 = s0-s1
//(a^x ^ x) + (b^y ^y) = (a+b)^z ^ z
//=>
//a^x = a0; x=a1;     b^y = r ; y=0
//s0=(a-b)^z ^ z;     s1  = r
wire [XL:0] b2a_b0;
assign      b2a_b0 = prng; 

//arithmatic mask to boolean mask by reusing of boolean masking add/sub
//a0-a1 = s0^s1
//(a^x ^ x) - (b^y ^y) = (a-b)^z ^ z
//=>
//a^x = a0; x=0;      b^y =-a1; y=0
//s0  = (a-b)^z;      s1  = z
wire [XL:0] a2b_b0;
assign      a2b_b0 = ~i_a1; 

//boolean masking logic 
wire [XL:0] op_a0, op_a1, op_b0, op_b1;
assign op_a0 = i_a0;
assign op_a1 = (dob2a)? i_a1   : (doa2b)? {XLEN{1'b0}}: s_a1;
assign op_b0 = (dob2a)? b2a_b0 : (doa2b)? a2b_b0      : n_b0;  
assign op_b1 = (dob2a | doa2b)?           {XLEN{1'b0}}: n_b1; 

msklogic    s0(~g_resetn,g_clk,mlogic_ena, n_prng, op_a0,op_a1, op_b0,op_b1, mxor0,mxor1, mand0,mand1,  gs_0);

//boolean masking arithmatic
wire        madd_rdy;
mskaddsub   s1(~g_resetn,g_clk,addsub_ena, addsub_ini, (dosub|doa2b),  gs_0, mxor0,mxor1, mand0,mand1,  madd0, madd1, madd_rdy);

//Control unit for boolean masking calculations
wire        dologic  = valid & (donot | doxor | doand | doior | doadd | dosub | dob2a | doa2b);
wire        doaddsub = valid & (doadd | dosub | dob2a | doa2b);
frv_masked_alu_ctl  ctl(g_resetn,g_clk, dologic, doaddsub, madd_rdy,  mlogic_ena, addsub_ini, addsub_ena);

reg         cal_rdy;
always @(posedge g_clk) 
    if (!g_resetn)                     {cal_rdy} <= 1'd0;
    else if (mlogic_ena & ~doaddsub)   {cal_rdy} <= 1'b1;
    else if (madd_rdy)                 {cal_rdy} <= 1'b1;
    else                               {cal_rdy} <= 1'd0;

// boolean mask, umask, remask
wire opmask = valid & (op_b_mask   | op_a_mask);   //masking operand
wire unmask = valid & (op_b_unmask | op_a_unmask);
wire remask = valid & (op_b_remask | op_a_remask);


wire b_mask = (op_b_mask | op_b_unmask | op_b_remask);

wire [XL:0] am_a0 = i_a0 + prng;
wire [XL:0] bm_a0 = i_a0 ^ prng; 

reg  [XL:0] m_a0_reg;
always @(posedge g_clk) 
    if (!g_resetn)          m_a0_reg <= {XLEN{1'b0}};
    else if (opmask|remask) m_a0_reg <= (b_mask)? bm_a0 : am_a0;

wire [XL:0] xm_a0 = (unmask)? i_a0 : m_a0_reg;

wire [XL:0] arm_a0 = xm_a0 - i_a1;
wire [XL:0] brm_a0 = xm_a0 ^ i_a1;

wire [XL:0] rmask0, rmask1;

assign      rmask0 = (opmask)? m_a0_reg: (b_mask)? brm_a0 : arm_a0; 
assign      rmask1 = (opmask | remask)? prng : {XLEN{1'b0}};


wire domask = opmask | unmask | remask;
reg  msk_rdy;
always @(posedge g_clk) 
    if (!g_resetn)              {msk_rdy} <= 1'd0;
    else if (domask & ~msk_rdy) {msk_rdy} <= 1'b1;
    else                        {msk_rdy} <= 1'd0;





//gather and multiplexing results

always @(*) begin
    if      (donot   ) {o_s0, o_s1} = {mxor0 ,      ~mxor1};
    else if (doxor   ) {o_s0, o_s1} = {mxor0 ,       mxor1};
    else if (doand   ) {o_s0, o_s1} = {mand0 ,       mand1};
    else if (doior   ) {o_s0, o_s1} = {mand0 ,      ~mand1};
    else if (dob2a   ) {o_s0, o_s1} = {madd0^madd1,  prng};
    else if (doa2b   ) {o_s0, o_s1} = {madd0,        madd1};
    else if (doaddsub) {o_s0, o_s1} = {madd0 ,       madd1};
    else if (domask)   {o_s0, o_s1} = {rmask0,       rmask1};
    else               {o_s0, o_s1} = {{XLEN{1'b0}}, {XLEN{1'b0}}};
end

assign ready = cal_rdy | msk_rdy;
//assign ready = cal_rdy;
assign mask  = prng;
assign rd_s0 = o_s0;
assign rd_s1 = o_s1;

endmodule



module frv_masked_alu_ctl(
input            g_resetn, g_clk, valid, doaddsub, madd_rdy, 
output           mlogic_ena, addsub_ini,
output reg       addsub_ena
);

localparam IDL = 2'b00;
localparam LOG = 2'b01;		//executing logical    instructions
localparam ART = 2'b10;		//executing arithmetic instructions
localparam FIN = 2'b11;

reg [1:0] ctl_state = IDL;
always @(posedge g_clk)
  if (!g_resetn) begin
    ctl_state	<= IDL;
    addsub_ena  <= 1'b0;
  end
  else
    case (ctl_state)
      IDL : begin
               ctl_state    <= (valid == 1'b1)? LOG  : IDL; 
               addsub_ena   <= (valid == 1'b1)? 1'b1 : 1'b0; 
            end
      LOG :    ctl_state    <= (doaddsub)? ART: FIN;
      ART :    ctl_state    <= (madd_rdy)? FIN: ART;
      FIN : begin
               ctl_state    <= IDL;			
               addsub_ena   <= 1'b0;  
            end
    endcase						

assign    mlogic_ena = (ctl_state == IDL) && (valid);
assign    addsub_ini = (ctl_state == LOG);
endmodule


module msklogic(
  input         rst, clk, ena, 
//  input  		i_gs,
  input  [31:0] i_gs,
  input  [31:0] i_a0,  i_a1, 
  input  [31:0] i_b0,  i_b1,
  output [31:0] o_xor0, o_xor1,
  output [31:0] o_and0, o_and1,
  output [31:0] o_gs
);

/* verilator lint_off UNOPTFLAT */
wire [31:0] gs;

//assign   gs ={i_gs,i_a1[31:1]};
assign     gs = i_gs; 
//assign o_gs = i_a1[0];
assign   o_gs = {i_gs[0],i_a1[31:1]}; 

generate genvar i;
for (i=0;i<32;i=i+1) begin : gen_pg_s1
	(* keep_hierarchy="yes" *)
    pg pg_s1(rst, clk, ena, gs[i], i_a0[i], i_a1[i],  i_b0[i], i_b1[i],  o_xor0[i], o_xor1[i],  o_and0[i], o_and1[i]);
end
endgenerate


endmodule
//mskaddsub s1( rst,clk,addsub_ena, addsub_ini, sub_lat,  gs_0, mxor0,mxor1, mand0,mand1,  o_s0,o_s1, rdy);
module mskaddsub(
    input         rst, clk, ena, ini,
    input         sub,  // active to perform a-b
//    input         i_gs, 
    input  [31:0] i_gs,
    input  [31:0] mxor0, mxor1,
    input  [31:0] mand0, mand1,
    output [31:0] o_s0, o_s1,
    output        rdy
);

//wire        gs;
wire [31:0] gs;
wire [31:0] p0, p1;
wire [31:0] g0, g1;

//wire        gs_i;
wire [31:0] gs_i;
wire [31:0] p0_i, p1_i;
wire [31:0] g0_i, g1_i;

reg  [ 2:0] seq_cnt;
always @(posedge clk)
  if (rst) 		seq_cnt <=3'd1;
  else if (ena) seq_cnt <=seq_cnt + 1'b1;
  else 			seq_cnt <=3'd1;

assign gs_i = (ini)?   i_gs : gs;
assign p0_i = (ini)?   mxor0: p0;
assign p1_i = (ini)?   mxor1: p1;
assign g0_i = (ini)?   mand0: g0;
assign g1_i = (ini)?   mand1: g1;
seq_process s1( rst,clk,ena, sub, gs_i, seq_cnt,  p0_i ,p1_i,  g0_i,g1_i,   p0,p1, g0,g1,  gs);
postprocess so(              sub,                 mxor0,mxor1, g0  ,g1  ,   o_s0,  o_s1);

assign rdy = (seq_cnt==3'd5);

endmodule



module ksa_ctl(
input            rst, clk, ena,
output 			 pre_ena, seq_sel,
output reg       seq_ena,
output reg [2:0] cnt,
output reg       val
);

localparam IDL = 2'b00;
localparam PRE = 2'b01;
localparam SEQ = 2'b10;
localparam POS = 2'b11;

reg [1:0] ctl_state = IDL;
always @(posedge clk)
  if (rst) begin
    ctl_state <= IDL;
    val       <= 1'b0;
	seq_ena   <= 1'b0;
    cnt       <= 3'd0;
  end
  else
    case (ctl_state)
      IDL : begin
               ctl_state <= (ena == 1'b1)? PRE  : IDL; 
			   seq_ena   <= (ena == 1'b1)? 1'b1 : 1'b0; 
               val       <= 1'b0;
			   cnt       <= 3'd1;
            end
      PRE : begin
               ctl_state <= SEQ;
               cnt       <= cnt + 1'b1;
            end
      SEQ : begin
              ctl_state <= (cnt == 3'd4)? POS: SEQ;
              cnt       <= cnt + 1'b1;
            end
      POS : begin
               ctl_state <= IDL;
			   seq_ena   <= 1'b0;
               val       <= 1'b1;
            end
    endcase						

assign    pre_ena = (ctl_state == IDL) && (ena);
assign    seq_sel = (ctl_state == PRE);
endmodule


module seq_process(
  input         rst, clk, ena,
  input         sub,
//  input         i_gs,
  input  [31:0] i_gs,
  input  [ 2:0] seq,

  input  [31:0] i_pk0, i_pk1,
  input  [31:0] i_gk0, i_gk1,
  output [31:0] o_pk0, o_pk1,
  output [31:0] o_gk0, o_gk1,

//  output        o_gs
  output [31:0] o_gs
);

(* keep="true" *)  wire [31:0] gs;
//assign      gs = {i_gs,i_pk0[31:1]};
assign      gs = i_gs;
//assign    o_gs =       i_pk0[0];
assign    o_gs = {i_gs[0],i_pk0[31:1]};

reg [31:0] gkj0, gkj1;
reg [31:0] pkj0, pkj1;

always @(*) begin
  case (seq)
      3'b001: begin
                  gkj0       = {i_gk0[30:0],1'd0};
                  gkj1       = {i_gk1[30:0],sub};
                  pkj0       = {i_pk0[30:0],1'd0};
                  pkj1       = {i_pk1[30:0],1'd0};
               end
      3'b010 : begin
                  gkj0       = {i_gk0[29:0],2'd0};
                  gkj1       = {i_gk1[29:0],sub,1'd0};                  
                  pkj0       = {i_pk0[29:0],2'd0};
                  pkj1       = {i_pk1[29:0],2'd0};
               end
      3'b011 : begin
                  gkj0       = {i_gk0[27:0],4'd0};
                  gkj1       = {i_gk1[27:0], sub, 3'd0};                  
                  pkj0       = {i_pk0[27:0],4'd0};
                  pkj1       = {i_pk1[27:0],4'd0};
               end
      3'b100 : begin
                  gkj0       = {i_gk0[23:0],8'd0};
                  gkj1       = {i_gk1[23:0],sub, 7'd0};                  
                  pkj0       = {i_pk0[23:0],8'd0};
                  pkj1       = {i_pk1[23:0],8'd0};
               end
      3'b101 : begin
                  gkj0       = {i_gk0[15:0],16'd0};
                  gkj1       = {i_gk1[15:0],sub,15'd0};                  
                  pkj0       = {32'd0};
                  pkj1       = {32'd0};
               end
      default: begin
                  gkj0       = {32'd0};
                  gkj1       = {32'd0};                  
                  pkj0       = {32'd0};
                  pkj1       = {32'd0};
               end
   endcase
end

generate genvar i;
for (i=0;i<32;i=i+1) begin : gen_black_s1
    (* keep_hierarchy="yes" *)	
    black bc_s1(rst,clk,ena,  gs[i],  pkj0[i],pkj1[i],  gkj0[i],gkj1[i],  i_pk0[i],i_pk1[i],  i_gk0[i],i_gk1[i],  o_gk0[i],o_gk1[i],  o_pk0[i],o_pk1[i]);
end
endgenerate

 
endmodule
module postprocess(
  input         sub,
  input  [31:0] i_pk0, i_pk1,
  input  [31:0] i_gk0, i_gk1,
  output [31:0] o_s0 , o_s1
);

//assign o_s0[0]    = i_pk0[0];
//assign o_s1[0]    = i_pk1[0];

assign o_s0 = i_pk0 ^ {i_gk0[30:0],1'b0};
assign o_s1 = i_pk1 ^ {i_gk1[30:0],sub};

endmodule


module pg(
  input  rst, clk, ena,
  input  i_gs,
  input  i_a0, i_a1,
  input  i_b0, i_b1,
  output o_p0, o_p1,
  output o_g0, o_g1
);

//assign o_p = i_a ^ i_b;
//assign o_p0 = i_a0 ^ i_b0;
//assign o_p1 = i_a1 ^ i_b1;

wire p0 = i_a0 ^ i_b0;
wire p1 = i_a1 ^ i_b1;

FF_Nb #(.N(1)) ff_p0(rst,clk, ena, p0, o_p0);
FF_Nb #(.N(1)) ff_p1(rst,clk, ena, p1, o_p1);

//assign o_g = i_a & i_b;
//assign o_g0 = (i_a0 & i_b0) ^ (i_a0 & i_b1);
//assign o_g1 = (i_a1 & i_b0) ^ (i_a1 & i_b1);

wire i_t0 = i_gs ^ (i_a0 & i_b0);
wire i_t1 = i_gs ^ (i_a0 & i_b1);
wire i_t2 = (i_a1 & i_b0);
wire i_t3 = (i_a1 & i_b1);

wire t0,t1;
wire t2,t3;
FF_Nb #(.N(1)) ff_t0(rst,clk, ena, i_t0, t0);
FF_Nb #(.N(1)) ff_t1(rst,clk, ena, i_t1, t1);
FF_Nb #(.N(1)) ff_t2(rst,clk, ena, i_t2, t2);
FF_Nb #(.N(1)) ff_t3(rst,clk, ena, i_t3, t3);
assign o_g0 = t0 ^ t2;
assign o_g1 = t1 ^ t3;

//wire a0, a1, b1;
//FF_Nb #(.N(1)) ff_t2(rst,clk, ena, i_a0, a0);
//FF_Nb #(.N(1)) ff_t3(rst,clk, ena, i_a1, a1);
//FF_Nb #(.N(1)) ff_t4(rst,clk, ena, i_b1, b1);
//assign o_g0 = t0 ^ (a0 & b1);
//assign o_g1 = t1 ^ (a1 & b1);

endmodule
module black(
  input  rst, clk, ena,
  input  i_gs,
  input  i_pj0, i_pj1,
  input  i_gj0, i_gj1,
  input  i_pk0, i_pk1,
  input  i_gk0, i_gk1,
  output o_g0, o_g1,
  output o_p0, o_p1
);

//assign o_g = i_gk ^ (i_gj & i_pk);
//assign o_g0 = i_gk0 ^ (i_gj0 & i_pk0) ^ (i_gj0 & i_pk1);
//assign o_g1 = i_gk1 ^ (i_gj1 & i_pk0) ^ (i_gj1 & i_pk1);
wire i_tg0 = i_gk0 ^ (i_gj0 & i_pk0);
wire i_tg1 = i_gk1 ^ (i_gj1 & i_pk0);
wire i_tg2 =         (i_gj0 & i_pk1);
wire i_tg3 =         (i_gj1 & i_pk1);

wire tg0,tg1;
wire tg2,tg3;
FF_Nb #(.N(1)) ff_tg0(rst,clk, ena, i_tg0, tg0);
FF_Nb #(.N(1)) ff_tg1(rst,clk, ena, i_tg1, tg1);
FF_Nb #(.N(1)) ff_tg2(rst,clk, ena, i_tg2, tg2);
FF_Nb #(.N(1)) ff_tg3(rst,clk, ena, i_tg3, tg3);
assign o_g0 = tg0 ^ tg2;
assign o_g1 = tg1 ^ tg3;

//wire gj0, gj1, pk1;
//FF_Nb #(.N(1)) ff_gj0(rst,clk, ena, i_gj0, gj0);
//FF_Nb #(.N(1)) ff_gj1(rst,clk, ena, i_gj1, gj1);
//FF_Nb #(.N(1)) ff_pk1(rst,clk, ena, i_pk1, pk1);
//assign o_g0 = tg0 ^ (gj0 & pk1);
//assign o_g1 = tg1 ^ (gj1 & pk1);


//assign o_p = i_pk & i_pj;
//assign o_p0 = (i_pk0 & i_pj0) ^ (i_pk1 & i_pj0);
//assign o_p1 = (i_pk0 & i_pj1) ^ (i_pk1 & i_pj1);
wire i_tp0 = i_gs ^ (i_pk0 & i_pj0);
wire i_tp1 = i_gs ^ (i_pk0 & i_pj1);
wire i_tp2 =        (i_pk1 & i_pj0);
wire i_tp3 =        (i_pk1 & i_pj1);

wire tp0,tp1;
wire tp2,tp3;
FF_Nb #(.N(1)) ff_tp0(rst,clk, ena, i_tp0, tp0);
FF_Nb #(.N(1)) ff_tp1(rst,clk, ena, i_tp1, tp1);
FF_Nb #(.N(1)) ff_tp2(rst,clk, ena, i_tp2, tp2);
FF_Nb #(.N(1)) ff_tp3(rst,clk, ena, i_tp3, tp3);
assign o_p0 = tp0 ^ tp2;
assign o_p1 = tp1 ^ tp3;

//wire pj0, pj1;
//FF_Nb #(.N(1)) ff_pj0(rst,clk, ena, i_pj0, pj0);
//FF_Nb #(.N(1)) ff_pj1(rst,clk, ena, i_pj1, pj1);
//assign o_p0 = tp0 ^ (pk1 & pj0);
//assign o_p1 = tp1 ^ (pk1 & pj1);

endmodule

module FF_Nb #(parameter N=1) (
  input  rst, clk,
  input  ena,
  input      [N-1:0] din,
  output reg [N-1:0] dout
);

always @(posedge clk)
  if (rst)        dout <= {N{1'b0}};
  else if (ena)   dout <= din;

endmodule
