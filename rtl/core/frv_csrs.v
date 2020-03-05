
//
// module: frv_csrs
//
//  Responsible for keeping control/status registers up to date.
//
module frv_csrs (

input              g_clk            , // global clock
input              g_resetn         , // synchronous reset

input              csr_en           , // CSR Access Enable
input              csr_wr           , // CSR Write Enable
input              csr_wr_set       , // CSR Write - Set
input              csr_wr_clr       , // CSR Write - Clear
input       [11:0] csr_addr         , // Address of the CSR to access.
input       [XL:0] csr_wdata        , // Data to be written to a CSR
output wire [XL:0] csr_rdata        , // CSR read data
output wire        csr_error        , // Raise invalid opcode exception.

output wire [XL:0] csr_mepc         , // Current EPC.
output wire [XL:0] csr_mtvec        , // Current MTVEC address.
output wire        vector_intrs     , // Vector interrupt mode (if set)

input  wire        exec_mret        , // MRET instruction executed.

output wire        mstatus_mie      , // Global interrupt enable.
output reg         mie_meie         , // External interrupt enable.
output reg         mie_mtie         , // Timer interrupt enable.
output reg         mie_msie         , // Software interrupt enable.

input  wire        mip_meip         , // External interrupt pending
input  wire        mip_mtip         , // Timer interrupt pending
input  wire        mip_msip         , // Software interrupt pending

input  wire [63:0] ctr_time         , // The time counter value.
input  wire [63:0] ctr_cycle        , // The cycle counter value.
input  wire [63:0] ctr_instret      , // The instret counter value.

output wire        inhibit_cy       , // Stop cycle counter incrementing.
output wire        inhibit_tm       , // Stop time counter incrementing.
output wire        inhibit_ir       , // Stop instret incrementing.

output reg         uxcrypto_ct      , // UXCrypto constant time bit.
output reg  [ 7:0] uxcrypto_b0      , // UXCrypto lookup table 0.
output reg  [ 7:0] uxcrypto_b1      , // UXCrypto lookup table 1.

output wire [12:0] leak_lkgcfg      , // FENL Leakage configuration register.

input  wire        trap_cpu         , // A trap occured due to CPU
input  wire        trap_int         , // A trap occured due to interrupt
input  wire [ 5:0] trap_cause       , // A trap occured due to interrupt
input  wire [XL:0] trap_mtval       , // Value associated with the trap.
input  wire [XL:0] trap_pc            // PC value associated with the trap.

);

