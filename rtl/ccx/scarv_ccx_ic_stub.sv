
//
// module: scarv_ccx_ic_stub
//
//  Interconnect stub. Attatched to router ports which are not mapped for
//  a given requesting interface.
//
//  It *always* returns an error response to every request.
//
module scarv_ccx_ic_stub (

scarv_ccx_memif.RSP memif

);

assign memif.gnt    = 1'b1;
assign memif.error  = 1'b1;
assign memif.rdata  = 32'b0;

endmodule
