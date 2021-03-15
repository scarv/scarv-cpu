
module sme_keccak #(
parameter LW    = 8,    // Lane width: 4/8/16/32/64
parameter TAPS  = 1     // TRNG bits mixed with state.
)(
input              g_clk    ,
input              g_resetn ,
input              update   ,
input  [TAPS -1:0] taps     ,
output [LW*25-1:0] state        // Current state
);

reg [LW-1:0]  s [24:0]; // current state
reg [LW-1:0]  C [ 4:0]; // temp
reg [LW-1:0]  D [ 4:0]; // temp 
reg [LW-1:0] ts [24:0]; // state post theta
reg [LW-1:0] rs [24:0]; // state post rho
reg [LW-1:0] ps [24:0]; // state post pi
reg [LW-1:0]  t [24:0]; // temp
reg [LW-1:0] cs [24:0]; // state post chi

`define IDX(x,y) (((x)%5)+5*((y)%5))
`define ROL(x,y) ((x << y) | (x >> (LW-y)))

reg [5:0] offsets [24:0];
assign offsets[ 0] =  0;
assign offsets[ 1] =  1;
assign offsets[ 2] = 62;
assign offsets[ 3] = 28;
assign offsets[ 4] = 27;
assign offsets[ 5] = 36;
assign offsets[ 6] = 44;
assign offsets[ 7] =  6;
assign offsets[ 8] = 55;
assign offsets[ 9] = 20;
assign offsets[10] =  3;
assign offsets[11] = 10;
assign offsets[12] = 43;
assign offsets[13] = 25;
assign offsets[14] = 39;
assign offsets[15] = 41;
assign offsets[16] = 45;
assign offsets[17] = 15;
assign offsets[18] = 21;
assign offsets[19] =  8;
assign offsets[20] = 18;
assign offsets[21] =  2;
assign offsets[22] = 61;
assign offsets[23] = 56;
assign offsets[24] = 14;

always @(*) begin : keccak_next
    integer x;
    integer y;
    
    // Theta
    for(x=0; x<5; x=x+1) begin
        C[x] = 0;
        for(y=0; y<5; y=y+1) begin
            C[x] = C[x] ^ s[`IDX(x,y)];
        end
    end
    for(x=0; x<5; x=x+1) begin
        D[x] = `ROL(C[(x+1)%5], 1) ^ C[(x+4)%5];
    end
    for(x=0; x<5; x=x+1) begin
        for(y=0; y<5; y=y+1) begin
            ts[`IDX(x, y)] = s[`IDX(x,y)] ^ D[x];
        end
    end

    // Rho
    for(x=0; x<5; x=x+1) begin
        for(y=0; y<5; y=y+1) begin
            rs[`IDX(x, y)] = `ROL(ts[`IDX(x, y)], offsets[`IDX(x, y)] % LW);
        end
    end

    // Pi
    for(x=0; x<5; x=x+1)begin
        for(y=0; y<5; y=y+1) begin
            t[`IDX(x, y)] = rs[`IDX(x, y)];
        end
    end
    for(x=0; x<5; x=x+1)begin
        for(y=0; y<5; y=y+1) begin
            ps[`IDX(0*x+1*y, 2*x+3*y)] = t[`IDX(x, y)];
        end
    end

    // Chi
    for(y=0; y<5; y=y+1) begin
        for(x=0; x<5; x=x+1)begin
            C[x] = ps[`IDX(x, y)] ^ ((~ps[`IDX(x+1, y)]) & ps[`IDX(x+2, y)]);
        end
        for(x=0; x<5; x=x+1)begin
            cs[`IDX(x, y)] = C[x];
        end
    end

    // Mix in tap bits instead of round constants.
    for(x = 0; x < TAPS && x < 25 && x<LW; x = x+1) begin
        cs[x][x] = cs[x][x] ^ taps[x];
    end
end

always @(posedge g_clk) begin : keccak_update
    integer i;

    if(!g_resetn) begin

        for(i = 0; i < 25; i=i+1) begin
            s[i] <= i[LW-1:0];
        end

    end else if(update) begin
        
        for(i = 0; i < 25; i=i+1) begin
            s[i] <= cs[i];
        end

    end
end


genvar i, j;
generate
    for(i = 0; i < 25; i=i+1) begin
        assign state[i*LW+:LW] = s[i];
    end
endgenerate

endmodule