// Common core parameters and constants
`include "frv_common.vh"

//
// CSR addresses and constant values.
// -------------------------------------------------------------------------

parameter  CSR_MTVEC_RESET_VALUE= 32'hC0000000;
parameter  CSR_MVENDORID        = 32'b0;
parameter  CSR_MARCHID          = 32'b0;
parameter  CSR_MIMPID           = 32'b0;
parameter  CSR_MHARTID          = 32'b0;

localparam CSR_ADDR_CYCLE       = 12'hC00;
localparam CSR_ADDR_TIME        = 12'hC01;
localparam CSR_ADDR_INSTRET     = 12'hC02;
localparam CSR_ADDR_CYCLEH      = 12'hC80;
localparam CSR_ADDR_TIMEH       = 12'hC81;
localparam CSR_ADDR_INSTRETH    = 12'hC82;

localparam CSR_ADDR_MCYCLE      = 12'hB00;
localparam CSR_ADDR_MINSTRET    = 12'hB02;
localparam CSR_ADDR_MCYCLEH     = 12'hB80;
localparam CSR_ADDR_MINSTRETH   = 12'hB82;

localparam CSR_ADDR_MCOUNTIN    = 12'h320;

localparam CSR_ADDR_MSTATUS     = 12'h300;
localparam CSR_ADDR_MISA        = 12'h301;
localparam CSR_ADDR_MEDELEG     = 12'h302;
localparam CSR_ADDR_MIDELEG     = 12'h303;
localparam CSR_ADDR_MIE         = 12'h304;
localparam CSR_ADDR_MTVEC       = 12'h305;

localparam CSR_ADDR_MSCRATCH    = 12'h340;
localparam CSR_ADDR_MEPC        = 12'h341;
localparam CSR_ADDR_MCAUSE      = 12'h342;
localparam CSR_ADDR_MTVAL       = 12'h343;
localparam CSR_ADDR_MIP         = 12'h344;

localparam CSR_ADDR_MVENDORID   = 12'hF11;
localparam CSR_ADDR_MARCHID     = 12'hF12;
localparam CSR_ADDR_MIMPID      = 12'hF13;
localparam CSR_ADDR_MHARTID     = 12'hF14;

localparam CSR_ADDR_UXCRYPTO    = 12'h800;
localparam CSR_ADDR_LKGCFG      = 12'h801;

//
// XCrypto feature class config bits.
parameter XC_CLASS_BASELINE   = 1'b1;
parameter XC_CLASS_RANDOMNESS = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_MEMORY     = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_BIT        = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_PACKED     = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_MULTIARITH = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_AES        = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_SHA2       = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_SHA3       = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_LEAK       = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_MASK       = 1'b1 && XC_CLASS_BASELINE;

//
// Partial Bitmanip Extension Support
parameter BITMANIP_BASELINE   = 1'b1;

//
// CSR: MISA
// -------------------------------------------------------------------------

wire [ 1:0] reg_misa_mxl        = 2'b01;
wire [25:0] reg_misa_extensions = {
    1'b0,               // Z
    1'b0,               // Y
    XC_CLASS_BASELINE,  // X - Non-standard/XCrypto
    1'b0,               // W
    1'b0,               // V
    1'b0,               // U
    1'b0,               // T
    1'b0,               // S
    1'b0,               // R
    1'b0,               // Q
    1'b0,               // P
    1'b0,               // O
    1'b0,               // N
    1'b1,               // M - Integer multiply/divide
    1'b0,               // L
    1'b0,               // K
    1'b0,               // J
    1'b1,               // I - RV32I Base ISA
    1'b0,               // H
    1'b0,               // G
    1'b0,               // F
    1'b0,               // E
    1'b0,               // D
    1'b1,               // C - Compressed ISA
    BITMANIP_BASELINE,  // B - Bitmanipulation
    1'b0                // A
};

wire [31:0] reg_misa = {
    reg_misa_mxl,
    4'b0        ,
    reg_misa_extensions
};


//
// CSR: constants
// -------------------------------------------------------------------------

wire [31:0] reg_mvendorid       = CSR_MVENDORID;
wire [31:0] reg_marchid         = CSR_MARCHID;
wire [31:0] reg_mimpid          = CSR_MIMPID;
wire [31:0] reg_mhartid         = CSR_MHARTID;

wire [31:0] reg_medeleg         = 32'b0;
wire [31:0] reg_mideleg         = 32'b0;


//
// CSR: MIP / MIE
// -------------------------------------------------------------------------

wire [31:0] reg_mip = {20'b0,mip_meip,3'b0,mip_mtip,3'b0,mip_msip,3'b0};

wire wen_mie = csr_en && csr_wr  && csr_addr == CSR_ADDR_MIE;

wire [31:0] reg_mie = {20'b0,mie_meie,3'b0,mie_mtie,3'b0,mie_msie,3'b0};

wire [31:0] n_reg_mie = 
    csr_wr_set ? reg_mie |  csr_wdata :
    csr_wr_clr ? reg_mie & ~csr_wdata :
                            csr_wdata ;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        mie_meie <= 1'b0;
        mie_mtie <= 1'b0;
        mie_msie <= 1'b0;
    end else if(wen_mie) begin
        mie_meie <= n_reg_mie[11];
        mie_mtie <= n_reg_mie[ 7];
        mie_msie <= n_reg_mie[ 3];
    end
end


//
// CSR: MSTATUS
// -------------------------------------------------------------------------

wire        reg_mstatus_sd      = 0; // FS,XS always zero.
reg  [ 7:0] reg_mstatus_wpri1      ;
wire        reg_mstatus_tsr     = 0; // Supervisor mode not implemented.
wire        reg_mstatus_tw      = 0; // WFI instruction not implemented.
wire        reg_mstatus_tvm     = 0; // Supervisor mode not implemented.
wire        reg_mstatus_mxr     = 0; // Supervisor mode not implemented.
wire        reg_mstatus_sum     = 0; // User/supervisor mode not implemnted.
wire        reg_mstatus_mprv    = 0; // User/supervisor mode not implemented.
wire [ 1:0] reg_mstatus_xs      = 0; // No non-standard extensions.
wire [ 1:0] reg_mstatus_fs      = 0; // Floating point not implemented.
wire [ 1:0] reg_mstatus_mpp     = 0; // User/supervisor mode not implemented.
reg  [ 1:0] reg_mstatus_wpri2      ;
wire        reg_mstatus_spp     = 0; // User mode not implemented
reg         reg_mstatus_mpie       ;
reg         reg_mstatus_wpri3      ;
wire        reg_mstatus_spie    = 0; // Supervisor mode not implemented
wire        reg_mstatus_upie    = 0; // User mode not implemented
reg         reg_mstatus_mie        ;
reg         reg_mstatus_wpri4      ;
wire        reg_mstatus_sie     = 0; // Supervisor mode not implemented
wire        reg_mstatus_uie     = 0; // User mode not implemented

assign        mstatus_mie = reg_mstatus_mie;

wire [31:0] reg_mstatus         = {
    reg_mstatus_sd    ,
    reg_mstatus_wpri1 ,
    reg_mstatus_tsr   ,
    reg_mstatus_tw    ,
    reg_mstatus_tvm   ,
    reg_mstatus_mxr   ,
    reg_mstatus_sum   ,
    reg_mstatus_mprv  ,
    reg_mstatus_xs    ,
    reg_mstatus_fs    ,
    reg_mstatus_mpp   ,
    reg_mstatus_wpri2 ,
    reg_mstatus_spp   ,
    reg_mstatus_mpie  ,
    reg_mstatus_wpri3 ,
    reg_mstatus_spie  ,
    reg_mstatus_upie  ,
    reg_mstatus_mie   ,
    reg_mstatus_wpri4 ,
    reg_mstatus_sie   ,
    reg_mstatus_uie    
};

wire        wen_mstatus     = csr_wr && csr_addr == CSR_ADDR_MSTATUS;
wire        wen_mstatus_mie = wen_mstatus || trap_cpu || trap_int || exec_mret;
wire        wen_mstatus_mpie= wen_mstatus || trap_cpu || trap_int || exec_mret;

wire        n_mstatus_mie       =
    trap_int      ? 1'b0                                :
    trap_cpu      ? 1'b0                                :
    exec_mret     ? reg_mstatus_mpie                    :
    csr_wr_set    ? reg_mstatus_mie |  csr_wdata[3] :
    csr_wr_clr    ? reg_mstatus_mie & ~csr_wdata[3] :
                    csr_wdata[3]                ;

wire        n_mstatus_mpie      = 
    trap_int      ? reg_mstatus_mie                 :
    trap_cpu      ? reg_mstatus_mie                 :
    exec_mret     ? 0                               :
    csr_wr_set    ? reg_mstatus_mie |  csr_wdata[7] :
    csr_wr_clr    ? reg_mstatus_mie & ~csr_wdata[7] :
                    csr_wdata[7]                    ;


wire        n_mstatus_wpri4     = csr_wdata[ 2: 2];
wire        n_mstatus_wpri3     = csr_wdata[ 6: 6];
wire [ 1:0] n_mstatus_wpri2     = csr_wdata[10: 9];
wire [ 7:0] n_mstatus_wpri1     = csr_wdata[30:23];

always @(posedge g_clk) begin
    if(!g_resetn) begin
        reg_mstatus_mie  <= 0;
    end else if (wen_mstatus_mie) begin
        reg_mstatus_mie  <= n_mstatus_mie ;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        reg_mstatus_mpie  <= 0;
    end else if (wen_mstatus_mpie) begin
        reg_mstatus_mpie  <= n_mstatus_mpie ;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        reg_mstatus_wpri1 <= 0;
        reg_mstatus_wpri2 <= 0;
        reg_mstatus_wpri3 <= 0;
        reg_mstatus_wpri4 <= 0;
    end else if (wen_mstatus) begin
        reg_mstatus_wpri1 <= n_mstatus_wpri1;
        reg_mstatus_wpri2 <= n_mstatus_wpri2;
        reg_mstatus_wpri3 <= n_mstatus_wpri3;
        reg_mstatus_wpri4 <= n_mstatus_wpri4;
    end
end


//
// CSR: MTVEC
// -------------------------------------------------------------------------

reg  [29:0] reg_mtvec_base  ;
reg  [ 1:0] reg_mtvec_mode  ; // Only direct exceptions supported.

wire [31:0] reg_mtvec       = {
    reg_mtvec_base,
    reg_mtvec_mode
};

assign      csr_mtvec    = {reg_mtvec_base, 2'b00};
assign      vector_intrs = reg_mtvec_mode[0];

wire        wen_mtvec    = csr_wr && csr_addr == CSR_ADDR_MTVEC;

wire [29:0] n_mtvec_base = 
    csr_wr_set ? csr_mtvec[31:2] |  csr_wdata[31:2] :
    csr_wr_clr ? csr_mtvec[31:2] & ~csr_wdata[31:2] :
                 csr_wdata[31:2]                    ;

wire [1:0] n_mtvec_mode = 
    csr_wr_set ? csr_mtvec[ 1:0] |  csr_wdata[ 1:0] :
    csr_wr_clr ? csr_mtvec[ 1:0] & ~csr_wdata[ 1:0] :
                 csr_wdata[ 1:0]                    ;

wire        mtvec_bad_write = wen_mtvec && (
    n_mtvec_mode[1] ||
    n_mtvec_mode[0] && |n_mtvec_base[4:0]
);

always @(posedge g_clk) begin
    if(!g_resetn) begin
        reg_mtvec_base <= CSR_MTVEC_RESET_VALUE[31:2];
        reg_mtvec_mode <= 2'b00;;
    end else if(wen_mtvec && !mtvec_bad_write) begin
        reg_mtvec_base <= n_mtvec_base;
        reg_mtvec_mode <= n_mtvec_mode;
    end
end


//
// CSR: MSCRATCH
// -------------------------------------------------------------------------

reg [31:0] reg_mscratch;

wire[31:0] n_reg_mscratch = 
    csr_wr_set ? reg_mscratch |  csr_wdata :
    csr_wr_clr ? reg_mscratch & ~csr_wdata :
                 csr_wdata                 ;

wire       wen_mscratch = csr_wr && csr_addr == CSR_ADDR_MSCRATCH;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        reg_mscratch <= 0;
    end else if(wen_mscratch) begin
        reg_mscratch <= n_reg_mscratch;
    end
end


//
// CSR: MTVAL
// -------------------------------------------------------------------------

reg  [31:0] reg_mtval   ;
wire [31:0] n_reg_mtval =
    trap_cpu? trap_mtval            :
    csr_wr_set ? reg_mtval |  csr_wdata:
    csr_wr_clr ? reg_mtval & ~csr_wdata:
                 csr_wdata             ;

wire wen_mtval = csr_wr && csr_addr == CSR_ADDR_MTVAL;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        reg_mtval <= 0          ;
    end else if(wen_mtval || trap_cpu) begin
        reg_mtval <= n_reg_mtval;
    end
end


//
// CSR: MEPC
// -------------------------------------------------------------------------

reg  [30:0] reg_mepc_mepc;
wire        reg_mepc_warl = 1'b0;

wire [31:0] reg_mepc = {
    reg_mepc_mepc,
    reg_mepc_warl
};

assign      csr_mepc = {reg_mepc_mepc, 1'b0};

wire        wen_mepc = csr_wr  && csr_addr == CSR_ADDR_MEPC ||
                       trap_cpu                             ||
                       trap_int                             ;

wire [30:0] n_mepc   =
    trap_int || trap_cpu? trap_pc[31:1]                     :
    csr_wr_set          ? reg_mepc_mepc |  csr_wdata[31:1]  :
    csr_wr_clr          ? reg_mepc_mepc & ~csr_wdata[31:1]  :
                          csr_wdata[31:1]                   ;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        reg_mepc_mepc <= 0;
    end else if(wen_mepc) begin
        reg_mepc_mepc <= n_mepc;
    end
end


//
// MCAUSE
// -------------------------------------------------------------------------

reg         reg_mcause_interrupt ;// Interrupts not implemented.
reg  [30:0] reg_mcause_cause     ;

wire [31:0] reg_mcause = {
    reg_mcause_interrupt,
    reg_mcause_cause
};

wire        wen_mcause = csr_wr  && csr_addr == CSR_ADDR_MCAUSE ||
                         trap_cpu                               ||
                         trap_int                               ;

wire [30:0] n_mcause_cause =
    trap_int || trap_cpu ? {25'b0, trap_cause   }                :
    csr_wr_set           ? reg_mcause_cause |  csr_wdata[30:0]   :
    csr_wr_clr           ? reg_mcause_cause & ~csr_wdata[30:0]   :
                           csr_wdata[30:0]                       ;

wire        wen_valid_mcause = 
    csr_wdata == {26'b0,TRAP_IALIGN  } ||
    csr_wdata == {26'b0,TRAP_IACCESS } ||
    csr_wdata == {26'b0,TRAP_IOPCODE } ||
    csr_wdata == {26'b0,TRAP_BREAKPT } ||
    csr_wdata == {26'b0,TRAP_LDALIGN } ||
    csr_wdata == {26'b0,TRAP_LDACCESS} ||
    csr_wdata == {26'b0,TRAP_STALIGN } ||
    csr_wdata == {26'b0,TRAP_STACCESS} ||
    csr_wdata == {26'b0,TRAP_ECALLM  } ||
    csr_addr  != CSR_ADDR_MCAUSE             ;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        reg_mcause_cause     <= 0; 
        reg_mcause_interrupt <= 0;
    end else if(wen_mcause && wen_valid_mcause) begin
        reg_mcause_cause     <= n_mcause_cause;
        reg_mcause_interrupt <= trap_int;
    end
end


//
// MCOUNTERIN
// -------------------------------------------------------------------------

reg mcountin_ir;
reg mcountin_tm;
reg mcountin_cy;

// TODO: Turn into ports.
assign inhibit_ir = mcountin_ir;
assign inhibit_tm = mcountin_tm;
assign inhibit_cy = mcountin_cy;

wire wen_mcountin = csr_wr && csr_addr == CSR_ADDR_MCOUNTIN;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        mcountin_ir <= 1'b0;
        mcountin_tm <= 1'b0;
        mcountin_cy <= 1'b0;
    end else if(wen_mcountin) begin
        mcountin_ir <= csr_wdata[2];
        mcountin_tm <= csr_wdata[1];
        mcountin_cy <= csr_wdata[0];
    end
end

wire [31:0] reg_mcountin = {
    29'b0, 
    mcountin_ir,
    mcountin_tm,
    mcountin_cy
};

//
// UXCRYPTO
// -------------------------------------------------------------------------

// Output register ports:
// - [0:0] uxcrypto_ct
// - [7:0] uxcrypto_b0
// - [7:0] uxcrypto_b1

wire [12:0] uxcrypto_features = {
    XC_CLASS_MASK       ,
    XC_CLASS_LEAK       ,
    XC_CLASS_BIT        ,
    XC_CLASS_MEMORY     ,
    XC_CLASS_RANDOMNESS ,
    XC_CLASS_PACKED     ,
    XC_CLASS_PACKED     ,
    XC_CLASS_PACKED     ,
    XC_CLASS_PACKED     ,
    XC_CLASS_MULTIARITH ,
    XC_CLASS_SHA3       ,
    XC_CLASS_SHA2       ,
    XC_CLASS_AES         
};

wire [31:0] reg_uxcrypto = {
    uxcrypto_b1      ,
    uxcrypto_b0      ,
    2'b000           ,
    uxcrypto_features,
    uxcrypto_ct
};

wire       wen_uxcrypto = csr_wr && csr_addr == CSR_ADDR_UXCRYPTO;

wire       n_uxcrypto_ct = 
    csr_wr_set ? uxcrypto_ct |  csr_wdata[0] :
    csr_wr_clr ? uxcrypto_ct & ~csr_wdata[0] :
                                csr_wdata[0] ;

wire [7:0] n_uxcrypto_b0 = 
    csr_wr_set ? uxcrypto_b0 |  csr_wdata[23:16] :
    csr_wr_clr ? uxcrypto_b0 & ~csr_wdata[23:16] :
                                csr_wdata[23:16] ;

wire [7:0] n_uxcrypto_b1 = 
    csr_wr_set ? uxcrypto_b1 |  csr_wdata[31:24] :
    csr_wr_clr ? uxcrypto_b1 & ~csr_wdata[31:24] :
                                csr_wdata[31:24] ;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        uxcrypto_ct <= 0;
        uxcrypto_b0 <= 0;
        uxcrypto_b1 <= 0;
    end else if(wen_uxcrypto) begin
        uxcrypto_ct <= n_uxcrypto_ct;
        uxcrypto_b0 <= n_uxcrypto_b0;
        uxcrypto_b1 <= n_uxcrypto_b1;
    end
end


//
// LKGCFG
//
//  FENL - Leakage Fence configuration register.
//
// -------------------------------------------------------------------------

reg  [12:0]   reg_lkgcfg ;

assign        leak_lkgcfg= reg_lkgcfg;

wire [12:0] n_reg_lkgcfg =
    csr_wr_set ? reg_lkgcfg |  csr_wdata[12: 0] :
    csr_wr_clr ? reg_lkgcfg & ~csr_wdata[12: 0] :
                               csr_wdata[12: 0] ;

wire          wen_lkgcfg = csr_wr && csr_addr == CSR_ADDR_LKGCFG;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        
        reg_lkgcfg <= 13'b0;

    end else if(wen_lkgcfg) begin
        
        reg_lkgcfg <= n_reg_lkgcfg;

    end
end

//
// CSR read responses.
// -------------------------------------------------------------------------

wire   read_mstatus   = csr_en && csr_addr == CSR_ADDR_MSTATUS  ;
wire   read_misa      = csr_en && csr_addr == CSR_ADDR_MISA     ;
wire   read_medeleg   = csr_en && csr_addr == CSR_ADDR_MEDELEG  ;
wire   read_mideleg   = csr_en && csr_addr == CSR_ADDR_MIDELEG  ;
wire   read_mie       = csr_en && csr_addr == CSR_ADDR_MIE      ;
wire   read_mtvec     = csr_en && csr_addr == CSR_ADDR_MTVEC    ;
wire   read_mscratch  = csr_en && csr_addr == CSR_ADDR_MSCRATCH ;
wire   read_mepc      = csr_en && csr_addr == CSR_ADDR_MEPC     ;
wire   read_mcause    = csr_en && csr_addr == CSR_ADDR_MCAUSE   ;
wire   read_mtval     = csr_en && csr_addr == CSR_ADDR_MTVAL    ;
wire   read_mip       = csr_en && csr_addr == CSR_ADDR_MIP      ;
wire   read_mvendorid = csr_en && csr_addr == CSR_ADDR_MVENDORID;
wire   read_marchid   = csr_en && csr_addr == CSR_ADDR_MARCHID  ;
wire   read_mimpid    = csr_en && csr_addr == CSR_ADDR_MIMPID   ;
wire   read_mhartid   = csr_en && csr_addr == CSR_ADDR_MHARTID  ;
wire   read_cycle     = csr_en && csr_addr == CSR_ADDR_CYCLE    ;
wire   read_time      = csr_en && csr_addr == CSR_ADDR_TIME     ;
wire   read_instret   = csr_en && csr_addr == CSR_ADDR_INSTRET  ;
wire   read_cycleh    = csr_en && csr_addr == CSR_ADDR_CYCLEH   ;
wire   read_timeh     = csr_en && csr_addr == CSR_ADDR_TIMEH    ;
wire   read_instreth  = csr_en && csr_addr == CSR_ADDR_INSTRETH ;
wire   read_mcycle    = csr_en && csr_addr == CSR_ADDR_MCYCLE   ;
wire   read_minstret  = csr_en && csr_addr == CSR_ADDR_MINSTRET ;
wire   read_mcycleh   = csr_en && csr_addr == CSR_ADDR_MCYCLEH  ;
wire   read_minstreth = csr_en && csr_addr == CSR_ADDR_MINSTRETH;
wire   read_mcountin  = csr_en && csr_addr == CSR_ADDR_MCOUNTIN ;
wire   read_uxcrypto  = csr_en && csr_addr == CSR_ADDR_UXCRYPTO ;
wire   read_lkgcfg    = csr_en && csr_addr == CSR_ADDR_LKGCFG   ;

wire   valid_addr     = 
    read_mstatus   ||
    read_misa      ||
    read_medeleg   ||
    read_mideleg   ||
    read_mie       ||
    read_mtvec     ||
    read_mscratch  ||
    read_mepc      ||
    read_mcause    ||
    read_mtval     ||
    read_mip       ||
    read_mvendorid ||
    read_marchid   ||
    read_mimpid    ||
    read_mhartid   ||
    read_cycle     ||
    read_time      ||
    read_instret   ||
    read_cycleh    ||
    read_timeh     ||
    read_instreth  ||
    read_mcycle    ||
    read_minstret  ||
    read_mcycleh   ||
    read_minstreth ||
    read_mcountin  ||
    read_uxcrypto  ||
    read_lkgcfg    ;

wire invalid_addr = !valid_addr;

assign csr_error = csr_en && (
    (csr_wr && invalid_addr ) ||
    (mtvec_bad_write        )
);
                    

assign csr_rdata =
    {32{read_mstatus  }} & reg_mstatus          |
    {32{read_misa     }} & reg_misa             |
    {32{read_medeleg  }} & reg_medeleg          |
    {32{read_mideleg  }} & reg_mideleg          |
    {32{read_mie      }} & reg_mie              |
    {32{read_mtvec    }} & reg_mtvec            |
    {32{read_mscratch }} & reg_mscratch         |
    {32{read_mepc     }} & reg_mepc             |
    {32{read_mcause   }} & reg_mcause           |
    {32{read_mtval    }} & reg_mtval            |
    {32{read_mip      }} & reg_mip              |
    {32{read_mvendorid}} & reg_mvendorid        |
    {32{read_marchid  }} & reg_marchid          |
    {32{read_mimpid   }} & reg_mimpid           |
    {32{read_mhartid  }} & reg_mhartid          |
    {32{read_cycle    }} & ctr_cycle    [31: 0] |
    {32{read_time     }} & ctr_time     [31: 0] |
    {32{read_instret  }} & ctr_instret  [31: 0] |
    {32{read_cycleh   }} & ctr_cycle    [63:32] |
    {32{read_timeh    }} & ctr_time     [63:32] |
    {32{read_instreth }} & ctr_instret  [63:32] |
    {32{read_mcycle   }} & ctr_cycle    [31: 0] |
    {32{read_minstret }} & ctr_instret  [31: 0] |
    {32{read_mcycleh  }} & ctr_cycle    [63:32] |
    {32{read_minstreth}} & ctr_instret  [63:32] |
    {32{read_mcountin }} & reg_mcountin         |
    {32{read_uxcrypto }} & reg_uxcrypto         |
    {32{read_lkgcfg   }} & {19'b0,reg_lkgcfg}   ;

endmodule

