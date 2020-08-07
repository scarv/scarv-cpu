
//
// module: scarv_ccx_ic
//
//  Core complex memory interconnect. A very simple, completely combinatorial
//  memory interconnect.
//
//  Interconnection Matrix:
//
//      Peripheral  |   CPU IMem    | CPU DMem
//      ------------|---------------|-----------------
//      rom         |       x       |  x
//      ram_a       |       x       |   
//      ram_b       |               |  x
//      ext         |       x       |  x
//      mmio        |               |  x
//
module scarv_ccx_ic #(
parameter   ROM_BASE    = 32'h0000_0000,
parameter   ROM_SIZE    = 32'h0000_0400,
parameter   RAM_BASE    = 32'h0001_0000,
parameter   RAM_SIZE    = 32'h0001_0000,
parameter   MMIO_BASE   = 32'h0002_0000,
parameter   MMIO_SIZE   = 32'h0000_0100,
parameter   EXT_BASE    = 32'h1000_0000,
parameter   EXT_SIZE    = 32'h1000_0000 
)(

input  wire      g_clk      ,
input  wire      g_resetn   ,

scarv_ccx_memif.RSP cpu_imem   , // CPU instruction memory
scarv_ccx_memif.RSP cpu_dmem   , // CPU data        memory

scarv_ccx_memif.REQ if_rom     ,
scarv_ccx_memif.REQ if_ram_a   ,
scarv_ccx_memif.REQ if_ram_b   ,
scarv_ccx_memif.REQ if_ext     ,
scarv_ccx_memif.REQ if_mmio

);

//
// Internal bus routing wires.

scarv_ccx_memif #() cpu_imem_rom ();
scarv_ccx_memif #() cpu_imem_ext ();
scarv_ccx_memif #() cpu_imem_mmio();

scarv_ccx_memif #() cpu_dmem_rom ();
scarv_ccx_memif #() cpu_dmem_ext ();

//
// Router Instances
// ------------------------------------------------------------

//
// Instruction Memory Request Router.
scarv_ccx_ic_router #(
.ROM_BASE   (ROM_BASE   ),
.ROM_SIZE   (ROM_SIZE   ),
.RAM_BASE   (RAM_BASE   ),
.RAM_SIZE   (RAM_SIZE   ),
.MMIO_BASE  (MMIO_BASE  ),
.MMIO_SIZE  (MMIO_SIZE  ),
.EXT_BASE   (EXT_BASE   ),
.EXT_SIZE   (EXT_SIZE   ) 
) i_router_imem (
.g_clk      (g_clk          ),
.g_resetn   (g_resetn       ),
.if_core    (cpu_imem       ),
.if_rom     (cpu_imem_rom   ),
.if_ram     (if_ram_a       ),
.if_ext     (cpu_imem_ext   ),
.if_mmio    (cpu_imem_mmio  )
);

//
// Data Memory Request Router.
scarv_ccx_ic_router #(
.ROM_BASE   (ROM_BASE   ),
.ROM_SIZE   (ROM_SIZE   ),
.RAM_BASE   (RAM_BASE   ),
.RAM_SIZE   (RAM_SIZE   ),
.MMIO_BASE  (MMIO_BASE  ),
.MMIO_SIZE  (MMIO_SIZE  ),
.EXT_BASE   (EXT_BASE   ),
.EXT_SIZE   (EXT_SIZE   ) 
) i_router_dmem (
.g_clk      (g_clk          ),
.g_resetn   (g_resetn       ),
.if_core    (cpu_dmem       ),
.if_rom     (cpu_dmem_rom   ),
.if_ram     (if_ram_b       ),
.if_ext     (cpu_dmem_ext   ),
.if_mmio    (if_mmio        )
);

//
// Arbiter and stub Instances
// ------------------------------------------------------------

scarv_ccx_ic_arbiter i_arbiter_rom (
.g_clk      (g_clk          ),
.g_resetn   (g_resetn       ),
.req_0      (cpu_imem_rom   ), // Requestor 0 (primary)
.req_1      (cpu_dmem_rom   ), // Requestor 1 (primary)
.rsp        (if_rom         )  // Responder   (secondary)
);


scarv_ccx_ic_arbiter i_arbiter_ext (
.g_clk      (g_clk          ),
.g_resetn   (g_resetn       ),
.req_0      (cpu_imem_ext   ), // Requestor 0 (primary)
.req_1      (cpu_dmem_ext   ), // Requestor 1 (primary)
.rsp        (if_ext         )  // Responder   (secondary)
);

//
// Instruction memory MMIO stub responder. Always returns an error response.
scarv_ccx_ic_stub i_imem_mmio_stub(.memif(cpu_imem_mmio));

endmodule

