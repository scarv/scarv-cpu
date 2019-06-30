
//
// module: sram_axi_adapter
//
// Module adapted from The picoRV32 AXI adapter to allow
// back to back read/write address channel requests and bus fault
// propagation.
//
module sram_axi_adapter (
input        g_clk              ,
input        g_resetn           ,

// AXI4-lite master memory interface

output        mem_axi_awvalid   ,
input         mem_axi_awready   ,
output [31:0] mem_axi_awaddr    ,
output [ 2:0] mem_axi_awprot    ,

output        mem_axi_wvalid    ,
input         mem_axi_wready    ,
output [31:0] mem_axi_wdata     ,
output [ 3:0] mem_axi_wstrb     ,

input         mem_axi_bvalid    ,
output        mem_axi_bready    ,

output        mem_axi_arvalid   ,
input         mem_axi_arready   ,
output [31:0] mem_axi_araddr    ,
output [ 2:0] mem_axi_arprot    ,

input         mem_axi_rvalid    ,
output        mem_axi_rready    ,
input  [31:0] mem_axi_rdata     ,

input         mem_instr         , // Is this an instruction fetch?
input         mem_cen           ,
output        mem_stall         ,
output        mem_error         ,
input  [31:0] mem_addr          ,
input  [31:0] mem_wdata         ,
input  [ 3:0] mem_wstrb         ,
output [31:0] mem_rdata
);
	reg ack_awvalid;
	reg ack_arvalid;
	reg ack_wvalid;
	reg xfer_done;

	assign mem_axi_awvalid = mem_cen && |mem_wstrb;
	assign mem_axi_awaddr = mem_addr;
	assign mem_axi_awprot = 0;

	assign mem_axi_arvalid = mem_cen && !mem_wstrb;
	assign mem_axi_araddr = mem_addr;
	assign mem_axi_arprot = mem_instr ? 3'b100 : 3'b000;

	assign mem_axi_wvalid = mem_cen && |mem_wstrb && !ack_wvalid;
	assign mem_axi_wdata = mem_wdata;
	assign mem_axi_wstrb = mem_wstrb;

	wire   mem_ready = mem_axi_bvalid || mem_axi_rvalid;
    assign mem_stall = !mem_ready;
	assign mem_axi_bready = mem_cen && |mem_wstrb;
    // Always accept read responses immediately.
	assign mem_axi_rready = 1'b1;
	assign mem_rdata = mem_axi_rdata;
    
    // TODO: implement this.
    assign mem_error = 1'b0;

	always @(posedge g_clk) begin
		if (!g_resetn) begin
			ack_awvalid <= 0;
		end else begin
			xfer_done <= mem_cen && mem_ready;
			if (mem_axi_awready && mem_axi_awvalid)
				ack_awvalid <= 1;
			if (mem_axi_arready && mem_axi_arvalid)
				ack_arvalid <= 1;
			if (mem_axi_wready && mem_axi_wvalid)
				ack_wvalid <= 1;
			if (xfer_done || !mem_cen) begin
				ack_awvalid <= 0;
				ack_arvalid <= 0;
				ack_wvalid <= 0;
			end
		end
	end
endmodule
