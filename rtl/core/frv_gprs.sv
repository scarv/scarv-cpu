
//
// module: frv_gprs
//
//  General purpose registers
//
module frv_gprs #(
parameter XLEN          = 32,
parameter BRAM_REGFILE  =  1
)(

input  wire             g_clk   , //
input  wire             g_resetn, //

input  wire [     4:0]  rs1_addr, // Source register 1 address
output wire [XLEN-1:0]  rs1_data, // Source register 1 read data

input  wire [     4:0]  rs2_addr, // Source register 2 address
output wire [XLEN-1:0]  rs2_data, // Source register 2 read data

input  wire            rd_wen   , // Destination write enable
input  wire [     4:0] rd_addr  , // Destination address
input  wire [XLEN-1:0] rd_wdata   // Destination write data [31:0]

);

localparam XL = XLEN-1;

generate if (BRAM_REGFILE) begin : fpga_regfile // Use DMEM based regfile.

    reg  [XL:0] regs  [31:0];

    assign  rs1_data    = |rs1_addr ? regs[rs1_addr] : {XLEN{1'b0}};
    assign  rs2_data    = |rs2_addr ? regs[rs2_addr] : {XLEN{1'b0}};


    always @(posedge g_clk) begin
        if(rd_wen && |rd_addr) begin
            regs[rd_addr] <= rd_wdata;
        end
    end

end else begin : ff_regfile                     // Use FF based regfile

    wire [XL:0] regs[31:0];

    assign  rs1_data    = regs[rs1_addr];
    assign  rs2_data    = regs[rs2_addr];
    
    assign regs[0]      = 0;

    genvar i;
    for(i = 1; i < 32; i = i + 1) begin

        reg [XL:0] r;

        assign regs[i] = r;

        always @(posedge g_clk) begin
            if(rd_wen && (rd_addr == i)) begin
                r <= rd_wdata;
            end
        end

    end

end endgenerate

endmodule
