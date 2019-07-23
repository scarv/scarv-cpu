
//
// module: frv_alu_mul_serial
//
//  A serial multiplier for signed and unsigned inputs.
//
module frv_alu_mul_serial (

input  wire [ 0:0] clk      ,
input  wire [ 0:0] resetn   ,

input  wire [LI:0] lhs      ,
input  wire [LI:0] rhs      ,

input  wire [ 0:0] lhs_signed,
input  wire [ 0:0] rhs_signed,

output reg  [LO:0] out      ,

input  wire [ 0:0] valid    ,
output wire [ 0:0] done 

);

parameter   LEN         =           4;
localparam  LI          =    LEN  - 1;
localparam  LO          = (2*LEN) - 1;
localparam  CL          = $clog2(LEN);


// Same process as for unsigned numbers.
wire case_p_p = !lhs[LI] && !rhs[LI];
// Same process as unsigned numbers, but subtract last multiplicand
wire case_p_n = !lhs[LI] &&  rhs[LI];
// negative multiplicand, positive muliplier.
wire case_n_p =  lhs[LI] && !rhs[LI];
// negative multiplicand and multiplier.
wire case_n_n =  lhs[LI] &&  rhs[LI];

reg          en         ;
wire         n_en       = valid && !done;

reg  [ CL:0] count      ; 
wire [ CL:0] n_count    = count+1; 

wire         add_en     = rhs[count[CL-1:0]];

wire         sublast    = rhs[LI] && n_count == LEN && rhs_signed;

wire [LEN:0] add_lhs    = {lhs_signed && out[LO],out[LO:LEN]};
wire [LEN:0] add_rhs    = {LEN+1{add_en}} & {lhs_signed && lhs[LI],lhs};
wire [LEN:0] add_rhs1   = sublast ? ~add_rhs : add_rhs;
wire [LEN:0] add_out    = add_lhs + add_rhs1 + {{LEN{1'b0}}, sublast};

wire [ LO:0] n_out      = {add_out, out[LI:1]};

assign       done       = valid && count == LEN;

//
// Accumulator register updating
always @(posedge clk) begin
    if(!resetn) begin
        out <= 0;
    end else if(valid && !en) begin
        out <= 0;
    end else if(valid && n_en) begin
        out <= n_out;
    end
end


//
// Counter incrementing
always @(posedge clk) begin
    if(!resetn) begin
        count <= 0;
    end else if(valid && !en) begin
        count <= 0;
    end else if(valid && en) begin
        count <= done ? 0 : n_count;
    end
end

//
// Enable bit
always @(posedge clk) begin
    if(!resetn) begin
        en  <= 1'b0;
    end else begin
        en  <= n_en;
    end
end

endmodule
