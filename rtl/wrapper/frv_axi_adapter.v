
//
// module: frv_axi_adapter
//
//  Bridge to transform the two request/response channels of the
//  FRV core into the 5 channels of the AXI standard.
//
module frv_axi_adapter (
input        g_clk                  ,
input        g_resetn               ,

// AXI4-lite master memory interface
output wire        mem_axi_awvalid  ,
input  wire        mem_axi_awready  ,
output wire [31:0] mem_axi_awaddr   ,
output wire [ 2:0] mem_axi_awprot   ,

output wire        mem_axi_wvalid   ,
input  wire        mem_axi_wready   ,
output wire [31:0] mem_axi_wdata    ,
output wire [ 3:0] mem_axi_wstrb    ,

input  wire        mem_axi_bvalid   ,
output wire        mem_axi_bready   ,
input  wire [ 1:0] mem_axi_bresp    ,

output wire        mem_axi_arvalid  ,
input  wire        mem_axi_arready  ,
output wire [31:0] mem_axi_araddr   ,
output wire [ 2:0] mem_axi_arprot   ,

input  wire        mem_axi_rvalid   ,
output wire        mem_axi_rready   ,
input  wire [31:0] mem_axi_rdata    ,
input  wire [ 1:0] mem_axi_rresp    ,

output wire         mem_req         , // Start memory request
output wire         mem_wen         , // Write enable
output wire [3:0]   mem_strb        , // Write strobe
output wire [31:0]  mem_wdata       , // Write data
output wire [31:0]  mem_addr        , // Read/Write address
input  wire         mem_gnt         , // request accepted
input  wire         mem_recv        , // Instruction memory recieve response.
output wire         mem_ack         , // Instruction memory ack response.
input  wire         mem_error       , // Error
input  wire [31:0]  mem_rdata         // Read data
);

// Is this an instruction (wrt. data) interface.
parameter INSTR_INTERFACE = 1'b0;

// Give response priority to write responses.
parameter RSP_PRIORITY_WR = 1;

//
// Constant AXI channel assignments.
assign mem_axi_awaddr   = mem_addr;
assign mem_axi_araddr   = mem_addr;
assign mem_axi_wdata    = mem_wdata;
assign mem_axi_wstrb    = mem_strb;

assign mem_axi_awprot   = {INSTR_INTERFACE, 1'b0, 1'b0};
assign mem_axi_arprot   = {INSTR_INTERFACE, 1'b0, 1'b0};


//
// Request channels
// ============================================================

assign mem_gnt = 
    mem_req &&  mem_wen && axi_write_req_done ||
    mem_req && !mem_wen && axi_read_req_done  ;

//
// Write request channels
// ------------------------------------------------------------

wire axi_write_req_done = 
    (aw_done || (mem_axi_awvalid && mem_axi_awready)) &&
    ( w_done || (mem_axi_wvalid  && mem_axi_wready )) ;

//
// AXI AW channel.

reg     aw_done;
wire    n_aw_done = !axi_write_req_done && 
                    (aw_done || (mem_axi_awvalid && mem_axi_awready));

assign mem_axi_awvalid = !aw_done && mem_req && mem_wen;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        aw_done <= 1'b0;
    end else begin
        aw_done <= n_aw_done;
    end
end

//
// AXI W channel.

reg     w_done;
wire    n_w_done = !axi_write_req_done && 
                    (w_done || (mem_axi_wvalid && mem_axi_wready));

assign mem_axi_wvalid = !w_done && mem_req && mem_wen;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        w_done <= 1'b0;
    end else begin
        w_done <= n_w_done;
    end
end


//
// Read request channels
// ------------------------------------------------------------

wire axi_read_req_done = mem_axi_arvalid && mem_axi_arready;

assign mem_axi_arvalid = mem_req && !mem_wen;

//
// Response channels
// ============================================================

wire rsp_b_error = |mem_axi_bresp;
wire rsp_r_error = |mem_axi_rresp;

wire rsp_valid = RSP_PRIORITY_WR ? (mem_axi_bvalid ? 1'b1 :
                                    mem_axi_rvalid ? 1'b1 : 1'b0)
                                 : (mem_axi_rvalid ? 1'b1 :
                                    mem_axi_bvalid ? 1'b1 : 1'b0)
                                 ;

wire rsp_error = RSP_PRIORITY_WR ? (mem_axi_bvalid ? rsp_b_error :
                                    mem_axi_rvalid ? rsp_r_error : 1'b0)
                                 : (mem_axi_rvalid ? rsp_r_error :
                                    mem_axi_bvalid ? rsp_b_error : 1'b0)
                                 ;

// Can't handle simultaneous read/write responses.
assign mem_axi_bready = mem_ack;
assign mem_axi_rready = mem_ack;

assign mem_recv     = rsp_valid;

assign mem_error    = rsp_error;

assign mem_rdata    = mem_axi_rdata;

endmodule
