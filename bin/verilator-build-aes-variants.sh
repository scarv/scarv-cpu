#!/bin/bash

set -e
set -x

#
# 1. Variant name
# 2. XC_AES_VARIANT parameter number = {1,2,3,4}
function build_variant {
make VL_DIR=$FRV_WORK/verilator-aes-$1 \
     VL_VERILOG_PARAMETERS=-GXC_AES_VARIANT=$2
}

build_variant   v1  1
build_variant   v2  2
build_variant   v3  3
build_variant   v5  4

