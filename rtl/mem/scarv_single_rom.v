
module scarv_single_rom #(
parameter   DEPTH = 1024    ,   // Depth of ROM in words
parameter   WIDTH = 32      ,   // Width of a ROM word.
parameter [255*8-1:0] INIT_FILE="" // Memory initialisaton file.
)(
input  wire         g_clk       ,
input  wire         g_resetn    ,

input  wire         a_cen       , // Start memory request
input  wire [AW: 0] a_addr      , // Read/Write address
output reg  [DW: 0] a_rdata       // Read data

);

// Write strobe width.
localparam SW = (WIDTH / 8) - 1;

// Address lines width.
localparam AW = $clog2(DEPTH) - 1;

// Data line width
localparam DW = WIDTH - 1;

endmodule

