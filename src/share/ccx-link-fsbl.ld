
ENTRY(__fsbl_start)

INCLUDE "ccx-link-memories.ld"

SECTIONS {

    . = ORIGIN(rom);

    .text : {
        *(.text.fsbl)
        *(.text.*)
        *(.text)
    } > rom
    .data  : { *(.data.*) } > rom
    .bss   : { *(.bss)    } > rom
    .sbss  : { *(.sbss)    } > rom

    /DISCARD/ : { *(.comment) }

    INCLUDE "ccx-link-provide.ld"
    INCLUDE "ccx-link-mmio.ld"

}

