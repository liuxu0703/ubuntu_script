#!/bin/bash

#       AUTHOR : liuxu
#       THIS SHELL IS ENVIRONMENT INDEPENDENT

ITEM_BASE="LenovoTabletYT"
ITEM_SERIAL_BASE=2000000000
ITEM_SERIAL=

TARGET_COUNT=
TARGET_FILE=./${ITEM_BASE}_keybox_file.$(date +%m%d%H%M%S)

#====================================


function IsInteger() {
    local ret       #return value
    if [[ $1 =~ [0-9]+ ]]; then     #make sure input is interger
        ret="true"
    else
        ret="false"
    fi
    echo $ret
}


if [ $(IsInteger $1) == "false" ]; then
    echo "arg1 should be integer"
else
    TARGET_COUNT=$1
    for ((i=0; i<$TARGET_COUNT; ++i)); do
        let ITEM_SERIAL=ITEM_SERIAL_BASE+i
        #echo $ITEM_BASE$ITEM_SERIAL
        echo $ITEM_BASE$ITEM_SERIAL >> $TARGET_FILE
    done
    echo "keybox file generated:"
    echo $(readlink -f $TARGET_FILE)
fi



