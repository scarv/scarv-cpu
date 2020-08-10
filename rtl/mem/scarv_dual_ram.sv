
module scarv_dual_ram #(
parameter   DEPTH = 4096    ,   // Depth of RAM in words
parameter   WIDTH = 32      ,   // Width of a RAM word.
parameter [255*8-1:0] INIT_FILE="" // Memory initialisaton file.
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

localparam BYTE_LANES   = WIDTH / 8;
localparam SIZE_BYTES   = BYTE_LANES * DEPTH;
localparam WORD_ADDR_W  = $clog2(DEPTH);
localparam BYTE_ADDR_W  = WORD_ADDR_W + $clog2(BYTE_LANES);
localparam BAW          = BYTE_ADDR_W - 1   ;

// Byte array of memory.
reg [7:0] mem [SIZE_BYTES-1:0];

initial begin
    if(INIT_FILE != 0) begin
        $display("Load RAM Init File: %s", INIT_FILE);
        $readmemh(INIT_FILE, mem);
    end
end

// Byte aligned address.
wire [BAW:0] a_addrin = {a_addr, {$clog2(BYTE_LANES){1'b0}}};

// Byte aligned address.
wire [BAW:0] b_addrin = {b_addr, {$clog2(BYTE_LANES){1'b0}}};


genvar i;
generate for (i = 0; i < BYTE_LANES; i = i + 1) begin

    wire [BAW:0] idx = i;

    //
    // Reads - Port A
    always @(posedge g_clk) begin
        if(a_cen) begin
            a_rdata[8*i+:8] <= mem[a_addrin | idx];
        end
    end
    
    //
    // Reads - Port B
    always @(posedge g_clk) begin
        if(b_cen) begin
            b_rdata[8*i+:8] <= mem[b_addrin | idx];
        end
    end

    //
    // Writes - Port A
    always @(posedge g_clk) begin
        if(a_cen && a_wen && a_strb[i]) begin
            mem[a_addrin | idx] <= a_wdata[8*i+:8];
        end
    end
    
    //
    // Writes - Port B
    always @(posedge g_clk) begin
        if(b_cen && b_wen && b_strb[i]) begin
            mem[b_addrin | idx] <= b_wdata[8*i+:8];
        end
    end

end endgenerate

endmodule
