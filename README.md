# [SCARV](https://github.com/scarv/scarv): processor core implementation 

<!--- -------------------------------------------------------------------- --->

*Acting as a component part of the wider
[SCARV](https://www.scarv.org)
project,
the
[RISC-V](https://riscv.org)
compatible SCARV micro-controller
(comprising a processor core and SoC)
is the eponymous, capstone output,
e.g., representing a demonstrator for the
research oriented
[XCrypto](https://github.com/scarv/xcrypto)
ISE
and the industry oriented [RISC-V Scalar Cryptography ISE](https://github.com/riscv/riscv-crypto).
The main
[repository](https://github.com/scarv/scarv)
acts as a general container for associated resources;
this specific submodule houses
the 
processor core
implementation.*

<!--- -------------------------------------------------------------------- --->

**Branches:**
- [![Build Status](https://travis-ci.org/scarv/scarv-cpu.svg?branch=master)](https://travis-ci.org/scarv/scarv-cpu)
  [`master`](https://github.com/scarv/scarv-cpu/) - 
  Main branch for XCrypto related work.
- [![Build Status](https://travis-ci.org/scarv/scarv-cpu.svg?branch=riscv%2Fcrypto-ise)](https://travis-ci.org/scarv/scarv-cpu/branches)
  [`riscv/crypto-ise`](https://github.com/scarv/scarv-cpu/tree/riscv/crypto-ise) - 
  Main branch for RISC-V Crypto ISE implementation.
- [![Build Status](https://travis-ci.org/scarv/scarv-cpu.svg?branch=scarv%2Fskywater%2Fmain)](https://travis-ci.org/scarv/scarv-cpu/branches)
  [`scarv/skywater/main`](https://github.com/scarv/scarv-cpu/tree/scarv/skywater/main) - 
  Main branch for Skywater tapeout project.
- [![Build Status](https://travis-ci.org/scarv/scarv-cpu.svg?branch=dev%2Fpaper%2Faes-n-ways)](https://travis-ci.org/scarv/scarv-cpu/branches)
  [`dev/paper/aes-n-ways`](https://github.com/scarv/scarv-cpu/tree/dev/paper/aes-n-ways) - 
  Development branch for RISC-V AES ISE Evaluation.
- [![Build Status](https://travis-ci.org/scarv/scarv-cpu.svg?branch=scarv%2Fxcrypto%2Fmasking-ise)](https://travis-ci.org/scarv/scarv-cpu/branches)
  [`scarv/xcrypto/masking-ise`](https://github.com/scarv/scarv-cpu/tree/scarv/xcrypto/masking-ise) - 
  Development branch for Software masking ISE.

<!--- -------------------------------------------------------------------- --->

**Contents:**
- [Overview](#Overview)
- [Documentation](#Documentation)
- [Quickstart](#Quickstart)
- [Acknowledgements](#Acknowledgements)

## Overview

This is a 5-stage single issue in order CPU core, implementing the
RISC-V 32-bit integer base architecture, along with the **C**ompressed
and **M**ultiply extensions.
It's a micro-controller, with no cache, branch prediction or
virtual memory.

![Pipeline Diagram](docs/scarv-cpu-uarch.png)

## Documentation

See the `docs/` folder for information on the design requirements and
the pipeline structure.

- [Design Requirements](docs/requirements.md)
- [Functional Verification](docs/verification.md)
- Implementation Documentation:
  - [Instruction Table](docs/instr-table.md)
  - [Pipeline Structure](docs/pipeline.md)
  - [Leakage Fence Instruction Implementation](docs/leakage-fence.md)
  - [Random Number Generator Interface](docs/rng-interface.md)

## Quickstart

- Install the following tools installed to use all parts of the
  design flow:

  - [Verilator](https://www.veripool.org/projects/verilator/)

  - [Yosys](http://www.clifford.at/yosys/)

  - [SymbiYosys](https://symbiyosys.readthedocs.io/en/latest/index.html)

  - [A Toolchain](https://github.com/scarv/riscv-gnu-toolchain) which
    supports the
    [XCrypto](https://github.com/scarv/xcrypto)
    instruction set extension.

- Checkout the repository and required submodules.

    ```sh
    $> git clone git@github.com:scarv-cpu/scarv-cpu.git
    $> cd scarv-cpu/
    $> git submodule update --init --remote
    ```

- Setup tool environment variables.

    ```sh
    $> export YOSYS_ROOT=<path to yosys installation>
    $> export RISCV=<path to toolchain installation>
    ```

- Configure the project environment.

    ```sh
    $> source bin/conf.sh
    ```

- Build the verilator simulation model:

    ```sh
    $> make verilator_build
    ```

- Run the basic RISC-V compliance tests:

    ```sh
    $> make riscv-compliance-build
    $> make riscv-compliance-run
    ```

- Run the standard Yosys Synthesis flow:

    ```sh
    $> make synthesise
    ```

<!--- -------------------------------------------------------------------- --->

## Acknowledgements

This work has been supported in part by EPSRC via grant 
[EP/R012288/1](https://gow.epsrc.ukri.org/NGBOViewGrant.aspx?GrantRef=EP/R012288/1),
under the [RISE](http://www.ukrise.org) programme.

<!--- -------------------------------------------------------------------- --->
