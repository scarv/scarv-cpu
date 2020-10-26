#!/bin/bash

set -e
set -x

#
# Pick one of these!
OPTIMISATION_GOAL=size
#OPTIMISATION_GOAL=latency

#
# 1. Variant name
# 2. XC_AES_VARIANT parameter number = {1,2,3,4}
# 3. Build synthesised core.
# 4. Use word aligned aes variant
# 5. Enable decryption
function build_variant {
    make -B build-unit-aes-${1} \
        AES_WORD_ALIGNED=${4}

    make -B run-unit-aes-${1} \
        VL_DIR=$FRV_WORK/verilator-aes-${1} \
        VL_VERILOG_PARAMETERS="-GXC_AES_VARIANT=$2 -GXC_CLASS_AES=1\'b1 -DXC_AES_OPT_GOAL=$OPTIMISATION_GOAL" \
        UNIT_TIMEOUT=200000 \
        UNIT_IMEM_MAX_STALL=0 UNIT_DMEM_MAX_STALL=0

    if [ ${3} -eq 1 ] ; then
        rm -rf $FRV_WORK/synth-aes-${1}-$5
        make synthesise \
            XC_CLASS_AES=1 \
            XC_AES_VARIANT=$2 \
            XC_AES_DECRYPT=$5 \
            XC_AES_OPT_GOAL=$OPTIMISATION_GOAL
        mv $FRV_WORK/synth $FRV_WORK/synth-aes-${1}-$5
    fi
}

build_variant   ref-bytewise    0   0   1  0
build_variant   ref-ttable      0   0   1  0

build_variant   v1              1   1   1  0
build_variant   v1              1   1   1  1

build_variant   v2              2   1   1 0
build_variant   v3              3   1   1 0
build_variant   v5              4   1   1 0

build_variant   v2              2   1   1 1
build_variant   v3              3   1   1 1
build_variant   v5              4   1   1 1

make synthesise \
    XC_CLASS_AES=0 \
    XC_AES_VARIANT=0 \
    XC_AES_DECRYPT=0 \
    XC_AES_OPT_GOAL=$OPTIMISATION_GOAL

grep -Irn "\!>" work/unit/ | sed 's/work.*\///' | sed 's/\.log.*> /,/' \
    | sort > $FRV_WORK/aes-variants-cycles.csv

grep -Irn "\?>" work/unit/ | sed 's/work.*\///' | sed 's/\.log.*> /,/' \
    | sort > $FRV_WORK/aes-variants-insret.csv

grep -Irn "@>" work/unit/ | sed 's/work.*\///' | sed 's/\.log.*> /,/' \
    | sort > $FRV_WORK/aes-variants-perf.csv

grep -Irn "Estimated number of" work/synth* | grep "synth-cell" \
    | sort > $FRV_WORK/aes-variants-cells.rpt

echo "Var, KSE,KSD,Enc,Dec" > $FRV_WORK/aes-variants-cycles-dec.csv
$FRV_HOME/bin/aes-variants-graphs.py $FRV_WORK/aes-variants-cycles.csv >> \
    $FRV_WORK/aes-variants-cycles-dec.csv

echo "Var, KSE,KSD,Enc,Dec" > $FRV_WORK/aes-variants-insret-dec.csv
$FRV_HOME/bin/aes-variants-graphs.py $FRV_WORK/aes-variants-insret.csv >> \
    $FRV_WORK/aes-variants-insret-dec.csv

echo "Var, KSE,KSD,Enc,Dec" > $FRV_WORK/aes-variants-perf-dec.csv
$FRV_HOME/bin/aes-variants-graphs.py $FRV_WORK/aes-variants-perf.csv >> \
    $FRV_WORK/aes-variants-perf-dec.csv
