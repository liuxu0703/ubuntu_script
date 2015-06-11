#!/bin/bash

#       AUTHOR : liuxu-0703@163.com

#v1.0   2013-09-01
#       dowload file use fex. push it to phone if needed.
#v1.1   2013-09-26
#       use an array to store package-location pairs

#v2.0   2013-11-18
#       big modification

#v2.1   2014-03-14
#       add -s option: sign apk with signit before push

RUN_INTERVAL=5  
RUN_TIME_ELIPSE=0
RUN_TIME_OUT=3600   # 3600s = 1 hour

# NOTE: files in /tmp dir will be deleted by system when poweroff, you may want to change it if you want to reserve download files.
DOWNLOAD_PATH=/tmp/fexpush_tmp
DECOMPRESS_PATH=$DOWNLOAD_PATH/decompress_dir
CAF_DIR=
CAF_SCRIPT=caf_script.sh
CAF_PREFIX=caf_objects

LATEST_FEX=
LATEST_DOWNLOAD=
SPECIFIED_CAF=

B_UPDATED=false
B_RUN=false
B_SIGN=false
DEBUG=false

KEYSET=rdv2
KEYTYPE=platform
#KEYTYPE=testkey

ADB="/usr/local/bin/adb"

#====================================

DEBUG() {
    if $DEBUG; then
        $@
    fi
}

CLEAR_WORK() {
    if [ -e $DECOMPRESS_PATH ]; then
        rm -r $DECOMPRESS_PATH
    fi
}
trap "CLEAR_WORK" EXIT

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:
fex_push.sh [-w] [-h]
fex_push.sh -d tarFileName

OPTIONS:
-h: print help
-w: keep waiting for update from fex server. if a caf update appares, download and push it.
    if no update comes in 1 hour, stop waiting and exit.
    product deference will be ignored in this case.
-d: decompress specified file and push, if it is a caf file.
-s: sign all apk before push to phone. using signit, with keyset rdv2, keytype platform

DESCRIPTION:
dowload caf file use fex. push it to phone if suitable.
without args, this script will check if the newest file in fex server is caf file.
if so, try push it to phone.
--------------------------------------------------------------------------------

EOF
}

#====================================

#
function IsCafFile() {
    local time_stamp=$(echo $1 | awk -F "." '{print $2}')
    if [ "$1" == "$CAF_PREFIX.$time_stamp.tar.gz" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# see if fex server is updated and the latest file is a caf file
function Update() {
    local idx_info=$(fex -l | head -1)
    DEBUG echo "update - fex newest : $idx_info"
    DEBUG echo "update - fex latest : $LATEST_FEX"
    
    if [ "$LATEST_FEX" == "" ]; then
        B_UPDATED=false
    elif [ "$LATEST_FEX" == "$idx_info" ]; then
        B_UPDATED=false
    else
        local download_name=$(echo $idx_info | awk '{print $3}')
        if [ "$(IsCafFile $download_name)" == "true" ]; then
            B_UPDATED=true
        else
            B_UPDATED=false
        fi
    fi
    
    LATEST_FEX=$idx_info
}

# check the latest file in fex server, if it is a caf file, download it.
function DownloadLatest() {
    local download_name=$(fex -l | head -1 | awk '{print $3}')
    if [ "$(IsCafFile $download_name)" == "true" ]; then
        LATEST_DOWNLOAD=$DOWNLOAD_PATH/$download_name
        fex -d $DOWNLOAD_PATH
        return 0
    else
        echo "* latest file in fex server is not caf file : $download_name"
        return 1
    fi
}

# use "tar" command to decompress CAF_UPLOAD.tar.gz file
# yield decompressed file path
# $1 should be path of the CAF_UPLOAD.tar.gz file
function Decompress() {
    if [ ! -e $1 ]; then
        return 1
    fi
    
    local tar_path=$(readlink -f $1)
    local de_name=$(tar -ztf $tar_path | head -1)
    
    if [ -e $DECOMPRESS_PATH ]; then
        rm -r $DECOMPRESS_PATH
    fi
    mkdir $DECOMPRESS_PATH
    cd $DECOMPRESS_PATH
    
    
    tar -zxf $tar_path > /dev/null
    if [ ! -d $DECOMPRESS_PATH/$de_name -o ! -e $DECOMPRESS_PATH/$de_name/$CAF_SCRIPT ]; then
        return 1
    fi
    
    echo $DECOMPRESS_PATH/$de_name
    return 0
}

#====================================

# sign an apk use signit
# $1 should ba path of a apk file
function SignitApk() {
    local full=$(readlink -f $1)
    if [ ! -f "$full" ]; then
        echo "* sign apk, not a file: $full"
        return 0
    fi
    local suffix=${full##*.}
    if [ ! "$suffix" == "apk" ]; then
        echo "* sign apk, not an apk file: $full"
        return 0
    fi
    
    signit -r $KEYSET -t $KEYTYPE -f "$full"
    if [ $? -ne 0 ]; then
        echo "* some error happened when sign apk with signit"
        return 1
    fi
    
    local ffff=$(basename "$full")
    local name=${ffff%.*}
    local path=$(dirname "$full")
    rm "$full" && mv $path/"$name[$KEYSET+$KEYTYPE].apk" $full
    if [ $? -ne 0 ]; then
        echo "replace $full with $path/$name[$KEYSET+$KEYTYPE].apk fail"
        return 2
    else
        echo "replace $full with $path/$name[$KEYSET+$KEYTYPE].apk"
        return 0
    fi
}

# use signit to sign all apk in a dir
# $1 should be path of a dir
function SignitAllApks() {
    local dddd=$(readlink -f $1)
    if [ ! -d "$dddd" ]; then
        echo "* sign all apk in dir fail, not a dir: $1"
        return 1
    fi
    
    cd "$dddd"
    local ret=true
    local files=$(ls "$dddd")
    for ffff in $files; do
        SignitApk $ffff
        if [ $? -ne 0 ]; then
            ret=false
            break
        fi
    done
    
    if $ret; then
        return 0
    else
        return 1
    fi
}

#====================================
#process args and opts

#process options

function ProcessOptions() {
    while getopts ":hwsd:" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "h")
                ShellHelp
                exit 0
                ;;
            "w")
                B_RUN=true
                ;;
            "s")
                B_SIGN=true
                ;;
            "d")
                SPECIFIED_CAF=$OPTARG
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                ShellHelp
                exit 1
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option -$opt needs a value, but it is not presented"
                ShellHelp
                exit 1
                ;;
            *)
                #unknown error, should not occur
                echo "* unknown error while processing options and params"
                ShellHelp
                exit 1
                ;;
        esac
    done
    return $OPTIND
}

