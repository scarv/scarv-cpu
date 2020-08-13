
//
// interface: scarv_ccx_memif
//
//  SystemVerilog interface representing the memory request/response
//  bus used by the scarv-cpu and ccx.
//
interface scarv_ccx_memif #(
parameter AW = 32, DW=32
)();

localparam SW       = (DW/8) - 1;

logic           req   ; // Start memory request
logic           wen   ; // Write enable
logic [SW  :0]  strb  ; // Write strobe
logic [DW-1:0]  wdata ; // Write data
logic [AW-1:0]  addr  ; // Read/Write address
logic           gnt   ; // request accepted
logic           error ; // Error
logic [DW-1:0]  rdata ; // Read data

modport REQ (
output req   , // Start memory request
output wen   , // Write enable
output strb  , // Write strobe
output wdata , // Write data
output addr  , // Read/Write address
input  gnt   , // request accepted
input  error , // Error
input  rdata   // Read data
);

modport RSP (
input  req   , // Start memory request
input  wen   , // Write enable
input  strb  , // Write strobe
input  wdata , // Write data
input  addr  , // Read/Write address
output gnt   , // request accepted
output error , // Error
output rdata   // Read data
);

endinterface
