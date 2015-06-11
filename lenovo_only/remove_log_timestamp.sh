#!/bin/bash

#       AUTHOR : liuxu
#       THIS SHELL IS ENVIRONMENT INDEPENDENT

#remove time stamp from an android log

SH_DOCUMENT="/home/liuxu/my_shellscript/sh_document/document"$(date +%m%d)
OUTPUT_FILE=
DEBUG="false"

#====================================

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

ERRORTRAP() {
    local shell_name=`basename $0`
    echo "==================="
    echo "MY SHELL ERROR: "
    echo "NAME: $shell_name"
    echo "ERRNO: $?"
    echo "==================="
}
trap "ERRORTRAP" ERR

CLEAR_WORK() {
    if [ -e $TMP_DIR ]; then
        sudo rm -rf $TMP_DIR
    fi
}
trap "CLEAR_WORK" EXIT

function ShellHelp() {
    local shell_name=`basename $0`
    echo
    echo "NAME:"
    echo "$shell_name: "
    echo
    echo "DESCRIPTION:"
    echo "remove time stamp, uid and pid from an android log."
    echo "this is for the convenience of comparing logs"
    echo
    echo "OPTIONS:"
    echo "None"
    echo
    echo "USAGE:"
    echo
}

if [ ! -f $1 ]; then
    echo "param should be full path of a file."
    exit 1
fi

if [ ! -d $SH_DOCUMENT ]; then
    mkdir $SH_DOCUMENT
fi

OUTPUT_FILE=$SH_DOCUMENT/$(basename $1)"_rm_timestamp_"$(date +%m%d%H%M%S)
DEBUG echo "SH_DOCUMENT : $SH_DOCUMENT"
DEBUG echo "OUTPUT_F$OUTPUT_FILEILE : $OUTPUT_FILE"

awk '{$1=$2=$3=$4=""; print}' $1 > $OUTPUT_FILE

echo $OUTPUT_FILE
