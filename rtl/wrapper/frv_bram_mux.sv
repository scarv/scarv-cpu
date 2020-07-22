
//
// module: frv_bram_mux
//
//  Enables two BRAM interfaces to share one bram.
//
module frv_bram_mux(
output wire         bram_cen        ,
output wire  [31:0] bram_addr       ,
output wire  [31:0] bram_wdata      ,
output wire  [ 3:0] bram_wstrb      ,
input  wire  [31:0] bram_rdata      ,

input  wire         bram0_cen       ,
input  wire  [31:0] bram0_addr      ,
input  wire  [31:0] bram0_wdata     ,
input  wire  [ 3:0] bram0_wstrb     ,
output wire         bram0_stall     ,
output wire  [31:0] bram0_rdata     ,

input  wire         bram1_cen       ,
input  wire  [31:0] bram1_addr      ,
input  wire  [31:0] bram1_wdata     ,
input  wire  [ 3:0] bram1_wstrb     ,
output wire         bram1_stall     ,
output wire  [31:0] bram1_rdata

);

assign bram_cen     = bram1_cen || bram0_cen;
assign bram_addr    = bram1_cen ? bram1_addr  : bram0_addr ;
assign bram_wdata   = bram1_cen ? bram1_wdata : bram0_wdata;
assign bram_wstrb   = bram1_cen ? bram1_wstrb : bram0_wstrb;

assign bram0_rdata  = bram_rdata;
assign bram1_rdata  = bram_rdata;

assign bram0_stall  = bram1_cen;
assign bram1_stall  = 1'b0;

endmodule

