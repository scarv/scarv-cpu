
//
// module: sme_mdu
//
//  Core multiplier unit
//
module sme_mdu (

input  wire         g_clk       , // Clock
output wire         g_clk_req   , // Clock Request
input  wire         g_resetn    , // Active low synchronous reset.

input  wire         flush       , // Flush and stop any execution.

input  wire         valid       , // Inputs are valid.
input  wire         op_mul      , //
input  wire         op_mulh     , //
input  wire         op_mulhu    , //
input  wire         op_mulhsu   , //
input  wire         op_clmul    , //
input  wire         op_clmulh   , //
input  wire         op_clmulr   , //

input  wire [XL: 0] rs1         , // Source register 1
input  wire [XL: 0] rs2         , // Source register 2

output wire         ready       , // Finished computing
output wire [XL: 0] rd            // Result

);

parameter  XLEN = 32;

localparam MLEN = XLEN*2;
localparam MW   = MLEN-1;

// When to request a clock signal.
assign      g_clk_req   = valid || flush;

//
// Result signals.
// ------------------------------------------------------------

wire [XL:0] result_mul  ;
wire [XL:0] result_clmul;

wire        any_mul     = op_mul || op_mulh || op_mulhu || op_mulhsu;
wire        any_clmul   = op_clmul || op_clmulh || op_clmulr;

assign      rd          = {XLEN{any_mul     }} & result_mul     |
                          {XLEN{any_clmul   }} & result_clmul   ;

assign      ready       = any_mul   ? mul_done      :
                          any_clmul ? clmul_done    : 
                                    1'b0            ;

//
// Argument / Variable storage
// ------------------------------------------------------------

reg  [XL:0] s_rs1;
reg  [XL:0] s_rs2;

reg  [XL:0] n_rs1_mul;
reg  [XL:0] n_rs2_mul;

reg  [MW:0]   mdu_state;

