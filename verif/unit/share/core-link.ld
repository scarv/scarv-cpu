
SECTIONS {

    . = 0x80000000;

    .text : { *(.text.*) }
    .data : { *(.data.*) }
    .bss  : { *(.bss) }

    /DISCARD/ : { *(.comment) }

    PROVIDE (__mmio_mtime_lo    =  0        );
    PROVIDE (__mmio_mtime_hi    =  4        );
    PROVIDE (__mmio_mtimecmp_lo =  8        );
    PROVIDE (__mmio_mtimecmp_hi = 12        );
    PROVIDE (__mmio_trng        = 16        );


}
