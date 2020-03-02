
export FRV_HOME=`pwd`
export FRV_WORK=$FRV_HOME/work

if [[ -z "$RISCV" ]]; then
    export RISCV=/opt/riscv32
fi

if [[ -z "$VERILATOR_ROOT" ]]; then
    export VERILATOR_ROOT=/home/ben/tools/verilator
fi

if [[ -z "$XCRYPTO_RTL" ]]; then
    export XCRYPTO_RTL=$FRV_HOME/external/xcrypto/rtl
fi

export PATH=$RISCV:$PATH

echo "------------------------[CPU Project Setup]--------------------------"
echo "\$FRV_HOME       = $FRV_HOME"
echo "\$FRV_WORK       = $FRV_WORK"
echo "\$RISCV          = $RISCV"
echo "\$XCRYPTO_RTL    = $XCRYPTO_RTL"
echo "\$VERILATOR_ROOT = $VERILATOR_ROOT"
echo "\$YOSYS_ROOT     = $YOSYS_ROOT"
echo "\$PATH           = $PATH"
echo "---------------------------------------------------------------------"
