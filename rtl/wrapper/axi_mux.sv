
//
// module: frv_axi_mux
//
//  A multiplexing interconnect for AXI busses. Allows two AXI
//  masters to access the same slave.
//
module frv_axi_mux(

// Clock/reset
input  wire        m0_aclk     ,
input  wire        m0_aresetn  ,
input  wire        s0_aclk     ,
input  wire        s0_aresetn  ,
input  wire        s1_aclk     ,
input  wire        s1_aresetn  ,

// AXI4 master interface
output wire        m0_awvalid  ,
output wire [ 7:0] m0_awlen    ,
output wire [ 2:0] m0_awsize   ,
output wire [ 1:0] m0_awburst  ,
output wire        m0_awlock   ,
output wire [ 3:0] m0_awcache  ,
output wire        m0_awid     ,
output wire [31:0] m0_awaddr   ,
output wire [ 2:0] m0_awprot   ,
input  wire        m0_awready  ,

output wire        m0_wvalid   ,
output wire [31:0] m0_wdata    ,
output wire [ 3:0] m0_wstrb    ,
input  wire        m0_wready   ,

output wire        m0_bready   ,
input  wire        m0_bvalid   ,
input  wire        m0_bid      ,
input  wire [ 1:0] m0_bresp    ,

output wire        m0_arvalid  ,
output wire        m0_arid     ,
output wire [31:0] m0_araddr   ,
output wire [ 2:0] m0_arprot   ,
input  wire        m0_arready  ,

output wire        m0_rready   ,
input  wire        m0_rvalid   ,
input  wire        m0_rid      ,
input  wire [31:0] m0_rdata    ,
input  wire [ 1:0] m0_rresp    ,

//
// AXI4 Slave interface 0
input  wire        s0_awvalid  ,
input  wire        s0_awid     ,
input  wire [31:0] s0_awaddr   ,
input  wire [ 2:0] s0_awprot   ,
output wire        s0_awready  ,

input  wire        s0_wvalid   ,
input  wire [31:0] s0_wdata    ,
input  wire [ 3:0] s0_wstrb    ,
output wire        s0_wready   ,

output wire        s0_bvalid   ,
output wire        s0_bid      ,
input  wire        s0_bready   ,
output wire [ 1:0] s0_bresp    ,

input  wire        s0_arvalid  ,
input  wire        s0_arid     ,
output wire        s0_arready  ,
input  wire [31:0] s0_araddr   ,
input  wire [ 2:0] s0_arprot   ,

output wire        s0_rvalid   ,
output wire        s0_rid      ,
input  wire        s0_rready   ,
output wire [31:0] s0_rdata    ,
output wire [ 1:0] s0_rresp    ,


//
// AXI4 Slave interface 1
input  wire        s1_awvalid  ,
input  wire        s1_awid     ,
output wire        s1_awready  ,
input  wire [31:0] s1_awaddr   ,
input  wire [ 2:0] s1_awprot   ,

input  wire        s1_wvalid   ,
output wire        s1_wready   ,
input  wire [31:0] s1_wdata    ,
input  wire [ 3:0] s1_wstrb    ,

output wire        s1_bvalid   ,
output wire        s1_bid      ,
input  wire        s1_bready   ,
output wire [ 1:0] s1_bresp    ,

input  wire        s1_arvalid  ,
input  wire        s1_arid     ,
output wire        s1_arready  ,
input  wire [31:0] s1_araddr   ,
input  wire [ 2:0] s1_arprot   ,

output wire        s1_rvalid   ,
output wire        s1_rid      ,
input  wire        s1_rready   ,
output wire [31:0] s1_rdata    ,
output wire [ 1:0] s1_rresp    

);

parameter  ID_WIDTH = 0             ;
localparam I1       = ID_WIDTH + 1  ;
localparam I0       = ID_WIDTH      ;

//
// AW channel

assign m0_awvalid = s0_awvalid || s1_awvalid;
assign m0_awid    = s1_awvalid;
assign m0_awaddr  = s0_awvalid ? s0_awaddr : s1_awaddr ;
assign m0_awprot  = s0_awvalid ? s0_awprot : s1_awprot ;

assign m0_awlen   = 0;
assign m0_awsize  = 3'b010;
assign m0_awburst = 2'b00;
assign m0_awlock  = 1'b0;
assign m0_awcache = 4'b0000;

assign s0_awready = s0_awvalid ? m0_awready : 1'b0      ;
assign s1_awready = s0_awvalid ? 1'b0       : m0_awready;

//
// AR channel

assign m0_arvalid = s0_arvalid || s1_arvalid;
assign m0_arid    = s1_arvalid;
assign m0_araddr  = s0_arvalid ? s0_araddr : s1_araddr ;
assign m0_arprot  = s0_arvalid ? s0_arprot : s1_arprot ;

assign s0_arready = s0_arvalid ? m0_arready : 1'b0      ;
assign s1_arready = s0_arvalid ? 1'b0       : m0_arready;

//
// W channel

assign m0_wvalid = s0_wvalid || s1_wvalid;
assign m0_wdata  = s0_wvalid ? s0_wdata : s1_wdata ;
assign m0_wstrb  = s0_wstrb  ? s0_wstrb : s1_wstrb ;

assign s0_wready = s0_wvalid ? m0_wready : 1'b0      ;
assign s1_wready = s0_wvalid ? 1'b0       : m0_wready;

//
// B channel

wire   b_chansel = m0_bid;

assign s0_bvalid = !b_chansel;
assign s0_bid    = m0_bid;
assign s0_bresp  = m0_bresp;

assign s1_bvalid = !b_chansel;
assign s1_bid    = m0_bid;
assign s1_bresp  = m0_bresp;

assign m0_bready = b_chansel ? s1_bready : s0_bready;

//
// R channel

wire   r_chansel = m0_rid;

assign s0_rvalid = !b_chansel;
assign s0_rid    = m0_rid;
assign s0_rresp  = m0_rresp ;
assign s0_rdata  = m0_rdata;

assign s1_rvalid = !r_chansel;
assign s1_rid    = m0_rid;
assign s1_rresp  = m0_rresp;
assign s1_rdata  = m0_rdata;

assign m0_rready = r_chansel ? s1_rready : s0_rready;

endmodule

