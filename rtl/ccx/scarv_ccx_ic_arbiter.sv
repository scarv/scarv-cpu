
//
// module: scarv_ccx_ic_arbiter
//
//  Core complex interconnect arbiter.
//  - Arbitrates two requestors onto a single a requestor.
//  - Port 0 has priority.
//
module scarv_ccx_ic_arbiter (

input  wire      g_clk      ,
input  wire      g_resetn   ,

scarv_ccx_memif.RSP req_0   , // Requestor 0 (primary)
scarv_ccx_memif.RSP req_1   , // Requestor 1 (primary)

scarv_ccx_memif.REQ rsp       // Responder   (secondary)

);

reg    inflight_r1  ;
wire n_inflight_r1  = inflight_r1 ? req_1.req && !req_1.gnt               :
                                    req_1.req && !req_1.gnt && !req_0.req ;

wire route_req_r0   = req_0.req && !inflight_r1;
wire route_req_r1   = req_1.req && !req_0.req  ;

reg  route_rsp_0    ;
reg  route_rsp_1    ;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        inflight_r1  <= 1'b0;
        route_rsp_0  <= 1'b0;
        route_rsp_1  <= 1'b0;
    end else begin
        inflight_r1  <= n_inflight_r1;
        route_rsp_0  <= route_req_r0;
        route_rsp_1  <= route_req_r1;
    end
end

assign rsp.req      = route_req_r0 ? req_0.req   : req_1.req   ;
//assign rsp.rtype    = route_req_r0 ? req_0.rtype : req_1.rtype ;
assign rsp.addr     = route_req_r0 ? req_0.addr  : req_1.addr  ;
assign rsp.wen      = route_req_r0 ? req_0.wen   : req_1.wen   ;
assign rsp.strb     = route_req_r0 ? req_0.strb  : req_1.strb  ;
assign rsp.wdata    = route_req_r0 ? req_0.wdata : req_1.wdata ;
//assign rsp.prv      = route_req_r0 ? req_0.prv   : req_1.prv   ;

assign req_0.gnt    = route_req_r0 && rsp.gnt;
assign req_1.gnt    = route_req_r1 && rsp.gnt;

assign req_0.error  = route_rsp_0  && rsp.error;
assign req_0.rdata  = rsp.rdata;

assign req_1.error  = route_rsp_1 && rsp.error;
assign req_1.rdata  = rsp.rdata;

endmodule




