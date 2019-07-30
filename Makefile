
ifndef FRV_HOME
    $(error "Please run 'source ./bin/source.me.sh' to setup the project workspace")
endif
ifndef RISCV
    $(error "Please set the RISCV environment variable")
endif

export CPU_RTL_DIR  = $(FRV_HOME)/rtl/core
export CPU_RTL_SRCS = $(shell find $(CPU_RTL_DIR) -name *.v)

export PATH:=$(RISCV)/bin:$(YOSYS_ROOT)/:$(PATH)

YOSYS       = $(YOSYS_ROOT)/yosys
YOSYS_SMTBMC= $(YOSYS_ROOT)/yosys-smtbmc

CC              = $(RISCV)/bin/riscv32-unknown-elf-gcc
AS              = $(RISCV)/bin/riscv32-unknown-elf-as
AR              = $(RISCV)/bin/riscv32-unknown-elf-ar
OBJDUMP         = $(RISCV)/bin/riscv32-unknown-elf-objdump
OBJCOPY         = $(RISCV)/bin/riscv32-unknown-elf-objcopy

include $(FRV_HOME)/flow/verilator/Makefile.in
include $(FRV_HOME)/flow/compliance/Makefile.in
include $(FRV_HOME)/flow/riscv-formal/Makefile.in
include $(FRV_HOME)/flow/formal/Makefile.in
include $(FRV_HOME)/flow/yosys/Makefile.in
include $(FRV_HOME)/flow/embench/Makefile.in
include $(FRV_HOME)/src/fsbl/Makefile.in
include $(FRV_HOME)/verif/unit/Makefile.in

clean:
	rm -rf work/*
