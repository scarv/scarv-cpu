
module scarv_single_rom #(
parameter   DEPTH = 1024    ,   // Depth of ROM in words
parameter   WIDTH = 32      ,   // Width of a ROM word.
parameter INIT_FILE="" // Memory initialisaton file.
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

localparam BYTE_LANES   = WIDTH / 8;
localparam SIZE_BYTES   = BYTE_LANES * DEPTH;
localparam WORD_ADDR_W  = $clog2(DEPTH);
localparam BYTE_ADDR_W  = WORD_ADDR_W + $clog2(BYTE_LANES);

localparam BAW          = BYTE_ADDR_W - 1   ;

// Byte array of memory.
reg [7:0] mem [SIZE_BYTES-1:0];

// Byte aligned address.
wire [BAW:0] addrin = {a_addr, {$clog2(BYTE_LANES){1'b0}}};

initial begin
    if(INIT_FILE != 0) begin
        $display("Load ROM Init File: %s", INIT_FILE);
        $readmemh(INIT_FILE, mem);
    end
end

genvar i;
generate for (i = 0; i < BYTE_LANES; i = i + 1) begin

    wire [BAW:0] idx = i;

    //
    // Reads
    always @(posedge g_clk) begin
        if(a_cen) begin
            a_rdata[8*i+:8] <= mem[addrin | idx];
        end
    end

end endgenerate

endmodule