always @(posedge g_clk) begin
    if(!g_resetn || flush) begin
        s_rs1       <= {XLEN{1'b0}};
        s_rs2       <= {XLEN{1'b0}};
    end else if(mul_start || clmul_start) begin
        s_rs1       <= rs1;
        s_rs2       <= rs2;
        mdu_state   <= {2*XLEN{1'b0}};
    end else if(mul_run) begin
        s_rs1       <= n_rs1_mul;
        s_rs2       <= n_rs2_mul;
        if(!n_mul_done || MUL_UNROLL == 1) begin
            mdu_state   <= n_mul_state;
        end
    end else if(clmul_run) begin
        s_rs1       <= n_rs1_clmul;
        s_rs2       <= n_rs2_clmul;
        if(!n_clmul_done || CLMUL_UNROLL == 1) begin
            mdu_state   <= n_clmul_state;
        end
    end
end

//
// Op counter
// ------------------------------------------------------------

reg  [ 6:0 ]    mdu_ctr ;
reg             mdu_done;
wire          n_mdu_done = n_mul_done || n_clmul_done;
reg             mdu_run ;

wire            mdu_start = mul_start || clmul_start;

always @(posedge g_clk) begin
    if (!g_resetn || flush) begin
        mdu_run     <= 1'b0;
        mdu_done    <= 1'b0;
        mdu_ctr     <= 'd0;
    end else if (mdu_start) begin
        mdu_run     <= 1'b1;
        mdu_done    <= 1'b0;
        mdu_ctr     <= 'd32;
    end else if(mdu_run) begin
        if(any_mul   && mdu_ctr == MUL_END    ||
           any_clmul && mdu_ctr == CLMUL_END  ) begin
            mdu_done    <= n_mdu_done;
            mdu_run     <= 1'b0;
        end else begin
            mdu_ctr     <= mdu_ctr - (any_mul   ? MUL_UNROLL   :
                                      any_clmul ? CLMUL_UNROLL :'d1);
        end
    end
end

//
// Multiplier
// ------------------------------------------------------------

parameter MUL_UNROLL = 4;
localparam MUL_END   = (MUL_UNROLL & 'd1) ==0 ? 0 : 1;

wire        mul_start = valid && any_mul && !mul_run && !mul_done;
wire        mul_hi    = op_mulh || op_mulhu || op_mulhsu;

assign      result_mul= 
    mul_hi  ? mdu_state[MW:XLEN] :
              mdu_state[XL:   0] ;

wire      n_mul_done= mdu_ctr == MUL_END && mul_run;

reg           mul_run   ; // Is the multiplier currently running?
reg           mul_done  ; // Is the multiplier complete.
reg  [  XL:0] to_add    ; // The thing added to current accumulator.
reg           to_add_sign;// The thing added to current accumulator.
reg  [XLEN:0] mul_add_l ; // Left hand side of multiply addition.
reg  [XLEN:0] mul_add_r ; // Right hand side of multiply addition.
reg  [XLEN:0] mul_sum   ; // Output of multiply addition.
reg           sub_last  ; // Subtract during final iteration? 

// Treat inputs as signed?
wire          lhs_signed = op_mulh || op_mulhsu;
wire          rhs_signed = op_mulh;

reg           mul_l_sign; // Sign of current left operand.
reg           mul_r_sign; // Sign of current right operand.

reg  [MW:0]  n_mul_state;

integer i;
always @(*) begin
    
    n_mul_state = mdu_state;
    n_rs1_mul   = s_rs1;
    n_rs2_mul   = s_rs2 >> MUL_UNROLL;
    sub_last    = 1'b0;

    for(i = 0; i < MUL_UNROLL; i = i + 1) begin
        sub_last    = i == (MUL_UNROLL - 1) &&
                      mdu_ctr == MUL_UNROLL &&
                      rhs_signed && s_rs2[MUL_UNROLL-1];
        to_add      = s_rs2[i]   ? s_rs1      : {XLEN{1'b0}};
        to_add_sign = to_add[XL]                            ;
        mul_l_sign  = lhs_signed && n_mul_state[MW]         ;
        mul_r_sign  = lhs_signed && to_add_sign             ;
        mul_add_l   = {mul_l_sign,n_mul_state[MW:XLEN]};
        mul_add_r   = {mul_r_sign,to_add              };
        if(sub_last) begin
            mul_add_r = ~mul_add_r;
        end
        mul_sum     = mul_add_l + mul_add_r + {{XLEN{1'b0}},sub_last};
        n_mul_state = {mul_sum, n_mul_state[XL:1]};
    end
end

always @(posedge g_clk) begin
    if (!g_resetn || flush) begin
        mul_run     <= 1'b0;
        mul_done    <= 1'b0;
    end else if (mul_start) begin
        mul_run     <= 1'b1;
        mul_done    <= 1'b0;
    end else if(mul_run) begin
        if(mdu_ctr == MUL_END) begin
            mul_done    <= n_mul_done;
            mul_run     <= 1'b0;
        end
    end
end

//
// Carryless multiplier
// ------------------------------------------------------------

parameter  CLMUL_UNROLL = 8;
localparam CLMUL_END    = 0;

wire       clmul_start  = valid && any_clmul && !clmul_run && !clmul_done;
reg        clmul_run    ; // Is the carry-less multiplier currently running?
reg        clmul_done   ; // Is the carry-less multiplier complete.
wire     n_clmul_done   = mdu_ctr == CLMUL_END && clmul_run;

// This is what we write back to GPR[rd].
assign result_clmul = op_clmulh   ? mdu_state[MW  :XLEN  ] :
                      op_clmulr   ? mdu_state[MW-1:XLEN-1] :
                                    mdu_state[XL  :     0] ;

reg [MW:0] n_clmul_state;
reg [XL:0] n_rs1_clmul  ;
reg [XL:0] n_rs2_clmul  ;
reg [XL:0] clmul_rhs    ;

integer j;
always @(*) begin
    n_clmul_state = mdu_state;
    n_rs1_clmul = s_rs1;
    n_rs2_clmul = s_rs2 >> CLMUL_UNROLL;

    for(j = 0; j < CLMUL_UNROLL; j = j + 1) begin
        clmul_rhs = s_rs2[j] ? s_rs1 : 32'b0;
        n_clmul_state = {
            1'b0                                ,
            n_clmul_state[MW:XLEN] ^ clmul_rhs  ,
            n_clmul_state[XL:1]            
        };
    end
end

always @(posedge g_clk) begin
    if (!g_resetn || flush) begin
        clmul_run     <= 1'b0;
        clmul_done    <= 1'b0;
    end else if (clmul_start) begin
        clmul_run     <= 1'b1;
        clmul_done    <= 1'b0;
    end else if(clmul_run) begin
        if(mdu_ctr == CLMUL_END) begin
            clmul_done    <= n_clmul_done;
            clmul_run     <= 1'b0;
        end
    end
end

endmodule


