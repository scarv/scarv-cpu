
yosys -import

# Read in the design
read_verilog -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/*.v

# Synthesise processes ready for SCC check.
procs

# Check that there are no logic loops in the design early on.
tee -o $::env(FRV_WORK)/synth/logic-loops.rpt check -assert

# Generic yosys synthesis command
synth -top mrv_cpu

# Print some statistics out
tee -o $::env(FRV_WORK)/synth/synth-statistics.rpt stat -width

# Write out the synthesised verilog
write_verilog $::env(FRV_WORK)/synth/synth-cells.v

dfflibmap -liberty $::env(YOSYS_ROOT)/techlibs/common/cells.lib
abc -liberty $::env(YOSYS_ROOT)/examples/cmos/cmos_cells.lib
tee -o $::env(FRV_WORK)/synth/synth-gates.rpt stat

write_verilog $::env(FRV_WORK)/synth-gates.v

