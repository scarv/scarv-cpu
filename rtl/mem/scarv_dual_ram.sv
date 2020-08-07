
module scarv_dual_ram #(
parameter   DEPTH = 4096    ,   // Depth of RAM in words
parameter   WIDTH = 32          // Width of a RAM word.
)(
input  wire         g_clk       ,
input  wire         g_resetn    ,

input  wire         a_cen       , // Start memory request
input  wire         a_wen       , // Write enable
input  wire [SW: 0] a_strb      , // Write strobe
input  wire [DW: 0] a_wdata     , // Write data
input  wire [AW: 0] a_addr      , // Read/Write address
output reg  [DW: 0] a_rdata     , // Read data

input  wire         b_cen       , // Start memory request
input  wire         b_wen       , // Write enable
input  wire [SW: 0] b_strb      , // Write strobe
input  wire [DW: 0] b_wdata     , // Write data
input  wire [AW: 0] b_addr      , // Read/Write address
output reg  [DW: 0] b_rdata       // Read data

);

// Write strobe width.
localparam SW = (WIDTH / 8) - 1;

// Address lines width.
localparam AW = $clog2(DEPTH) - 1;

// Data line width
localparam DW = WIDTH - 1;

endmodule
