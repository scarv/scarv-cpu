
INCLUDE "ccx-link-memories.ld"

SECTIONS {

    . = ORIGIN(ram);

    .text : {
        *(.text.*)
        *(.text)
    } > ram
    .data  : { *(.data.*) } > ram
    .bss   : { *(.bss)    } > ram
    .sbss  : { *(.sbss)    } > ram

    /DISCARD/ : { *(.comment) }

    INCLUDE "ccx-link-provide.ld"
    INCLUDE "ccx-link-mmio.ld"

}

