
ifndef FRV_HOME
    $(error "Please run 'source ./bin/source.me.sh' to setup the project workspace")
endif
ifndef RISCV
    $(error "Please set the RISCV environment variable")
endif
ifndef XCRYPTO_RTL
    $(error "Please set the XCRYPTO_RTL environment variable")
endif

export PATH:=$(RISCV)/bin:$(YOSYS_ROOT)/:$(PATH)

YOSYS       = $(YOSYS_ROOT)/yosys
YOSYS_SMTBMC= $(YOSYS_ROOT)/yosys-smtbmc

CC              = $(RISCV)/bin/riscv64-unknown-elf-gcc
AS              = $(RISCV)/bin/riscv64-unknown-elf-as
AR              = $(RISCV)/bin/riscv64-unknown-elf-ar
OBJDUMP         = $(RISCV)/bin/riscv64-unknown-elf-objdump
OBJCOPY         = $(RISCV)/bin/riscv64-unknown-elf-objcopy

include $(FRV_HOME)/flow/verilator/Makefile.in
include $(FRV_HOME)/flow/compliance/Makefile.in
include $(FRV_HOME)/flow/riscv-formal/Makefile.in
include $(FRV_HOME)/flow/designer-assertions/Makefile.in
#include $(FRV_HOME)/flow/xcfi-formal/Makefile.in
include $(FRV_HOME)/flow/yosys/Makefile.in
include $(FRV_HOME)/flow/embench/Makefile.in

include $(FRV_HOME)/src/share/fsbl.mk
include $(FRV_HOME)/src/fsbl-ccx-test/Makefile.in
include $(FRV_HOME)/src/fsbl-fpga/Makefile.in
include $(FRV_HOME)/src/csp/Makefile.in

include $(FRV_HOME)/verif/unit/Makefile.in

# depends on verif/unit/Makefile.in
include $(FRV_HOME)/src/benchmarks/Makefile.in

clean:
	rm -rf work/*
