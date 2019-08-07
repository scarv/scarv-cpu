ENTRY(_start);

SECTIONS {

    . = 0x80000000;

    .text : {
        *(.text._start);
        *(.text._passfail);
        *(.text*);
    }
    .data : { *(.data) }
    .bss  : { *(.bss) }

}
