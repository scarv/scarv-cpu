
//
// module: frv_alu_muldiv
//
//  Multipler/divider logic for the EXU.
//
module frv_alu_muldiv(

input              g_clk        , // Global clock
input              g_resetn     , // Global negative level triggered reset

input  wire        exu_stall    , // stalled due to other stages
input  wire        exu_flush    , // should flush everything.
input  wire        pipe_progress, // Pipe is progressing.

input  wire        imul_valid   , // IMUL instruction / op valid
input  wire        imul_mul     , // 
input  wire        imul_mulh    , // 
input  wire        imul_mulhu   , // 
input  wire        imul_mulhsu  , // 
input  wire        imul_div     , // 
input  wire        imul_divu    , // 
input  wire        imul_rem     , // 
input  wire        imul_remu    , // 

input  wire [31:0] imul_lhs     , // Left hand operand
input  wire [31:0] imul_rhs     , // Left hand operand

output wire        imul_ready   , // ready to progress
output wire [31:0] imul_result    // Result of the IMUL operation.

);

//
// Multiply instructions
//

wire        i_mul       = imul_valid && imul_mul   ;
wire        i_mulh      = imul_valid && imul_mulh  ;
wire        i_mulhu     = imul_valid && imul_mulhu ;
wire        i_mulhsu    = imul_valid && imul_mulhsu;

wire        is_mul      = i_mul  || i_mulh  || i_mulhu || i_mulhsu;
wire        mul_hi      = i_mulh || i_mulhu || i_mulhsu;

wire [63:0] mul_result  ;
wire        mul_go      = is_mul && !mul_finished;
wire        mul_done    ;
wire        lhs_signed  = i_mul || i_mulh || i_mulhsu;
wire        rhs_signed  = i_mul || i_mulh;
    
`ifdef RISCV_FORMAL_ALTOPS
// Shorten compute time for riscv-formal mul/div checks.
wire mul_finished = 1'b1;

`else
reg         mul_finished;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        mul_finished <= 1'b0;
    end else if(pipe_progress) begin
        mul_finished <= 1'b0;
    end else if(mul_go && mul_done) begin
        mul_finished <= 1'b1;
    end
end

`endif

// Serial signed/unsigned multiplier
frv_alu_mul_serial
#(
.LEN(32)
) i_mul_serial (
.clk       (g_clk     ),
.resetn    (g_resetn  ),
.lhs       (imul_lhs  ),
.rhs       (imul_rhs  ),
.lhs_signed(lhs_signed),
.rhs_signed(rhs_signed),
.out       (mul_result),
.valid     (mul_go    ),
.done      (mul_done  )
);

//
// Divide Instructions
//

wire        i_div       = imul_valid && imul_div   ;
wire        i_divu      = imul_valid && imul_divu  ;
wire        i_rem       = imul_valid && imul_rem   ;
wire        i_remu      = imul_valid && imul_remu  ;

wire        r_div       = i_div || i_divu;
wire        r_rem       = i_rem || i_remu;

reg         div_run     ;
reg         div_done    ;
reg [4:0]   div_count   ;

wire        is_divrem   = i_div || i_divu || i_rem || i_remu;
wire        signed_lhs  = (i_div || i_rem) && imul_lhs[31];
wire        signed_rhs  = (i_div || i_rem) && imul_rhs[31];

wire        div_start   = is_divrem && !div_run && !div_done;
wire        div_finished= (div_run && div_count == 0) || div_done;

reg  [31:0] quotient    ;
reg  [31:0] dividend    ;
reg  [62:0] divisor     ;
reg         outsign     ;

wire [31:0] qmask       = 32'b1           << div_count;

wire        div_less    = divisor <= {31'b0,dividend};

always @(posedge g_clk) begin
    if(!g_resetn || exu_flush) begin
        
        div_done <= 1'b0;
        div_run  <= 1'b0;
        div_count<= 31;
        dividend <= 0;
        divisor  <= 0;
        quotient <= 0;
        outsign  <= 1'b0;

    end else if(div_done) begin
        
        div_done <= exu_stall;

    end else if(div_start) begin
        
        div_count<= 31;
        div_run  <= 1'b1;
        div_done <= 1'b0;
        dividend <= signed_lhs ? -imul_lhs : imul_lhs;
        divisor  <= (signed_rhs ? -{{31{imul_rhs[31]}},imul_rhs} :
                                    {31'b0,imul_rhs}               ) << 31;
        quotient <= 0;
        outsign  <= (i_div && (imul_lhs[31] != imul_rhs[31]) && |imul_rhs) ||
                    (i_rem && imul_lhs[31]);

    end else if(div_run) begin

        if(div_less) begin
        
            dividend <= dividend - divisor[31:0];
            quotient <= quotient | qmask  ;

        end

        if(div_finished) begin

            div_run  <= 1'b0;
            div_done <= 1'b1;

        end else begin
        
            div_count <= div_count - 1;
            divisor   <= divisor >> 1;

        end

    end
end


//
// Result multiplexing
//

wire [31:0] dividend_out = outsign ? -dividend : dividend;
wire [31:0] quotient_out = outsign ? -quotient : quotient;

`ifdef RISCV_FORMAL_ALTOPS

wire [31:0] mulhsu_fml_result = 
    $signed(imul_lhs) - $signed({1'b0,imul_rhs});

// Alternative computations for riscv-formal framework.
assign imul_result =
    {32{i_mul   }} & ((imul_lhs + imul_rhs) ^ 32'h5876_063e ) |
    {32{i_mulh  }} & ((imul_lhs + imul_rhs) ^ 32'hf658_3fb7 ) |
    {32{i_mulhsu}} & ((mulhsu_fml_result  ) ^ 32'hecfb_e137 ) |
    {32{i_mulhu }} & ((imul_lhs + imul_rhs) ^ 32'h949c_e5e8 ) |
    {32{i_div   }} & ((imul_lhs - imul_rhs) ^ 32'h7f85_29ec ) |
    {32{i_divu  }} & ((imul_lhs - imul_rhs) ^ 32'h10e8_fd70 ) |
    {32{i_rem   }} & ((imul_lhs - imul_rhs) ^ 32'h8da6_8fa5 ) |
    {32{i_remu  }} & ((imul_lhs - imul_rhs) ^ 32'h3138_d0e1 ) ;

assign imul_ready  = (is_mul && mul_finished) || (is_divrem );

`else

assign imul_result =
    {32{r_rem }} & dividend_out         |
    {32{r_div }} & quotient_out         |
    {32{mul_hi}} & mul_result[63:32]    |
    {32{i_mul }} & mul_result[31: 0]    ;

assign imul_ready  = (is_mul && mul_finished) || (is_divrem && (div_done));

`endif

endmodule
