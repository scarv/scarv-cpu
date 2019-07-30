
//
// module: frv_counters
//
//  Responsible for all performance counters and timers.
//
module frv_counters (

input              g_clk            , // global clock
input              g_resetn         , // synchronous reset
                                
input              instr_ret        , // Instruction retired.
output reg         timer_interrupt  , // Raise a timer interrupt

output wire [63:0] ctr_time         , // The time counter value.
output reg  [63:0] ctr_cycle        , // The cycle counter value.
output reg  [63:0] ctr_instret      , // The instret counter value.

input  wire        inhibit_cy       , // Stop cycle counter incrementing.
input  wire        inhibit_tm       , // Stop time counter incrementing.
input  wire        inhibit_ir       , // Stop instret incrementing.

input  wire        mmio_en          , // MMIO enable
input  wire        mmio_wen         , // MMIO write enable
input  wire [31:0] mmio_addr        , // MMIO address
input  wire [31:0] mmio_wdata       , // MMIO write data
output reg  [31:0] mmio_rdata       , // MMIO read data
output reg         mmio_error         // MMIO error

);

// Base address of the memory mapped IO region.
parameter   MMIO_BASE_ADDR        = 32'h0000_1000;
parameter   MMIO_BASE_MASK        = 32'hFFFF_F000;

// Base address of the MTIME memory mapped register.
localparam  MMIO_MTIME_ADDR       = MMIO_BASE_ADDR;
localparam  MMIO_MTIME_ADDR_HI    = MMIO_MTIME_ADDR+4;

// Base address of the MTIMECMP memory mapped register.
localparam  MMIO_MTIMECMP_ADDR    = MMIO_BASE_ADDR + 8;
localparam  MMIO_MTIMECMP_ADDR_HI = MMIO_MTIMECMP_ADDR+4;

// Reset value of the MTIMECMP register.
parameter   MMIO_MTIMECMP_RESET   = -1;

// ---------------------- Memory mapped registers -----------------------

wire    addr_mtime_lo    = mmio_en &&
    (mmio_addr& ~MMIO_BASE_MASK)==(MMIO_MTIME_ADDR & ~MMIO_BASE_MASK);

wire    addr_mtime_hi    = mmio_en &&
    (mmio_addr& ~MMIO_BASE_MASK)==(MMIO_MTIME_ADDR_HI & ~MMIO_BASE_MASK);

wire    addr_mtimecmp_lo = mmio_en &&
    (mmio_addr& ~MMIO_BASE_MASK)==(MMIO_MTIMECMP_ADDR & ~MMIO_BASE_MASK);

wire    addr_mtimecmp_hi = mmio_en &&
    (mmio_addr& ~MMIO_BASE_MASK)==(MMIO_MTIMECMP_ADDR_HI & ~MMIO_BASE_MASK);

reg  [63:0] mapped_mtime;
reg  [63:0] mapped_mtimecmp;

wire [63:0] n_mapped_mtime = mapped_mtime + 1;

wire n_timer_interrupt = mapped_mtime >= mapped_mtimecmp;

wire wr_mtime_hi = addr_mtime_hi && mmio_wen;
wire wr_mtime_lo = addr_mtime_lo && mmio_wen;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        mapped_mtime <= 0;
    end else if(wr_mtime_hi) begin
        mapped_mtime <= {mmio_wdata, mapped_mtime[31:0]};
    end else if(wr_mtime_lo) begin
        mapped_mtime <= {mapped_mtime[63:32], mmio_wdata};
    end else if(!inhibit_tm) begin
        mapped_mtime <= n_mapped_mtime;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        timer_interrupt <= 0;
    end else begin
        timer_interrupt <= n_timer_interrupt;
    end
end

wire wr_mtimecmp_hi = addr_mtimecmp_hi && mmio_wen;
wire wr_mtimecmp_lo = addr_mtimecmp_lo && mmio_wen;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        
        mapped_mtimecmp <= MMIO_MTIMECMP_RESET;

    end else if(wr_mtimecmp_hi) begin
        
        mapped_mtimecmp <= {mmio_wdata[31:0], mapped_mtimecmp[31:0]};

    end else if(wr_mtimecmp_lo) begin
        
        mapped_mtimecmp <= {mapped_mtimecmp[63:32], mmio_wdata[31:0]};

    end
end


// ---------------------- MMIO Bus Reads --------------------------------

wire [31:0] n_mmio_rdata =
    {32{addr_mtime_lo   }} & mapped_mtime   [31: 0] |
    {32{addr_mtime_hi   }} & mapped_mtime   [63:32] |
    {32{addr_mtimecmp_lo}} & mapped_mtimecmp[31: 0] |
    {32{addr_mtimecmp_hi}} & mapped_mtimecmp[63:32] ;
        
wire        n_mmio_error = mmio_en && !(
    addr_mtime_lo       ||
    addr_mtime_hi       ||
    addr_mtimecmp_lo    ||
    addr_mtimecmp_hi    
);

always @(posedge g_clk) begin
    if(!g_resetn) begin
        mmio_error <=  1'b0;
        mmio_rdata <= 32'b0;
    end else if(mmio_en) begin
        mmio_error <= n_mmio_error;
        mmio_rdata <= n_mmio_rdata;
    end
end


// ---------------------- CSR registers ---------------------------------

//
// time register
//

assign ctr_time = mapped_mtime;


//
// instret register
//

wire [63:0] n_ctr_instret = ctr_instret + 1;

always @(posedge g_clk) begin
    if(!g_resetn) begin
    
        ctr_instret <= 0;

    end else if(instr_ret && !inhibit_ir) begin
        
        ctr_instret <= n_ctr_instret;

    end
end

//
// Cycle counter register
//

wire [63:0] n_ctr_cycle = ctr_cycle + 1;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        ctr_cycle <= 0;
    end else if(!inhibit_cy) begin
        ctr_cycle <= n_ctr_cycle;
    end
end

endmodule

