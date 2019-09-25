
//
// module: frv_bram_adapter
//
//  Bridge to transform the two request/response channels of the
//  FRV core into a simple BRAM interface.
//
module frv_bram_adapter (
input        g_clk                  ,
input        g_resetn               ,

output wire         bram_cen        ,
output wire  [31:0] bram_addr       ,
output wire  [31:0] bram_wdata      ,
output wire  [ 3:0] bram_wstrb      ,
input  wire         bram_stall      ,
input  wire  [31:0] bram_rdata      ,

input  wire         enable          , // Enable requests / does addr map?

input  wire         mem_req         , // Start memory request
output wire         mem_gnt         , // request accepted
input  wire         mem_wen         , // Write enable
input  wire [3:0]   mem_strb        , // Write strobe
input  wire [31:0]  mem_wdata       , // Write data
input  wire [31:0]  mem_addr        , // Read/Write address

output reg          mem_recv        , // Instruction memory recieve response.
input  wire         mem_ack         , // Instruction memory ack response.
output wire         mem_error       , // Error
output wire [31:0]  mem_rdata         // Read data
);

assign mem_rdata    = bram_rdata;

assign mem_error    = 1'b0;
assign mem_gnt      = (!mem_recv || (mem_recv && mem_ack)) && !bram_stall;
assign mem_error    = 1'b0;

assign bram_addr    = enable  ? mem_addr : 32'b0    ;
assign bram_wdata   = mem_wdata;
assign bram_wstrb   = mem_wen ? mem_strb : 4'b0000  ;
assign bram_cen     = mem_req && enable;

wire   n_mem_recv   = (bram_cen && !bram_stall) || (mem_recv && !mem_ack);

always @(posedge g_clk) begin
    if(!g_resetn) begin
        mem_recv = 1'b0;
    end else begin
        mem_recv = n_mem_recv;
    end
end

endmodule
