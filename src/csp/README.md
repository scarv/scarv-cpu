
# Core Support Package (CSP)

*Details on the core support package library.*

---

The CSP is a very small library which contains useful functions and
constants for managing the `scarv-cpu` and associated Core Complex (CCX).
This includes:

- Accessors for the CSR registers.

- Constant codes useful for implementing trap handlers.

- Tools for configuring interrupts.

## Documentation

The CSP is documented using [Doxygen](https://www.doxygen.nl).
To re-generate the documentation, run:
```sh
make docs-csp
```
from the repository root.

The generated documentation will be placed in `work/doc/csp/html`.

