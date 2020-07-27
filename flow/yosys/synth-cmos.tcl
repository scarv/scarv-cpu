
yosys -import

# Read in the design
read_verilog -sv -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/*.sv

# Synthesise processes ready for SCC check.
procs

# Check that there are no logic loops in the design early on.
tee -o $::env(FRV_WORK)/synth/logic-loops.rpt check -assert

# Generic yosys synthesis command
synth -top frv_core

# Map to CMOS cells
abc -g cmos4

# Statistics: size and latency
flatten

# Simple optimisations
opt -full

# Write out the synthesised verilog
write_verilog $::env(FRV_WORK)/synth/frv_core_synth.sv

tee -o $::env(FRV_WORK)/synth/synth-cmos.rpt stat
tee -a $::env(FRV_WORK)/synth/synth-cmos.rpt ltp  -noff
