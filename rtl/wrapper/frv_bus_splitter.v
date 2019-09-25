
//
// module: frv_bus_splitter
//
//  Splits requests between two different masters based on
//  a basic address map. All requests to one master must complete
//  before requests to the other master can begin.
//
module frv_bus_splitter (

input               g_clk    , // global clock
input               g_resetn , // synchronous reset

//
// Slave 0
input  wire         s0_req   , // Start memory request
output wire         s0_gnt   , // request accepted
input  wire         s0_wen   , // Write enable
input  wire [3:0]   s0_strb  , // Write strobe
input  wire [31:0]  s0_wdata , // Write data
input  wire [31:0]  s0_addr  , // Read/Write address

output wire         s0_recv  , // Instruction memory recieve response.
input  wire         s0_ack   , // Instruction memory ack response.
output wire         s0_error , // Error
output wire [31:0]  s0_rdata , // Read data

//
// Master 0
output wire         m0_req   , // Start memory request
input  wire         m0_gnt   , // request accepted
output wire         m0_wen   , // Write enable
output wire [3:0]   m0_strb  , // Write strobe
output wire [31:0]  m0_wdata , // Write data
output wire [31:0]  m0_addr  , // Read/Write address

input  wire         m0_recv  , // Instruction memory recieve response.
output wire         m0_ack   , // Instruction memory ack response.
input  wire         m0_error , // Error
input  wire [31:0]  m0_rdata , // Read data

//
// Master 1
output wire         m1_req   , // Start memory request
input  wire         m1_gnt   , // request accepted
output wire         m1_wen   , // Write enable
output wire [3:0]   m1_strb  , // Write strobe
output wire [31:0]  m1_wdata , // Write data
output wire [31:0]  m1_addr  , // Read/Write address

input  wire         m1_recv  , // Instruction memory recieve response.
output wire         m1_ack   , // Instruction memory ack response.
input  wire         m1_error , // Error
input  wire [31:0]  m1_rdata   // Read data

);

parameter M0_ADDR_MASK = 32'hFFFF8000;
parameter M0_ADDR_MATCH= 32'hC0000000;

//
// Outstanding request tracking.

wire      m0_req_now    = m0_req    && m0_gnt;
wire      m0_rsp_now    = m0_recv   && m0_ack;

wire      m1_req_now    = m1_req    && m1_gnt;
wire      m1_rsp_now    = m1_recv   && m1_ack;

reg  [2:0] m0_reqs_out;
reg  [2:0] m1_reqs_out;

wire [2:0] n_m0_reqs_out = (m0_reqs_out + m0_req_now) - m0_rsp_now;
wire [2:0] n_m1_reqs_out = (m1_reqs_out + m1_req_now) - m1_rsp_now;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        m0_reqs_out <= 0;
        m1_reqs_out <= 0;
    end else begin
        m0_reqs_out <= n_m0_reqs_out;
        m1_reqs_out <= n_m1_reqs_out;
    end
end

//
// Request destination decoding

wire    addr_to_m0 = (m0_addr & M0_ADDR_MASK) == M0_ADDR_MATCH;
wire    addr_to_m1 = !addr_to_m0;

wire    m0_req_en  = addr_to_m0 && m1_reqs_out == 0;
wire    m1_req_en  = addr_to_m1 && m0_reqs_out == 0;

//
// Request sending.

assign m0_req   = s0_req && m0_req_en;

assign m0_wen   = s0_wen  ;
assign m0_strb  = s0_strb ;
assign m0_wdata = s0_wdata;
assign m0_addr  = s0_addr ;

assign m1_req   = s0_req && m1_req_en;

assign m1_wen   = s0_wen  ;
assign m1_strb  = s0_strb ;
assign m1_wdata = s0_wdata;
assign m1_addr  = s0_addr ;

assign s0_gnt   = m0_req && m0_gnt || m1_req && m1_gnt;

//
// Response routing.
//
//  Assumption: Impossible for two responses at the same time, since
//      requests to different masters cannot overlap in time either.
//
assign s0_recv  = m0_recv || m1_recv;
assign s0_error = m0_recv ? m0_error : m1_error;
assign s0_rdata = m0_recv ? m0_rdata : m1_rdata;

endmodule
