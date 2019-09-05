
//
// module: fsbl_rom
//
//  A read only SRAM module containing the FSBL program
//
module fsbl_rom (
    
input   wire          clk       ,
input   wire          reset     ,

input   wire          mem_cen   ,
input   wire  [11:0]  mem_addr  ,
input   wire  [31:0]  mem_wdata ,
input   wire  [ 3:0]  mem_wstrb ,
output  reg   [31:0]  mem_rdata 

);

parameter MEMFILE = "fsbl.hex";

wire [7:0] idx = {mem_addr[7:2],2'b00};

reg [7:0] romdata [255:0]; 

initial begin
    $display("LOAD MEM FILE", MEMFILE);
    $readmemh(MEMFILE,romdata);
end

always @(posedge clk) begin
    if(reset) begin
        mem_rdata <= 0;
    end else if(mem_cen) begin
        mem_rdata[ 7: 0] = romdata[idx + 0];
        mem_rdata[15: 8] = romdata[idx + 1];
        mem_rdata[23:16] = romdata[idx + 2];
        mem_rdata[31:24] = romdata[idx + 3];
    end
end

endmodule
