
yosys -import

# Read in the design
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/*.v

# Synthesise processes ready for SCC check.
procs

# Check that there are no logic loops in the design early on.
tee -o $::env(FRV_WORK)/synth/logic-loops.rpt check -assert

# Generic yosys synthesis command
synth -top frv_core

# Map to CMOS cells
abc -g cmos4

# Simple optimisations
opt -fast

# Write out the synthesised verilog
write_verilog $::env(FRV_WORK)/synth/frv_core_synth.v

# Statistics: size and latency
flatten
tee -o $::env(FRV_WORK)/synth/synth-cmos.rpt stat
tee -a $::env(FRV_WORK)/synth/synth-cmos.rpt ltp  -noff
