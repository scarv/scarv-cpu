
//
// module: scarv_ccx_top
//
//  Top level module of the core complex.
//
module scarv_ccx_top (

input  wire         f_clk           , // Free-running clock.
input  wire         g_resetn        , // Synchronous active low reset.

input  wire         int_ext         , // External interrupt.
input  wire [31:0]  int_ext_cause   , // External interrupt cause.

output wire [31: 0] cpu_trs_pc      , // Trace program counter.
output wire [31: 0] cpu_trs_instr   , // Trace instruction.
output wire         cpu_trs_valid   , // Trace output valid.

scarv_ccx_memif.REQ if_ext            // External memory requests.

);

//
// CCX Parameters

parameter   ROM_BASE    = 32'h0000_0000; //! Base address of ROM
parameter   ROM_SIZE    = 32'h0000_0400; //! Size in bytes of ROM.
parameter   RAM_BASE    = 32'h0001_0000; //! Base address of RAM
parameter   RAM_SIZE    = 32'h0001_0000; //! Size in bytes of RAM.
parameter   MMIO_BASE   = 32'h0002_0000; //! Base address of MMIO.
parameter   MMIO_SIZE   = 32'h0000_0100; //! Size in bytes of MMIO
parameter   EXT_BASE    = 32'h1000_0000; //! Base address of EXT Mem.
parameter   EXT_SIZE    = 32'h1000_0000; //! Size in bytes of EXT Mem.

// Reset value for the mtimecmp memory mapped register.
parameter   MTIMECMP_RESET = 64'hFFFF_FFFF_FFFF_FFFF;

// Reset value for the program counter.
parameter   PC_RESET       = 32'b0;

/* verilator lint_off WIDTH */
//! Memory initialisation file for the ROM.
parameter [255*8-1:0] ROM_INIT_FILE = "rom.hex";
parameter [255*8-1:0] RAM_INIT_FILE = "ram.hex";
/* verilator lint_on WIDTH */

// Depth of the RAM in 32-bit words.
localparam RAM_DEPTH = RAM_SIZE / 4;

// Depth of the RAM in 32-bit words.
localparam ROM_DEPTH = ROM_SIZE / 4;


//
// CPU <-> Other modules wiring.
// ------------------------------------------------------------

//
// CPU trace interface

wire         cpu_instr_ret       ; // Instruction retired

//
// CPU interrupt interface.

wire         cpu_int_nmi         ; // Non-maskable interrupt.
wire         cpu_int_external    ; // External interrupt trigger line.
wire [ 3: 0] cpu_int_extern_cause; // External interrupt cause code.
wire         cpu_int_software    ; // Software interrupt trigger line.
wire         cpu_int_mtime       ; // Machine timer interrupt triggered.

//
// CPU counters.

wire [63: 0] cpu_ctr_time        ; // Current mtime counter value.
wire [63: 0] cpu_ctr_cycle       ; // Current cycle counter value.
wire [63: 0] cpu_ctr_instret     ; // Instruction retired counter value.
wire         cpu_ctr_inhibit_cy  ; // Stop cycle counter incrementing.
wire         cpu_ctr_inhibit_ir  ; // Stop instret incrementing.

//
// CPU memory interfaces.

scarv_ccx_memif #() cpu_imem();
scarv_ccx_memif #() cpu_dmem();

//
// TRNG wires
// TODO: Implement CCX level TRNG.
wire [31: 0] trng_pollentropy   ; // Value read by pollentropy instruciton.
wire         trng_read          ; // pollentropy access just happened.

//
// Interconnect interfaces and wires
// ------------------------------------------------------------

scarv_ccx_memif #() if_mmio ();

scarv_ccx_memif #() if_ram_a();
scarv_ccx_memif #() if_ram_b();

scarv_ccx_memif #() if_rom  ();

// RAM and ROM always accept requests immediately.
assign if_ram_a.gnt = 1'b1;
assign if_ram_b.gnt = 1'b1;
assign if_rom.gnt   = 1'b1;

assign if_rom.error = 1'b0;
assign if_ram_a.error = 1'b0;
assign if_ram_b.error = 1'b0;

//
// CPU Instance
// ------------------------------------------------------------

frv_core #(
.FRV_PC_RESET_VALUE(PC_RESET        )
) i_scarv_cpu (
.g_clk            (f_clk                  ), // global clock
.g_resetn         (g_resetn               ), // synchronous reset
.trs_pc           (cpu_trs_pc             ), // Trace program counter.
.trs_instr        (cpu_trs_instr          ), // Trace instruction.
.trs_valid        (cpu_trs_valid          ), // Trace output valid.
.instr_ret        (cpu_instr_ret          ), // Instruction retired
.int_nmi          (cpu_int_nmi            ), // Non-maskable interrupt.
.int_external     (cpu_int_external       ), // External interrupt trigger.
.int_extern_cause (cpu_int_extern_cause   ), // External interrupt cause code.
.int_software     (cpu_int_software       ), // Software interrupt.
.int_mtime        (cpu_int_mtime          ), // Machine timer interrupt.
.ctr_time         (cpu_ctr_time           ), // Current mtime counter value.
.ctr_cycle        (cpu_ctr_cycle          ), // Current cycle counter value.
.ctr_instret      (cpu_ctr_instret        ), // Instruction retired counter.
.ctr_inhibit_cy   (cpu_ctr_inhibit_cy     ), // Stop cycle counter increment.
.ctr_inhibit_ir   (cpu_ctr_inhibit_ir     ), // Stop instret incrementing.
.imem_req         (cpu_imem.req           ), // Start memory request
.imem_wen         (cpu_imem.wen           ), // Write enable
.imem_strb        (cpu_imem.strb          ), // Write strobe
.imem_wdata       (cpu_imem.wdata         ), // Write data
.imem_addr        (cpu_imem.addr          ), // Read/Write address
.imem_gnt         (cpu_imem.gnt           ), // request accepted
.imem_error       (cpu_imem.error         ), // Error
.imem_rdata       (cpu_imem.rdata         ), // Read data
.dmem_req         (cpu_dmem.req           ), // Start memory request
.dmem_wen         (cpu_dmem.wen           ), // Write enable
.dmem_strb        (cpu_dmem.strb          ), // Write strobe
.dmem_wdata       (cpu_dmem.wdata         ), // Write data
.dmem_addr        (cpu_dmem.addr          ), // Read/Write address
.dmem_gnt         (cpu_dmem.gnt           ), // request accepted
.dmem_error       (cpu_dmem.error         ), // Error
.dmem_rdata       (cpu_dmem.rdata         )  // Read data
);

