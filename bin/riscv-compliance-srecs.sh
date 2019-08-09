#!/bin/sh

VARIANTS="rv32i rv32im rv32imc"

OBJCOPY=$RISCV/bin/riscv32-unknown-elf-objcopy
DEST=$FRV_HOME/work/riscv-compliance

mkdir -p $DEST

for V in $VARIANTS
do

    SRC_DIR=$FRV_HOME/external/riscv-compliance/work/$V
    SRC_FILES=`find $SRC_DIR -executable -type f`

    mkdir -p $DEST/$V

    for F in $SRC_FILES
    do
        $OBJCOPY -O srec --srec-forceS3 $F $F.srec
        chmod -x $F.srec
        BNAME=`basename $F`
        grep "80.*:" $F.objdump \
            | grep -v ">:" | cut -c 11- | sed 's/\t//' \
            | sort | uniq | sed 's/ +/ /' | sed 's/\t/ /' \
            | sed 's/\(^....    \)    /0000\1/' \
            > $DEST/$V/$BNAME.gtkwl
        mv $F.srec $DEST/$V/$BNAME.srec
        echo $DEST/$V/$BNAME.srec
    done

done
