#!/bin/bash

set -e
set -x

#
# 1. Variant name
# 2. XC_AES_VARIANT parameter number = {1,2,3,4}
function build_variant {
    make -B build-unit-aes-${1}
    make run-unit-aes-${1} \
        VL_DIR=$FRV_HOME/work/verilator-aes-${1} \
        VL_VERILOG_PARAMETERS="-GXC_AES_VARIANT=$2 -GXC_CLASS_AES=1\'b1" \
        UNIT_TIMEOUT=200000 \
        UNIT_IMEM_MAX_STALL=0 UNIT_DMEM_MAX_STALL=0
}

build_variant   v1  1
build_variant   v2  2
build_variant   v3  3
build_variant   v5  4

grep -Irn "\!>" work/unit/ | sed 's/work.*\///' | sed 's/\.log.*> /,/' \
    | sort > $FRV_WORK/aes-variants-cycles.csv

grep -Irn "\?>" work/unit/ | sed 's/work.*\///' | sed 's/\.log.*> /,/' \
    | sort > $FRV_WORK/aes-variants-insret.csv
