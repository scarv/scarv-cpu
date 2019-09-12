
module flushable_bram (

input  wire         clka        ,
input  wire         rsta        ,
input  wire         ena         ,
input  wire [ 3:0]  wea         ,
input  wire [14:0]  addra       ,
input  wire [31:0]  dina        ,
output reg  [31:0]  douta       ,

input  wire         flush_rand  ,
input  wire [31:0]  flush_data  ,

output wire         rsta_busy    

);

//! Depth of the BRAM in *words*, where 1 word = 4 bytes.
parameter   DEPTH = 8192;
localparam  LW    = $clog2(DEPTH);

assign rsta_busy = 1'b0;

reg [7:0] darry_0 [DEPTH-1:0];
reg [7:0] darry_1 [DEPTH-1:0];
reg [7:0] darry_2 [DEPTH-1:0];
reg [7:0] darry_3 [DEPTH-1:0];

wire [LW-1:0] idx_a = addra[LW-1+2:2];

wire [31:0] read_data = {darry_3[idx_a],
                         darry_2[idx_a],
                         darry_1[idx_a],
                         darry_0[idx_a]};

wire is_write = |wea;

// Port a reads / flushes
always @(posedge clka) begin
    if(rsta) begin
        douta <= 0;
    end else if(flush_rand && !ena) begin
        douta <= flush_data;
    end else if(ena && !is_write) begin
        douta <= read_data;
    end
end

//
// Port a writes
always @(posedge clka) if(ena && wea[0]) darry_0[idx_a] <= dina[ 7: 0];
always @(posedge clka) if(ena && wea[1]) darry_1[idx_a] <= dina[15: 8];
always @(posedge clka) if(ena && wea[2]) darry_2[idx_a] <= dina[23:16];
always @(posedge clka) if(ena && wea[3]) darry_3[idx_a] <= dina[31:24];

endmodule
