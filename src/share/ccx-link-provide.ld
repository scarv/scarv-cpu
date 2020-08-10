

PROVIDE (__ccx_stack_start  = ORIGIN(ram) + LENGTH(ram) - 16);

PROVIDE (__rom_begin        = ORIGIN(rom)               );
PROVIDE (__rom_length       =               LENGTH(rom) );
PROVIDE (__rom_end          = ORIGIN(rom) + LENGTH(rom) );

PROVIDE (__ram_begin        = ORIGIN(ram)               );
PROVIDE (__ram_length       =               LENGTH(ram) );
PROVIDE (__ram_end          = ORIGIN(ram) + LENGTH(ram) );

PROVIDE (__mmio_begin       = ORIGIN(mmio)              );
PROVIDE (__mmio_end         = ORIGIN(mmio)+ LENGTH(mmio));

PROVIDE (__mmio_mtime_lo    = __mmio_begin  +  0        );
PROVIDE (__mmio_mtime_hi    = __mmio_begin  +  4        );
PROVIDE (__mmio_mtimecmp_lo = __mmio_begin  +  8        );
PROVIDE (__mmio_mtimecmp_hi = __mmio_begin  + 12        );
PROVIDE (__mmio_trng        = __mmio_begin  + 16        );
