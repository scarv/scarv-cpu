
yosys -import

# Don't synthesise the FPGA specific TRNG
verilog_defines -DNO_SYNTH_FPGA_TRNG=1

# Read in the design
read_verilog -sv -I$::env(FRV_HOME)/rtl/sme  $::env(FRV_HOME)/rtl/sme/*.sv
read_verilog -sv -I$::env(FRV_HOME)/rtl/core $::env(FRV_HOME)/rtl/core/*.sv

# Check that there are no logic loops in the design early on.
tee -o $::env(FRV_WORK)/synth/logic-loops.rpt check -assert

# Generic yosys synthesis command
synth -top frv_core -flatten

# Write out the synthesised verilog
write_verilog $::env(FRV_WORK)/synth/synth-core.sv

tee -o $::env(FRV_WORK)/synth/synth-core.rpt stat -tech cmos
tee -a $::env(FRV_WORK)/synth/synth-core.rpt ltp  -noff
