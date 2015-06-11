#!/bin/bash

#v1.0   format code. for version 1.0, code_formatter.sh did the following things:
#       1. convert tab to 4 spaces
#       2. remove spaces at the end of each line
#       the origin file is stored in $SH_DOC
#v1.1   2013-04-22
#       add two options:
#       -m: remove all ^M and ^Z chars in the file.
#       -b: print backup files.

DEBUG="true"
B_RM_MZ="false"
SH_DOC="$HOME/my_shellscript/sh_document"
SH_DOCUMENT=$SH_DOC/document$(date +%m%d)
BACKUP_DIR=$SH_DOCUMENT/code_formatter_backup
BACKUP_FILE=
TMP_FILE=/tmp/code_formatter_tmpfile_$(date +%m%d%H%M%S)

declare -a FILE_ARR
FILE_ARR_LENGTH=${#FILE_ARR[*]}

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

CLEAR_WORK() {
    if [ ! $FILE_ARR_LENGTH -eq 0 ]; then
        echo
        echo "* The following files have been formatted:"
        for f in ${FILE_ARR[*]}; do
            echo $f
        done
        echo
    fi
    
    if [ -e $TMP_DIR ]; then
        sudo rm -rf $TMP_FILE
    fi
}
trap "CLEAR_WORK" EXIT

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:
codeformatter.sh [-h] [-b]
codeformatter.sh [-m] file1 file2 ......

OPTIONS:
-h: show help
-b: print backup files
-m: remove ^Z and ^M chars (line break char /r/n)

DESCRIPTION:
Format code. The following changes will be commit to the given files:
    1. convert tab to 4 spaces"
    2. remove spaces at the end of each line"
    3. if -m option is specified, remove all ^Z and ^M chars
Origin files will be backuped, use codeformatter.sh -b to print bakup file path
--------------------------------------------------------------------------------

EOF
}

# add a new element to $FILE_ARR
# $1 should be the element, no matter what it is
function FileArrAdd() {
    FILE_ARR[$FILE_ARR_LENGTH]=$1
    FILE_ARR_LENGTH=${#FILE_ARR[*]}
}

# $1 should be full path of a file
function BackupOrigin() {
    if [ ! -f $1 ]; then
        echo "* Not a file, cannot backup"
        return 1
    fi
    [ ! -d $SH_DOCUMENT ] && mkdir $SH_DOCUMENT
    [ ! -d $BACKUP_DIR ] && mkdir $BACKUP_DIR
    file_name=$(basename $1)
    BACKUP_FILE=$BACKUP_DIR/${file_name}"."$(date +%m%d%H%M%S)".backup"
    cp $1 $BACKUP_FILE
}

#param should be $@
function ProcessParam() {
    if [ "$1" == "-h" -o $# -eq 0 ]; then
        ShellHelp
        exit 0
    fi
    
    if [ "$1" == "-b" ]; then
        echo
        echo "* backup files:"
        local bkupfiles=$(ls $BACKUP_DIR)
        for bkupfile in $bkupfiles; do
            echo $(readlink -f $bkupfile)
        done
        echo
        exit 0
    fi
    
    if [ "$1" == "-m" ]; then
        B_RM_MZ="true"
        shift
    fi
    
    for param in $@; do
        if [ -f $param ]; then
            full_path=$(readlink -f $param)
            full_dir=$(dirname $full_path)
            FileArrAdd $full_path
            BackupOrigin $full_path
            
            expand -t 4 $full_path | sed -e 's/[ ]*$//g' > $TMP_FILE
            if [ "$B_RM_MZ" == "true" ]; then
                tr -d '\015\032' < $TMP_FILE > $full_path
            else
                cp $TMP_FILE $full_path
            fi
        else
            echo "* All param should be files."
            ShellHelp
            exit 1
        fi
    done
}

ProcessParam $@

