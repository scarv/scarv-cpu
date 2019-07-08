
//
// module: frv_pipeline_fetch
//
//  Fetch pipeline stage.
//
module frv_pipeline_fetch (

input               g_clk           , // global clock
input               g_resetn        , // synchronous reset

input  wire         cf_req          , // Control flow change
input  wire [XL:0]  cf_target       , // Control flow change target
output wire         cf_ack          , // Acknowledge control flow change

output reg          imem_cen        , // Chip enable
output wire         imem_wen        , // Write enable
input  wire         imem_error      , // Error
input  wire         imem_stall      , // Memory stall
output wire [3:0]   imem_strb       , // Write strobe
output reg  [XL:0]  imem_addr       , // Read/Write address
input  wire [XL:0]  imem_rdata      , // Read data
output wire [XL:0]  imem_wdata      , // Write data

input  wire         fe_flush        , // Flush stage
input  wire         fe_stall        , // Stall stage
output wire         fe_ready        , // Stage ready to progress

output wire [XL:0]  d_data          , // Data to be decoded.
output wire         d_error 

);

// Value taken by the PC on a reset.
parameter FRV_PC_RESET_VALUE = 32'h8000_0000;

// Common core parameters and constants
`include "frv_common.vh"

wire        f_4byte      ; // Input data valid
wire        f_2byte      ; // Load only the 2 MS bytes
wire        f_ready      ; // buffer ready for data

wire [XL:0] buf_data     ; // Output data
wire        buf_out_2    ; // 
wire        buf_out_4    ; // 
wire        buf_err      ; // Output error bit
wire        buf_valid    ; // D output data is valid
wire        buf_ready    ; // Eat 2/4 bytes

assign      d_data       = buf_data;
assign      d_error      = buf_err;

wire [XL:0] dbg_buf_out = {buf_out_2 ? 16'b0 : buf_data[31:16], buf_data[15:0]};

// Decode stage can eat fetched bytes
assign      buf_ready = !fe_stall;

// Fetch / decode are ready to progress.
assign      fe_ready= buf_valid;

// Ignore recieved data
wire        txn_ign = !f_ready;

// Recieve 4 bytes from memory
wire        txn_recv= imem_cen && !imem_stall && !txn_ign;

// Store 4 bytes of fetch data to the buffer.
assign      f_4byte = txn_recv && !misaligned_fetch;

// Store upper 2 bytes of fetch data to the buffer.
assign      f_2byte = txn_recv &&  misaligned_fetch;

wire progress_fe = !fe_stall && fe_ready;

//
// Fetch address computation
wire [XL:0] n_fetch_addr           = imem_addr + 4;

reg         misaligned_fetch;

wire      n_misaligned_fetch = 
    (cf_req && cf_ack && cf_target[1] || misaligned_fetch) &&
    !f_2byte;

assign      cf_ack = !imem_cen || txn_recv;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        misaligned_fetch <= 1'b0;
    end else begin
        misaligned_fetch <= n_misaligned_fetch;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        imem_addr <= FRV_PC_RESET_VALUE;
    end else if(cf_req && cf_ack) begin
        imem_addr <= {cf_target[XL:2],2'b00};
    end else if(txn_recv) begin
        imem_addr <= n_fetch_addr;
    end
end

assign imem_wdata = 0;
assign imem_strb  = 0;
assign imem_wen   = 0;

reg  p_txn_finish;

always @(posedge g_clk) p_txn_finish<= !g_resetn? 1'b0 : txn_recv;

// Keep fetching so long as there are no valid instructions in the
// fetch buffer.
wire n_imem_cen = f_ready ||
                 !f_ready && progress_fe;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        imem_cen <= 1'b0;
    end else begin
        imem_cen <= n_imem_cen;
    end
end

// ---------------------- Submodules -------------------------


frv_core_fetch_buffer i_core_fetch_buffer (
.g_clk    (g_clk        ), // Global clock
.g_resetn (g_resetn     ), // Global negative level triggered reset
.flush    (fe_flush     ),
.f_ready  (f_ready      ),
.f_4byte  (f_4byte      ), // Input data valid
.f_2byte  (f_2byte      ), // Load only the 2 MS bytes
.f_err    (imem_error   ), // Input error
.f_in     (imem_rdata   ), // Input data
.buf_out  (buf_data     ), // Output data
.buf_out_2(buf_out_2    ), // Output data
.buf_out_4(buf_out_4    ), // Output data
.buf_err  (buf_err      ), // Output error bit
.buf_valid(buf_valid    ), // D output data is valid
.buf_ready(buf_ready    )  // Eat 2/4 bytes
);


endmodule
