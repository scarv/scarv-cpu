
//
// module: frv_gprs
//
//  General purpose registers
//
module frv_gprs (

input  wire         g_clk   , //
input  wire         g_resetn, //

input  wire [ 4:0]  rs1_addr, // Source register 1 address
output wire [31:0]  rs1_data, // Source register 1 read data
output wire [31:0]  rs1_rdhi, // Source register 1 wide read high 32-bits

input  wire [ 4:0]  rs2_addr, // Source register 2 address
output wire [31:0]  rs2_data, // Source register 2 read data
output wire [31:0]  rs2_rdhi, // Source register 2 wide read high 32-bits

input  wire [ 4:0]  rs3_addr, // Source register 3 address
output wire [31:0]  rs3_data, // Source register 3 read data

input  wire        rd_wen    , // Destination write enable
input  wire        rd_wide   , // Destination wide write
input  wire [ 4:0] rd_addr   , // Destination address
input  wire [31:0] rd_wdata  , // Destination write data [31:0]
input  wire [31:0] rd_wdata_hi  // Destination write data [63:32]

);

// Use an FPGA BRAM style register file.
parameter BRAM_REGFILE = 0;

reg [31:0] gprs_even [15:0];
reg [31:0] gprs_odd  [15:0];

// Used for debugging.
wire [31:0] gprs      [31:0];

wire [31:0] rs1_even = gprs_even[rs1_addr[4:1]];
wire [31:0] rs2_even = gprs_even[rs2_addr[4:1]];
wire [31:0] rs3_even = gprs_even[rs3_addr[4:1]];

wire [31:0] rs1_odd  = gprs_odd [rs1_addr[4:1]];
wire [31:0] rs2_odd  = gprs_odd [rs2_addr[4:1]];
wire [31:0] rs3_odd  = gprs_odd [rs3_addr[4:1]];

assign      rs1_data = rs1_addr[0] ? rs1_odd : rs1_even;
assign      rs2_data = rs2_addr[0] ? rs2_odd : rs2_even;
assign      rs3_data = rs3_addr[0] ? rs3_odd : rs3_even;

assign      rs1_rdhi = rs1_odd;
assign      rs2_rdhi = rs2_odd;

wire        rd_odd   =  rd_addr[0];
wire        rd_even  = !rd_addr[0];

wire [ 3:0] rd_top   =  rd_addr[4:1];

wire        rd_wen_even  = rd_even && rd_wen;
wire        rd_wen_odd   = (rd_odd || rd_wide) && rd_wen;

wire [31:0] rd_wdata_odd = rd_wide ? rd_wdata_hi : rd_wdata;

genvar i ;
generate for(i = 0; i < 16; i = i+1) begin

    if(i == 0) begin

        //
        // Should be always@(*) but causes X-propagation issues
        // in Vivado 2019.2. Rely on optimiser to remove.
        always @(posedge g_clk) begin
            gprs_even[i] <= 0;
        end
        
        assign gprs[2*i+0] = 32'b0;
        assign gprs[2*i+1] = gprs_odd [i];
        
        always @(posedge g_clk) if(rd_wen_odd && rd_top == i) begin

            gprs_odd[i] <= rd_wdata_odd;

        end

    end else begin
        
        assign gprs[2*i+0] = gprs_even[i];
        assign gprs[2*i+1] = gprs_odd [i];

        always @(posedge g_clk) if(rd_wen_even && rd_top == i) begin

            gprs_even[i] <= rd_wdata;

        end

        always @(posedge g_clk) if(rd_wen_odd && rd_top == i) begin

            gprs_odd[i] <= rd_wdata_odd;

        end

    end

end endgenerate

endmodule
