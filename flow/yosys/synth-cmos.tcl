
yosys -import

# Read in the design
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_core.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_counters.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_pipeline.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_pipeline_decode.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_pipeline_execute.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_pipeline_fetch.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_pipeline_memory.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_pipeline_register.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_pipeline_writeback.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_alu.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_asi.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_bitwise.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_common.vh
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_core_fetch_buffer.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_csrs.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_gprs.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_interrupts.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_leak.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_lsu.v
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_rngif.v
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
read_verilog $::env(FRV_HOME)/../../rtl/aes/share/aes_sbox_shared.v 
read_verilog $::env(FRV_HOME)/../../rtl/aes/share/aes_mixcolumn.v 
read_verilog $::env(FRV_HOME)/../../rtl/aes/v1/aes_v1_latency.v 
read_verilog $::env(FRV_HOME)/../../rtl/aes/v2/aes_v2_latency.v
read_verilog $::env(FRV_HOME)/../../rtl/aes/v3/aes_v3_1.v
read_verilog $::env(FRV_HOME)/../../rtl/aes/tiled/aes_tiled.v

hierarchy

# Synthesise processes ready for SCC check.
procs

# Check that there are no logic loops in the design early on.
tee -o $::env(FRV_WORK)/synth/logic-loops.rpt check -assert

# Generic yosys synthesis command
synth -top frv_core

# Write out the synthesised verilog
write_verilog $::env(FRV_WORK)/synth/synth-cells.v

abc -g cmos
opt fast
flatten

# Statistics: size and latency
tee -o $::env(FRV_WORK)/synth/synth-cells.rpt stat -tech cmos

write_verilog $::env(FRV_WORK)/synth-gates.v

