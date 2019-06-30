
# Import yosys commands into TCL environment
yosys -import

read_verilog -formal $::env(FRV_HOME)/rtl/core/*.v
read_verilog -formal $::env(FRV_HOME)/verif/formal/fml_sram_if.v
read_verilog -formal $::env(FRV_HOME)/verif/formal/fml_sram_top.v

# Simple RTL synthesis
prep -top fml_sram_top;

# Create the SMT2 definition
write_smt2 -wires $::env(FRV_WORK)/formal/sram_check/model.smt2
