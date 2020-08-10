
//
// module: scarv_ccx_mmio
//
//  Memory mapped registers for the core complex.
//  Includes counters mtime and mtimecmp
//
module scarv_ccx_mmio (

input               f_clk           , // global clock
input               g_resetn        , // synchronous reset
                                 
input               instr_ret       , // Instruction retired.
output reg          timer_interrupt , // Raise a timer interrupt

output wire [63: 0] ctr_time        , // The time counter value.
output reg  [63: 0] ctr_cycle       , // The cycle counter value.
output reg  [63: 0] ctr_instret     , // The instret counter value.

input  wire         inhibit_cy      , // Stop cycle counter incrementing.
input  wire         inhibit_ir      , // Stop instret incrementing.

input  wire [31:0]  trng_pollentropy, // Value returned when TRNG_ADDR read.
output wire         trng_read       , // TRNG_ADDR has just been read.

scarv_ccx_memif.RSP mmio              // MMIO memory request interface.

);

// Base address of the memory mapped IO region.
parameter   MMIO_BASE_ADDR        = 32'h0000_1000;
parameter   MMIO_SIZE             = 32'h0000_0100;
localparam  MMIO_BASE_MASK        = ~MMIO_SIZE   ;

// Base address of the MTIME memory mapped register.
localparam  MMIO_MTIME_ADDR       = MMIO_BASE_ADDR;
localparam  MMIO_MTIME_ADDR_HI    = MMIO_MTIME_ADDR+4;

// Base address of the MTIMECMP memory mapped register.
localparam  MMIO_MTIMECMP_ADDR    = MMIO_BASE_ADDR + 8;
localparam  MMIO_MTIMECMP_ADDR_HI = MMIO_MTIMECMP_ADDR+4;

// Reset value of the MTIMECMP register.
parameter   MMIO_MTIMECMP_RESET   = -1;

// Base address of the TRNG MMIO register.
localparam  MMIO_TRNG_ADDR        = MMIO_BASE_ADDR + 12;

// Always accept requests instantly.
assign mmio.gnt = 1'b1;

// ---------------------- Memory mapped registers -----------------------

wire    addr_mtime_lo    = mmio.req &&
    (mmio.addr& ~MMIO_BASE_MASK)==(MMIO_MTIME_ADDR & ~MMIO_BASE_MASK);

wire    addr_mtime_hi    = mmio.req &&
    (mmio.addr& ~MMIO_BASE_MASK)==(MMIO_MTIME_ADDR_HI & ~MMIO_BASE_MASK);

wire    addr_mtimecmp_lo = mmio.req &&
    (mmio.addr& ~MMIO_BASE_MASK)==(MMIO_MTIMECMP_ADDR & ~MMIO_BASE_MASK);

wire    addr_mtimecmp_hi = mmio.req &&
    (mmio.addr& ~MMIO_BASE_MASK)==(MMIO_MTIMECMP_ADDR_HI & ~MMIO_BASE_MASK);

wire    addr_trng_poll   = mmio.req &&
    (mmio.addr& ~MMIO_BASE_MASK)==(MMIO_TRNG_ADDR        & ~MMIO_BASE_MASK);

reg  [63:0] mapped_mtime;
reg  [63:0] mapped_mtimecmp;

wire [63:0] n_mapped_mtime = mapped_mtime + 1;

wire n_timer_interrupt = mapped_mtime >= mapped_mtimecmp;

wire wr_mtime_hi = addr_mtime_hi && mmio.wen;
wire wr_mtime_lo = addr_mtime_lo && mmio.wen;

always @(posedge f_clk) begin
    if(!g_resetn) begin
        mapped_mtime <= 0;
    end else if(wr_mtime_hi) begin
        mapped_mtime <= {mmio.wdata, mapped_mtime[31:0]};
    end else if(wr_mtime_lo) begin
        mapped_mtime <= {mapped_mtime[63:32], mmio.wdata};
    end else begin
        mapped_mtime <= n_mapped_mtime;
    end
end

always @(posedge f_clk) begin
    if(!g_resetn) begin
        timer_interrupt <= 0;
    end else begin
        timer_interrupt <= n_timer_interrupt;
    end
end

wire wr_mtimecmp_hi = addr_mtimecmp_hi && mmio.wen;
wire wr_mtimecmp_lo = addr_mtimecmp_lo && mmio.wen;

always @(posedge f_clk) begin
    if(!g_resetn) begin
        
        mapped_mtimecmp <= MMIO_MTIMECMP_RESET;

    end else if(wr_mtimecmp_hi) begin
        
        mapped_mtimecmp <= {mmio.wdata[31:0], mapped_mtimecmp[31:0]};

    end else if(wr_mtimecmp_lo) begin
        
        mapped_mtimecmp <= {mapped_mtimecmp[63:32], mmio.wdata[31:0]};

    end
end


// ---------------------- MMIO Bus Reads --------------------------------

wire [31:0] n_mmio_rdata =
    {32{addr_mtime_lo   }} & mapped_mtime    [31: 0] |
    {32{addr_mtime_hi   }} & mapped_mtime    [63:32] |
    {32{addr_mtimecmp_lo}} & mapped_mtimecmp [31: 0] |
    {32{addr_mtimecmp_hi}} & mapped_mtimecmp [63:32] |
    {32{addr_trng_poll  }} & trng_pollentropy[31: 0] ;
        
wire        n_mmio_error = mmio.req && !(
    addr_mtime_lo       ||
    addr_mtime_hi       ||
    addr_mtimecmp_lo    ||
    addr_mtimecmp_hi    ||
    addr_trng_poll   
);

assign      trng_read = mmio.req && mmio.gnt && addr_trng_poll;

always @(posedge f_clk) begin
    if(!g_resetn) begin
        mmio.error <=  1'b0;
        mmio.rdata <= 32'b0;
    end else if(mmio.req) begin
        mmio.error <= n_mmio_error;
        mmio.rdata <= n_mmio_rdata;
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

always @(posedge f_clk) begin
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

always @(posedge f_clk) begin
    if(!g_resetn) begin
        ctr_cycle <= 0;
    end else if(!inhibit_cy) begin
        ctr_cycle <= n_ctr_cycle;
    end
end

endmodule

