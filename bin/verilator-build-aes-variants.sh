#!/bin/bash

set -e
set -x

#
# 1. Variant name
# 2. XC_AES_VARIANT parameter number = {1,2,3,4}
function build_variant {
    make -B build-unit-aes-${1} \
        AES_WORD_ALIGNED=1
    make run-unit-aes-${1} \
        VL_DIR=$FRV_WORK/verilator-aes-${1} \
        VL_VERILOG_PARAMETERS="-GXC_AES_VARIANT=$2 -GXC_CLASS_AES=1\'b1" \
        UNIT_TIMEOUT=200000 \
        UNIT_IMEM_MAX_STALL=0 UNIT_DMEM_MAX_STALL=0

    if [ ${3} -eq 1 ] ; then
        rm -rf $FRV_WORK/synth-aes-${1}
        make synthesise XC_CLASS_AES=1 XC_AES_VARIANT=$2
        mv $FRV_WORK/synth $FRV_WORK/synth-aes-${1}
    fi
}

build_variant   ref-bytewise    0   0
build_variant   ref-ttable      0   0
build_variant   v1              1   1
build_variant   v2              2   1
build_variant   v3              3   1
build_variant   v5              4   1

make synthesise XC_CLASS_AES=0 XC_AES_VARIANT=0

grep -Irn "\!>" work/unit/ | sed 's/work.*\///' | sed 's/\.log.*> /,/' \
    | sort > $FRV_WORK/aes-variants-cycles.csv

grep -Irn "\?>" work/unit/ | sed 's/work.*\///' | sed 's/\.log.*> /,/' \
    | sort > $FRV_WORK/aes-variants-insret.csv

grep -Irn "Estimated number of" work/synth* | grep "synth-cell" \
    | sort > $FRV_WORK/aes-variants-cells.rpt

echo "Var, KSE,KSD,Enc,Dec" > $FRV_WORK/aes-variants-cycles-dec.csv
$FRV_HOME/bin/aes-variants-graphs.py $FRV_WORK/aes-variants-cycles.csv >> \
    $FRV_WORK/aes-variants-cycles-dec.csv

echo "Var, KSE,KSD,Enc,Dec" > $FRV_WORK/aes-variants-insret-dec.csv
$FRV_HOME/bin/aes-variants-graphs.py $FRV_WORK/aes-variants-insret.csv >> \
    $FRV_WORK/aes-variants-insret-dec.csv