#====================================
#main

ProcessOptions "$@"

if [ ! -e $DOWNLOAD_PATH ]; then
    mkdir $DOWNLOAD_PATH
fi
if [ -e $DECOMPRESS_PATH ]; then
    rm -r $DECOMPRESS_PATH
fi
mkdir $DECOMPRESS_PATH

$ADB shell mount -o rw,remount /system

if $B_RUN; then
    # let user login
    fex -l > /dev/null
    
    # wait for update
    echo "* begin waiting for fex update ..."
    while [ $RUN_TIME_ELIPSE -le $RUN_TIME_OUT ]; do
        Update
        DEBUG echo "B_UPDATED : $B_UPDATED"
        if $B_UPDATED; then
            DownloadLatest
            # ignore product deference when we are in waiting mode
            CAF_DIR=$(Decompress $LATEST_DOWNLOAD)
            if $B_SIGN; then
                SignitAllApks $CAF_DIR
            fi
            source $CAF_DIR/$CAF_SCRIPT -i
            RUN_TIME_ELIPSE=0
            continue
        fi
        
        ((RUN_TIME_ELIPSE=RUN_TIME_ELIPSE+RUN_INTERVAL))
        # print some info at intervals to show that we are still working
        if [ $(($RUN_TIME_ELIPSE%60)) -lt $RUN_INTERVAL ]; then
            echo "$RUN_TIME_ELIPSE seconds without update"
        fi
        
        sleep "${RUN_INTERVAL}s"
    done
    # no update in a long time, stop waiting for update
    echo "* no update in $RUN_TIME_OUT seconds, stop waiting for update."
    
elif [ ! "$SPECIFIED_CAF" == "" ]; then
    # decompress specified caf file and push
    if [ "$(IsCafFile $(basename $SPECIFIED_CAF))" == "true" ]; then
        CAF_DIR=$(Decompress $SPECIFIED_CAF)
        if $B_SIGN; then
            SignitAllApks $CAF_DIR
        fi
        source $CAF_DIR/$CAF_SCRIPT
    else
        echo "* given file is not a caf file"
        exit 1
    fi
    
else
    # try download the newest from fex server
    DownloadLatest
    if [ $? -ne 0 ]; then
        exit 1
    fi
    CAF_DIR=$(Decompress $LATEST_DOWNLOAD)
    if $B_SIGN; then
        SignitAllApks $CAF_DIR
    fi
    source $CAF_DIR/$CAF_SCRIPT
fi
    
