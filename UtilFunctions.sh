#!/bin/bash

#       AUTHOR : liuxu
#       THIS SHELL IS ENVIRONMENT INDEPENDENT

#util functions for writting sh

SH_DOC=$(dirname $0)"/sh_document"
SH_DOCUMENT=$(dirname $0)/sh_document/document$(date +%m%d)
TMP=/tmp/namestring_$(date +%m%d%H%M%S)

#====================================
#needed by every sh

DEBUG() {
    if $DEBUG; then
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
cat <<EOF

--------------------------------------------------------------------------------
USAGE:

OPTIONS:

DESCRIPTION:
--------------------------------------------------------------------------------

EOF
}

#====================================
#util functions

#see if $1 is interger or not
#if $2, $3 is presented, see if $1 is inside [$2, $3]
#yield true or false
#if present, $2 and $3 should be interger
function IsInteger() {
    local ret       #return value

    if [[ $1 =~ [0-9]+ ]]; then     #make sure input is interger
        ret="true"
    else
        ret="false"
    fi

    if [ "$ret" == "false" -o $# -eq 1 ]; then
        echo $ret
        return
    fi

    if [[ ( $1 -ge $2 ) && ( $1 -le $3 ) ]]; then      #make sure $n is inside the range
        ret="true"
    else
        ret="false"
    fi

    echo $ret
}

#pick an appropriate adb
function ReadyADB() {
    [ "$UID" = "0" ] && SUDO= || SUDO=sudo
    if [ -f $PROJECT_PATH/out/host/linux-x86/bin/adb ]; then
        ADB="$SUDO $PROJECT_PATH/out/host/linux-x86/bin/adb"
    else
        ADB="$SUDO /usr/local/bin/adb"
    fi
    DEBUG echo "ADB: $ADB"
}

#====================================
#process args and opts

#process options
function ProcessOptions() {
    while getopts ":txdul:" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "t")
                B_TOUCH_ENABLED="true"
                ;;
            "x")
                B_PUSH_TO_PHONE="false"
                ;;
            "u")
                B_UPDATE_API="true"
                ;;
            "d")
                DEBUG="true"
                ;;
            "l")
                optarg=$OPTARG
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                ShellHelp
                exit
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option -$opt needs a value, but it is not presented"
                ShellHelp
                exit
                ;;
            *)
                #unknown error, should not occur
                echo "* unknown error while processing options and params"
                ShellHelp
                exit
                ;;
        esac
    done
    return $OPTIND
}

#process args
function ProcessArgs() {
    DEBUG echo "args: $@"
    if [ $# -eq 0 ]; then
        #no args, just print help
    fi

    for arg in $@; do
        echo $arg
    done
}

ProcessOptions "$@"
arg_start=$?
ProcessArgs "${@:$arg_start}"

#====================================

#read config information from *.config file
function ReadProjectConfig() {
    echo
}

