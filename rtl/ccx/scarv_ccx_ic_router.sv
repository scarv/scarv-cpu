
//
// module: scarv_ccx_ic_router
//
//  Core complex interconnect router.
//  - Routes requests from the CPU to the RAM/ROM/EXT memory ports.
//
module scarv_ccx_ic_router #(
parameter   AW          = 32           ,    // Address width
parameter   DW          = 32           ,    // Data width
parameter   NDEVICES    = 4            ,    // Number of devices. Upto 4.
parameter   D0_BASE     = 32'h0000_0000,
parameter   D0_SIZE     = 32'h0000_0400,
parameter   D1_BASE     = 32'h0001_0000,
parameter   D1_SIZE     = 32'h0001_0000,
parameter   D2_BASE     = 32'h0002_0000,
parameter   D2_SIZE     = 32'h0000_0100,
parameter   D3_BASE     = 32'h1000_0000,
parameter   D3_SIZE     = 32'h1000_0000 
)(

input  wire      g_clk      ,
input  wire      g_resetn   ,

scarv_ccx_memif.RSP if_core , // CPU requestor

scarv_ccx_memif.REQ if_d0   ,
scarv_ccx_memif.REQ if_d1   ,
scarv_ccx_memif.REQ if_d2   ,
scarv_ccx_memif.REQ if_d3

);

//
// Parameters
// ------------------------------------------------------------

localparam  D0_MASK  = D0_SIZE - 1;
localparam  D1_MASK  = D1_SIZE - 1;
localparam  D2_MASK  = D2_SIZE - 1;
localparam  D3_MASK  = D3_SIZE - 1;

//
// Utility functions
// ------------------------------------------------------------

//
// Function to check if an address matches a particular peripheral
//
function [0:0] address_match (
input [AW-1:0] address  ,   // The address to match
input [AW-1:0] mask     ,   // Mask bits to match top addr bits with
input [AW-1:0] base     ,   // Base address of the range
input [AW-1:0] range        // Size of the range.
);
    address_match = (address |  base) == (address            ) &&
                    (address & ~mask) == (base               )  ;
endfunction


//
// Which addresses match which peripherals?
// ------------------------------------------------------------

wire map_core_d0 = NDEVICES>=1 && address_match(if_core.addr,D0_MASK,D0_BASE,D0_SIZE);
wire map_core_d1 = NDEVICES>=2 && address_match(if_core.addr,D1_MASK,D1_BASE,D1_SIZE);
wire map_core_d2 = NDEVICES>=3 && address_match(if_core.addr,D2_MASK,D2_BASE,D2_SIZE);
wire map_core_d3 = NDEVICES>=4 && address_match(if_core.addr,D3_MASK,D3_BASE,D3_SIZE);

wire map_core_none= !map_core_d0  && 
                    !map_core_d1  &&
                    !map_core_d2  &&
                    !map_core_d3  ;


// Check the mappings are sensible.
always @(posedge g_clk) begin

    // TODO
    
end


//
// Route request wires
// ------------------------------------------------------------

//
// Always assigned wires.

`define IF_ASSIGN(RSP, REQ)                 \
assign  RSP.addr     = REQ.addr    ;        \
assign  RSP.wen      = REQ.wen     ;        \
assign  RSP.strb     = REQ.strb    ;        \
assign  RSP.wdata    = REQ.wdata   ;        \

`IF_ASSIGN(if_d0,if_core)
`IF_ASSIGN(if_d1,if_core)
`IF_ASSIGN(if_d2,if_core)
`IF_ASSIGN(if_d3,if_core)

`undef  IF_ASSIGN

// Request lines masked by mapping lines.
assign  if_d0.req    = if_core.req && map_core_d0;
assign  if_d1.req    = if_core.req && map_core_d1;
assign  if_d2.req    = if_core.req && map_core_d2;
assign  if_d3.req    = if_core.req && map_core_d3;

//
// Request/Response Tracking.
// ------------------------------------------------------------

reg    rsp_route_d0  ;
reg    rsp_route_d1  ;
reg    rsp_route_d2  ;
reg    rsp_route_d3  ;
reg    rsp_route_none;

wire n_rsp_route_d0  = if_d0.req     && if_core.gnt;
wire n_rsp_route_d1  = if_d1.req     && if_core.gnt;
wire n_rsp_route_d2  = if_d2.req     && if_core.gnt;
wire n_rsp_route_d3  = if_d3.req     && if_core.gnt;
wire n_rsp_route_none= map_core_none && if_core.gnt;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        rsp_route_d0   <= 1'b0;
        rsp_route_d1   <= 1'b0;
        rsp_route_d2   <= 1'b0;
        rsp_route_d3   <= 1'b0;
        rsp_route_none <= 1'b0;
    end else begin
        rsp_route_d0   <= n_rsp_route_d0 ;
        rsp_route_d1   <= n_rsp_route_d1 ;
        rsp_route_d2   <= n_rsp_route_d2 ;
        rsp_route_d3   <= n_rsp_route_d3;
        rsp_route_none <= n_rsp_route_none;
    end
end

//
// Response Routing.
// ------------------------------------------------------------

assign if_core.gnt  = map_core_d0  ? if_d0.gnt   :
                      map_core_d1  ? if_d1.gnt   :
                      map_core_d2  ? if_d2.gnt   :
                      map_core_d3  ? if_d3.gnt   :
                                     1'b1        ;

assign if_core.error= rsp_route_d0 ? if_d0.error :
                      rsp_route_d1 ? if_d1.error :
                      rsp_route_d2 ? if_d2.error :
                      rsp_route_d3 ? if_d3.error :
                                       1'b1      ;

assign if_core.rdata= rsp_route_d0 ? if_d0.rdata :
                      rsp_route_d1 ? if_d1.rdata :
                      rsp_route_d2 ? if_d2.rdata :
                      rsp_route_d3 ? if_d3.rdata :
                                    {DW{1'b0}}   ;

endmodule




