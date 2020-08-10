
FSBL_CFLAGS  = -nostartfiles -Os -O2 -Wall -fpic -fPIC
FSBL_CFLAGS += -L$(FRV_HOME)/src/share/
FSBL_CFLAGS += -e __fsbl_start
FSBL_CFLAGS += -T$(FRV_HOME)/src/share/ccx-link-fsbl.ld
FSBL_CFLAGS += -march=rv32imc_xcrypto -mabi=ilp32

FSBL_BUILD  = $(FRV_WORK)/fsbl

#
# 1. FSBL name
define map_fsbl_dir
$(FSBL_BUILD)
endef

#
# 1. FSBL name
define map_fsbl_elf
$(call map_fsbl_dir,${1})/${1}.o
endef

#
# 1. FSBL name
define map_fsbl_objdump
$(call map_fsbl_dir,${1})/${1}.dis
endef

#
# 1. FSBL name
define map_fsbl_hex
$(call map_fsbl_dir,${1})/${1}.hex
endef

#
# 1. FSBL name
# 2. FSBL srcs
define add_fsbl_elf
$(call map_fsbl_elf,${1}) : ${2}
	@mkdir -p $(call map_fsbl_dir,${1})
	$(CC) $(FSBL_CFLAGS) -o $${@} $${^}
endef

#
# 1. FSBL name
# 2. FSBL srcs
define add_fsbl_objdump
$(call map_fsbl_objdump,${1}) : $(call map_fsbl_elf,${1})
	@mkdir -p $(call map_fsbl_dir,${1})
	$(OBJDUMP) -z -D $${<} > $${@} 
endef

#
# 1. FSBL name
# 2. FSBL srcs
define add_fsbl_hex
$(call map_fsbl_hex,${1}) : $(call map_fsbl_elf,${1})
	@mkdir -p $(call map_fsbl_dir,${1})
	$(OBJCOPY) --gap-fill 0 -O verilog $${<} $${@}
endef

#
# 1. FSBL Name
# 2. FSBL srcs
define add_fsbl_target
$(call add_fsbl_elf,${1},${2})
$(call add_fsbl_objdump,${1},${2})
$(call add_fsbl_hex,${1},${2})

build-fsbl-${1}: $(call map_fsbl_elf,${1})      \
                 $(call map_fsbl_objdump,${1})  \
                 $(call map_fsbl_hex,${1})
endef
