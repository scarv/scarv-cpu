
yosys -import

# Read in the design
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/*.v
read_verilog $::env(XCRYPTO_RTL)/p_addsub/p_addsub.v
read_verilog $::env(XCRYPTO_RTL)/p_shfrot/p_shfrot.v
read_verilog $::env(XCRYPTO_RTL)/xc_malu/xc_malu.v
read_verilog $::env(XCRYPTO_RTL)/xc_malu/xc_malu_divrem.v
read_verilog $::env(XCRYPTO_RTL)/xc_malu/xc_malu_long.v
read_verilog $::env(XCRYPTO_RTL)/xc_malu/xc_malu_mul.v
read_verilog $::env(XCRYPTO_RTL)/xc_malu/xc_malu_muldivrem.v
read_verilog $::env(XCRYPTO_RTL)/xc_malu/xc_malu_pmul.v
read_verilog $::env(XCRYPTO_RTL)/xc_sha3/xc_sha3.v
read_verilog $::env(XCRYPTO_RTL)/xc_sha256/xc_sha256.v
read_verilog $::env(XCRYPTO_RTL)/xc_aessub/xc_aessub.v
read_verilog $::env(XCRYPTO_RTL)/xc_aessub/xc_aessub_sbox.v
read_verilog $::env(XCRYPTO_RTL)/xc_aesmix/xc_aesmix.v
read_verilog $::env(XCRYPTO_RTL)/b_bop/b_bop.v
read_verilog $::env(XCRYPTO_RTL)/b_lut/b_lut.v

# Synthesise processes ready for SCC check.
procs

# Check that there are no logic loops in the design early on.
tee -o $::env(FRV_WORK)/synth/logic-loops.rpt check -assert

# Generic yosys synthesis command
synth -top frv_core

# Print some statistics out
tee -o $::env(FRV_WORK)/synth/synth-statistics.rpt stat -width

# Write out the synthesised verilog
write_verilog $::env(FRV_WORK)/synth/synth-cells.v

dfflibmap -liberty $::env(YOSYS_ROOT)/techlibs/common/cells.lib
abc -liberty $::env(YOSYS_ROOT)/examples/cmos/cmos_cells.lib
tee -o $::env(FRV_WORK)/synth/synth-gates.rpt stat -tech cmos

write_verilog $::env(FRV_WORK)/synth-gates.v

