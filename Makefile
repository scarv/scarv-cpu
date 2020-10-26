
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
                      $(XCRYPTO_RTL)/b_lut/b_lut.v \
                      $(AES_VAR_RTL_DIR)/share/aes_sbox_shared.v \
                      $(AES_VAR_RTL_DIR)/share/aes_mixcolumn.v \
                      $(AES_VAR_RTL_DIR)/v1/aes_v1_latency.v \
                      $(AES_VAR_RTL_DIR)/v1/aes_v1_size.v \
                      $(AES_VAR_RTL_DIR)/v2/aes_v2_latency.v \
                      $(AES_VAR_RTL_DIR)/v2/aes_v2_size.v \
                      $(AES_VAR_RTL_DIR)/v3/aes_v3_1.v \
                      $(AES_VAR_RTL_DIR)/tiled/aes_tiled_size.v \
                      $(AES_VAR_RTL_DIR)/tiled/aes_tiled_latency.v

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

#
# 1. Variant Name
# 2. Variant Number
# 3. Optmisation Goal.
define run_aesvar
run-sim-${1}-${3} :
	$(MAKE) -B run-unit-aes-${1} \
      VL_DIR=${FRV_WORK}/verilator-aes-${1}-${3} \
      VL_VERILOG_PARAMETERS="-DXC_AES_OPT_GOAL=${3} -GXC_AES_VARIANT=${2} -GXC_CLASS_AES=1\'b1" \
      UNIT_TIMEOUT=200000 \
      UNIT_IMEM_MAX_STALL=0 \
      UNIT_DMEM_MAX_STALL=0
endef

$(eval $(call run_aesvar,v1,1,size))
$(eval $(call run_aesvar,v1,1,latency))
$(eval $(call run_aesvar,v2,2,size))
$(eval $(call run_aesvar,v2,2,latency))
$(eval $(call run_aesvar,v3,3,latency))
$(eval $(call run_aesvar,v5,4,size))
$(eval $(call run_aesvar,v5,4,latency))

clean:
	rm -rf work/*
