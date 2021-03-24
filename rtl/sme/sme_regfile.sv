
//
// module: sme_regfile
//
//  A single 16-entry register file used by SME to store shares.
//  The regfile _does not_ do forwarding of write values to read ports.
//
module sme_regfile #(
parameter XLEN=32
)(
input         g_clk      , // Global clock
output wire   g_clk_req  , // Global clock request
input         g_resetn   , // Sychronous active low reset.

input  [ 3:0] rs1_addr   , // Source register 1 address
output [XL:0] rs1_rdata  , // Source register 1 read data

input  [ 3:0] rs2_addr   , // Source register 2 address
output [XL:0] rs2_rdata  , // Source register 2 read data

input         rd_wen     , // Write enable
input  [ 3:0] rd_addr    , // Write address
input  [XL:0] rd_wdata     // Write data

);

parameter XL    = XLEN - 1;


// The register storage.
logic [XL:0] regs [15:0];

// Only request a clock when we are doing a register write.
assign g_clk_req    = rd_wen;

// Register reads.
assign rs1_rdata = regs[rs1_addr];
assign rs2_rdata = regs[rs2_addr];

// Register writes.
always @(posedge g_clk) if(rd_wen) begin
    regs[rd_addr] <= rd_wdata;
end

endmodule

