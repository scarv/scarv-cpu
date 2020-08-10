
/*
 *  Linker Script file for defining where the memory mapped IO region of
 *  the core complex lives.
 */

PROVIDE(__ccx_mmio_start    = 0x00020000);
PROVIDE(__ccx_mmio_end      = 0x00020100);

