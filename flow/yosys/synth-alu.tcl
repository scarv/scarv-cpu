

yosys -import

# Read in the design
read_verilog -sv -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/frv_alu.sv

# Synthesise processes ready for SCC check.
procs

# Generic yosys synthesis command
synth -top frv_alu

# Map to CMOS cells
abc -g cmos4

# Statistics: size and latency
flatten

# Simple optimisations
opt -full

# Write out the synthesised verilog
write_verilog $::env(FRV_WORK)/synth/synth-alu.sv

tee -o $::env(FRV_WORK)/synth/synth-alu.rpt stat -tech cmos
tee -a $::env(FRV_WORK)/synth/synth-alu.rpt ltp  -noff
