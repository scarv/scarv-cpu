
export FRV_HOME=`pwd`
export FRV_WORK=$FRV_HOME/work
export SCARV_CPU=$FRV_HOME
export AES_RTL_DIR=$FRV_HOME/../../rtl/aes

if [[ -z "$RISCV" ]]; then
    export RISCV=/opt/riscv
fi

if [[ -z "$VERILATOR_ROOT" ]]; then
    export VERILATOR_ROOT=/opt/eda/verilator
fi

if [[ -z "$XCRYPTO_RTL" ]]; then
    export XCRYPTO_RTL=$FRV_HOME/external/xcrypto/rtl
fi

if [[ -z "$SYMBIYOSYS_PATH" ]]; then
    export SYMBIYOSYS_PATH=/opt/eda/symbiyosys
    export SYMBIYOSYS_BIN=$SYMBIYOSYS_PATH/bin/sby
fi

if [[ -z "$BOOLECTOR_PATH" ]]; then
    export BOOLECTOR_PATH=/opt/eda/boolector/build/bin
fi

if [[ -z "$YOSYS_ROOT" ]]; then
    export YOSYS_ROOT=/opt/eda/Yosys
fi

export PATH=$RISCV:$BOOLECTOR_PATH:$PATH

echo "------------------------[CPU Project Setup]--------------------------"
echo "\$FRV_HOME       = $FRV_HOME"
echo "\$FRV_WORK       = $FRV_WORK"
echo "\$RISCV          = $RISCV"
echo "\$XCRYPTO_RTL    = $XCRYPTO_RTL"
echo "\$VERILATOR_ROOT = $VERILATOR_ROOT"
echo "\$YOSYS_ROOT     = $YOSYS_ROOT"
echo "\$SYMBIYOSYS_BIN = $SYMBIYOSYS_BIN"
echo "\$BOOLECTOR_PATH = $BOOLECTOR_PATH"
echo "\$PATH           = $PATH"
echo "---------------------------------------------------------------------"
