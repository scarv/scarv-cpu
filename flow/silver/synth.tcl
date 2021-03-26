
yosys -import

verilog_defines -DSILVER=1

read_verilog $::env(SILVER_VERILOG)
read_verilog -lib $::env(SILVER)/yosys/LIB/custom_cells.v

#setattr -set keep_hierarchy 1;
synth -top $::env(SILVER_TOP) -flatten
dfflibmap -liberty $::env(SILVER)/yosys/LIB/custom_cells.lib
abc -liberty $::env(SILVER)/yosys/LIB/custom_cells.lib
opt_clean

stat -liberty $::env(SILVER)/yosys/LIB/custom_cells.lib

#setattr -set keep_hierarchy 0;
flatten
select $::env(SILVER_TOP)
insbuf -buf BUF A Y
#show -format svg -prefix $::env(FRV_HOME)/work/silver -colors 1 -stretch

write_verilog -selected $::env(SILVER_NETLIST)

