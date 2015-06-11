#!/bin/bash

function backup() {
    local BACKUP_DIR=$HOME/backup_dir
    local BACKUP_SUFFIX="bkp"
    local BACKUP_INFO_FILE="~backup_infos"
    
    local day=$(date +%F)
    local time=$(date +%H%M%S)
    
    if [ $# -eq 0 ]; then
        echo "backup usage:"
        echo "backup file   : backup the given file or dir"
        echo "backup -l     : list backup files for today"
        return
    fi
    
    if [ "$1" == "-l" ]; then
        if [ -f $BACKUP_DIR/$day/$BACKUP_INFO_FILE ]; then
            cat $BACKUP_DIR/$day/$BACKUP_INFO_FILE
        else
            echo "* no backup files for today yet"
        fi
        return
    fi
    
    if [ ! -e "$1" ]; then
        echo "* the given path does not exists."
        return
    fi
    
    if [ ! -d $BACKUP_DIR ]; then
        mkdir $BACKUP_DIR
    fi
    if [ ! -d $BACKUP_DIR/$day ]; then
        mkdir $BACKUP_DIR/$day
    fi
    
    local param=$1
    local full_path=$(readlink -f $param)
    local file_name=$(basename $full_path)
    local backup_path=$BACKUP_DIR/$day/$file_name"."$time"."$BACKUP_SUFFIX
    cp -r $full_path $backup_path
    
    if [ $? -eq 0 ]; then
        echo "$full_path  -->  $backup_path" >> $BACKUP_DIR/$day/$BACKUP_INFO_FILE
        echo "backup success."
        echo "origin: $full_path"
        echo "backup: $backup_path"
    else
        echo "backup failed."
    fi
}

function cdd() {
    if [ $# -eq 0 ]; then
        echo "cdd usage:"
        echo "cdd file   : go to parent dir of the file, or the file itself if it is an dir"
        return
    fi
    
    if [ ! -e "$1" ]; then
        echo "* the given path does not exists."
        return
    elif [ -d "$1" ]; then
        cd "$1"
        return
    fi
    
    local param=$1
    local full_path=$(readlink -f $param)
    local parent_dir=$(dirname $param)
    cd $parent_dir
}