//
// Interconnect Instance
// ------------------------------------------------------------

scarv_ccx_ic #(
.ROM_BASE (ROM_BASE     ),
.ROM_SIZE (ROM_SIZE     ),
.RAM_BASE (RAM_BASE     ),
.RAM_SIZE (RAM_SIZE     ),
.MMIO_BASE(MMIO_BASE    ),
.MMIO_SIZE(MMIO_SIZE    ),
.EXT_BASE (EXT_BASE     ),
.EXT_SIZE (EXT_SIZE     ) 
) i_interconnect (
.g_clk          (f_clk          ),
.g_resetn       (g_resetn       ),
.cpu_imem       (cpu_imem       ), // CPU instruction memory
.cpu_dmem       (cpu_dmem       ), // CPU data        memory
.if_rom         (if_rom         ),
.if_ram_a       (if_ram_a       ),
.if_ram_b       (if_ram_b       ),
.if_ext         (if_ext         ),
.if_mmio        (if_mmio        )
);


//
// Peripheral instances
// ------------------------------------------------------------


//
// instance: scarv_ccx_mmio
//
//  Memory mapped registers for the core complex.
//  Includes counters mtime and mtimecmp
//
scarv_ccx_mmio #(
.MMIO_BASE_ADDR     (MMIO_BASE      ),
.MMIO_SIZE          (MMIO_SIZE      ),
.MMIO_MTIMECMP_RESET(MTIMECMP_RESET )
) i_mmio (
.f_clk              (f_clk              ), // global clock
.g_resetn           (g_resetn           ), // synchronous reset
.instr_ret          (cpu_instr_ret      ), // Instruction retired.
.timer_interrupt    (cpu_int_mtime      ), // Raise a timer interrupt
.ctr_time           (cpu_ctr_time       ), // The time counter value.
.ctr_cycle          (cpu_ctr_cycle      ), // The cycle counter value.
.ctr_instret        (cpu_ctr_instret    ), // The instret counter value.
.inhibit_cy         (cpu_ctr_inhibit_cy ), // Stop cycle counter incrementing.
.inhibit_ir         (cpu_ctr_inhibit_ir ), // Stop instret incrementing.
.trng_pollentropy   (trng_pollentropy   ), // Value read by pollentropy instr.
.trng_read          (trng_read          ), // pollentropy just happened.
.mmio               (if_mmio            )  // MMIO memory request interface.
);

//
// Memory instances
// ------------------------------------------------------------

localparam RAM_AH = $clog2(RAM_DEPTH)+1;
localparam ROM_AH = $clog2(ROM_DEPTH)+1;

scarv_dual_ram #(
.DEPTH      (RAM_DEPTH      ),   // Depth of RAM in words
.WIDTH      (32             ),   // Width of a RAM word.
.INIT_FILE  (RAM_INIT_FILE  )
) i_ram (
.g_clk       (f_clk             ),
.g_resetn    (g_resetn          ),
.a_cen       (if_ram_a.req      ), // Start memory request
.a_wen       (if_ram_a.wen      ), // Write enable
.a_strb      (if_ram_a.strb     ), // Write strobe
.a_wdata     (if_ram_a.wdata    ), // Write data
.a_addr      (if_ram_a.addr[RAM_AH:2]     ), // Read/Write address
.a_rdata     (if_ram_a.rdata    ), // Read data
.b_cen       (if_ram_b.req      ), // Start memory request
.b_wen       (if_ram_b.wen      ), // Write enable
.b_strb      (if_ram_b.strb     ), // Write strobe
.b_wdata     (if_ram_b.wdata    ), // Write data
.b_addr      (if_ram_b.addr[RAM_AH:2]     ), // Read/Write address
.b_rdata     (if_ram_b.rdata    )  // Read data
);

scarv_single_rom #(
.DEPTH    (ROM_DEPTH    ),   // Depth of ROM in words
.WIDTH    (32           ),   // Width of a ROM word.
.INIT_FILE(ROM_INIT_FILE)    // Memory initialisaton file.
) i_rom (
.g_clk       (f_clk             ),
.g_resetn    (g_resetn          ),
.a_cen       (if_rom.req        ), // Start memory request
.a_addr      (if_rom.addr[ROM_AH:2]       ), // Read/Write address
.a_rdata     (if_rom.rdata      )  // Read data
);

endmodule
 
