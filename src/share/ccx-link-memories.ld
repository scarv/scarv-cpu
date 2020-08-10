
/*
 *  Linker Script file for defining the physical layout of memories.
 */

MEMORY {
    rom ( rx)    : ORIGIN = 0x00000000, LENGTH = 1K
    ram (wrx)    : ORIGIN = 0x00010000, LENGTH = 64K
    mmio(wr )    : ORIGIN = 0x00020000, LENGTH = 1K
}

