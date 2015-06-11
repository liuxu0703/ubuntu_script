#!/bin/bash

#       AUTHOR : liuxu-0703@163.com

#v1.0   2014-03-18
#       sign an apk with specified key

KEYSET=rdv2
KEYTYPE=platform
APK=

function ShellHelp() {
echo "--------------------------------------------------------------------------------"
echo "USAGE: autosign.sh [-t keytype]"
echo "autosign.sh *.apk"
echo "sign an apk with keyset=$KEYSET , keytype=$KEYTYPE (default)."
echo "use -t to specify keytype"
echo "--------------------------------------------------------------------------------"
}

# sign an apk use signit
# $1 should ba path of a apk file
function SignitApk() {
    local full=$(readlink -f $1)
    if [ ! -f "$full" ]; then
        echo "* sign apk, not a file: $full"
        ShellHelp
        return 0
    fi
    local suffix=${full##*.}
    if [ ! "$suffix" == "apk" ]; then
        echo "* sign apk, not an apk file: $full"
        ShellHelp
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


#process options
function ProcessOptions() {
    while getopts ":t:" opt; do
        case "$opt" in
            "t")
                KEYTYPE=$OPTARG
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
    APK=$1
}

ProcessOptions "$@"
arg_start=$?
ProcessArgs "${@:$arg_start}"

if [ "$APK" == "" ]; then
    ShellHelp
else
    echo "* sign $APK with keyset=$KEYSET keytype=$KEYTYPE"
    SignitApk $APK
fi
