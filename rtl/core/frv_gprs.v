
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

input  wire [ 4:0]  rs2_addr, // Source register 2 address
output wire [31:0]  rs2_data, // Source register 2 read data

input  wire [ 4:0]  rs3_addr, // Source register 3 address
output wire [31:0]  rs3_data, // Source register 3 read data

input  wire         rd_wen  , // Destination register write enable
input  wire [ 4:0]  rd_addr , // Destination register address
input  wire [31:0]  rd_data   // Destination register write data

);

// Use an FPGA BRAM style register file.
parameter BRAM_REGFILE = 0;

generate begin if(BRAM_REGFILE) begin

    //
    // BRAM inference friendly register file implementation.

    reg [31:0] gpr1 [31:0];
    reg [31:0] gpr2 [31:0];
    reg [31:0] gpr3 [31:0];

    wire [31:0] z_rs1 = {32{rs1_addr != 0}};
    wire [31:0] z_rs2 = {32{rs2_addr != 0}};
    wire [31:0] z_rs3 = {32{rs2_addr != 0}};

    assign rs1_data = z_rs1 & gpr1[rs1_addr];
    assign rs2_data = z_rs2 & gpr2[rs2_addr];
    assign rs3_data = z_rs3 & gpr3[rs3_addr];

    always @(posedge g_clk) begin
        if(rd_wen) begin
            gpr1[rd_addr] <= rd_data;
        end
    end

    always @(posedge g_clk) begin
        if(rd_wen) begin
            gpr2[rd_addr] <= rd_data;
        end
    end

    always @(posedge g_clk) begin
        if(rd_wen) begin
            gpr3[rd_addr] <= rd_data;
        end
    end

end else begin // BRAM_REGFILE = 0

    //
    // Standard register file implementation.

    reg  [31:0] gprs [31:0];

    assign rs1_data = gprs[rs1_addr];
    assign rs2_data = gprs[rs2_addr];
    assign rs3_data = gprs[rs3_addr];

    genvar i;

    for(i = 0; i < 32; i = i + 1) begin
        if(i == 0) begin
            
            always @(*) begin
                gprs[i] = 0;
            end

        end else begin

            always @(posedge g_clk) begin
                if(!g_resetn) begin
                    gprs[i] <= 0;
                end else if(rd_wen && rd_addr == i) begin
                    gprs[i] <= rd_data;
                end
            end

        end
    end 

end end endgenerate

endmodule
