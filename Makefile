
ifndef FRV_HOME
    $(error "Please run 'source ./bin/source.me.sh' to setup the project workspace")
endif
ifndef RISCV
    $(error "Please set the RISCV environment variable")
endif
ifndef XCRYPTO_RTL
    $(error "Please set the XCRYPTO_RTL environment variable")
endif

AES_VAR_RTL_DIR     = $(FRV_HOME)/../../rtl/aes

export CPU_RTL_DIR  = $(FRV_HOME)/rtl/core
export CPU_RTL_SRCS = $(shell find $(CPU_RTL_DIR) -name *.v) \
                      $(XCRYPTO_RTL)/p_addsub/p_addsub.v \
                      $(XCRYPTO_RTL)/p_shfrot/p_shfrot.v \
                      $(XCRYPTO_RTL)/xc_sha3/xc_sha3.v \
                      $(XCRYPTO_RTL)/xc_sha256/xc_sha256.v \
                      $(XCRYPTO_RTL)/xc_aessub/xc_aessub.v \
                      $(XCRYPTO_RTL)/xc_aessub/xc_aessub_sbox.v \
                      $(XCRYPTO_RTL)/xc_aesmix/xc_aesmix.v \
                      $(XCRYPTO_RTL)/xc_malu/xc_malu.v \
                      $(XCRYPTO_RTL)/xc_malu/xc_malu_divrem.v \
                      $(XCRYPTO_RTL)/xc_malu/xc_malu_long.v \
                      $(XCRYPTO_RTL)/xc_malu/xc_malu_mul.v \
                      $(XCRYPTO_RTL)/xc_malu/xc_malu_pmul.v \
                      $(XCRYPTO_RTL)/xc_malu/xc_malu_muldivrem.v \
                      $(XCRYPTO_RTL)/b_bop/b_bop.v \
                      $(XCRYPTO_RTL)/b_lut/b_lut.v

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
include $(FRV_HOME)/flow/xcfi-formal/Makefile.in
include $(FRV_HOME)/flow/yosys/Makefile.in
include $(FRV_HOME)/flow/embench/Makefile.in
include $(FRV_HOME)/src/fsbl/Makefile.in
include $(FRV_HOME)/verif/unit/Makefile.in

clean:
	rm -rf work/*
