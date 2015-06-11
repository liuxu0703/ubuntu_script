#!/bin/bash
#v1.0   2013-01-30
#       first version, push given libs to phone. multiple params supported.
#       -p: locate project path according to current dir if out/target/product/$PRODUCT/... is given

#====================================
#global variables

B_PROJECT_RELATIVE="false"
DEBUG="false"
PROJECT_PATH=
ADB=

declare -a MODULE_ARR

#====================================

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
NAME:
adbpush.sh

USAGE:
adbpush.sh [-p] file

OPTIONS:
push the given files into the corresponding dirs in the phone.
-p: if the given path is a relative path (start with "out/target/product") to a project, connect it to a project root path according to current dir.

DESCRIPTION:
push the given modules to the phone

--------------------------------------------------------------------------------

EOF
}

#$1 should be full path of a file
function AddToArray() {
    local length=${#MODULE_ARR[*]}
    MODULE_ARR[$length]="$1"
}

function PushToPhone() {
    if [ ${#MODULE_ARR[@]} -eq 0 ]; then
        echo
        echo "* nothing to push!"
        echo
        exit 1
    fi
    
    [ "$UID" = "0" ] && SUDO= || SUDO=sudo
#    if [ -f $PROJECT_PATH/out/host/linux-x86/bin/adb ]; then
#        ADB="$SUDO $PROJECT_PATH/out/host/linux-x86/bin/adb"
#    else
#        ADB="$SUDO /usr/local/bin/adb"
#    fi
    ADB="$SUDO /usr/local/bin/adb"
    DEBUG echo "ADB: $ADB"
    
    for f in ${MODULE_ARR[*]}; do
        local pj_compiled_lib=$(echo $f | awk -F "$PROJECT_PATH/" '{print $2}')
        local product_name=$(echo $pj_compiled_lib | awk -F "/" '{print $4}')
        local file_basename=$(basename $f)
        local phone_dir=$(echo $f | awk -F "out/target/product/$product_name" '{print $2}' | awk -F "$file_basename" '{print $1}')
        echo
        echo "$f -> $phone_dir"
        [ "$DEBUG" == "true" ] && continue
        $ADB push $f $phone_dir
        echo
    done
}

#locate project root dir
#$1 should be a full path of a file or dir
#without $1 this function will check current path
#yield the path if found, or "/" if not found
function LocateProjectRoot() {
    local path
    local cur_path=$(pwd)
    local tmp_path
    local prj_path
    
    if [ $# -eq 0 ]; then
        path=$(pwd)
    elif [ -f $1 ]; then
        path=$(dirname $1 | xargs readlink -f)
    else
        path=$(readlink -f $1)
    fi

    tmp_path=$path
    cd $tmp_path > /dev/null
    while true; do
        if [ -f build/core/envsetup.mk -a -f Makefile ]; then
            break
        elif [ "$tmp_path" == "/" ]; then
            echo "/"
            return
        fi
        cd ..
        tmp_path=$(pwd)
    done

    cd $cur_path > /dev/null
    prj_path=$tmp_path
    if [ $? -eq 0 ]; then
        echo $prj_path
    else
        echo "/"
    fi
}

#process options
function ProcessOptions() {
    while getopts ":pd" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "p")
                B_PROJECT_RELATIVE="true"
                ;;
            "d")
                DEBUG="true"
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                ShellHelp
                exit 1
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option $OPTARG needs a value, but it is not presented"
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

#process params
function ProcessParams() {
    DEBUG echo "params: $@"
    if [ $# -eq 0 ]; then
        #no params, just print help
        ShellHelp
        exit 1
    fi

    for param in $@; do
        DEBUG echo "param: $param"
        local pj_path
        local full_path
        
        if [ -f $param ]; then
            pj_path=$(echo $param | awk -F "/out/target/product" '{print $1}')
            full_path=$(readlink -f $param)
        elif [ "$B_PROJECT_RELATIVE" == "true" ]; then
            pj_path=$(LocateProjectRoot)
            if [ "$pj_path" == "/" ]; then
                echo
                echo "* given lib is not in any project path: $param"
                echo
                exit 1
            fi
            full_path=$pj_path/$param
        else
            echo
            echo "* given lib is not a validate file path: $param"
            echo
            exit 1
        fi
        
        if [ "$PROJECT_PATH" == "" ]; then
            PROJECT_PATH=$pj_path
        elif [ ! "$PROJECT_PATH" == "$pj_path" ]; then
            echo
            echo "* libs are not in the same project path, will not push."
            echo
            exit 1
        elif [ ! -f $full_path ]; then
            echo
            echo "cannot locate file, pls check args: $full_path"
            echo
            exit 1
        fi
        
        AddToArray $full_path
    done
}
ProcessOptions "$@"
param_start=$?
ProcessParams "${@:$param_start}"
PushToPhone
exit 0
