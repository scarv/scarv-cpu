
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

    PROVIDE (__ccx_stack_start  = ORIGIN(ram) + LENGTH(ram) - 16);

    PROVIDE (__rom_begin        = ORIGIN(rom)               );
    PROVIDE (__rom_length       =               LENGTH(rom) );
    PROVIDE (__rom_end          = ORIGIN(rom) + LENGTH(rom) );

    PROVIDE (__ram_begin        = ORIGIN(ram)               );
    PROVIDE (__ram_length       =               LENGTH(ram) );
    PROVIDE (__ram_end          = ORIGIN(ram) + LENGTH(ram) );

    INCLUDE "ccx-link-mmio.ld"

}

