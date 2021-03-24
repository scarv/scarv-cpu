

yosys -import

# Read in the design
read_verilog -sv -I$::env(FRV_HOME)/rtl/sme  $::env(FRV_HOME)/rtl/sme/*.sv
read_verilog -sv -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/*.sv

# Synthesise processes ready for SCC check.
procs

# Generic yosys synthesis command
synth -top $::env(SYNTH_TOP)

# Map to CMOS cells
abc -g cmos

# Statistics: size and latency
flatten

# Simple optimisations
opt -full

# Write out the synthesised verilog
write_verilog $::env(FRV_WORK)/synth/synth-$::env(SYNTH_TOP).sv

tee -o $::env(FRV_WORK)/synth/synth-$::env(SYNTH_TOP).rpt stat -tech cmos
tee -a $::env(FRV_WORK)/synth/synth-$::env(SYNTH_TOP).rpt ltp  -noff


