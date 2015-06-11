#!/bin/bash
#v1.0   2012-04-10
#       run this shell before leave, it will do commands in below sequence: 
#       repo sync ; rm -rf /out ; make ; du -sh /out ; poweroff

CODE_D=workspace/code
PROJECT_NAME=
PROJECT_PATH=
CURRENT_PATH=$(pwd)
ERROR_NUM=0
AUTO_COMPILE=autocompile.sh
DEBUG="true"

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

function ShellHelp() {
    local shell_name=`basename $0`
    echo
    echo "NAME:"
    echo "$0: "
    echo
    echo "DESCRIPTION:"
    echo "run this sh before leaving the office, it will do commands in below sequence:"
    echo "repo sync ; rm -rf /out ; make ; du -sh /out ; poweroff"
    echo
    echo "OPTIONS:"
    echo "none"
    echo
    echo "USAGE:"
    echo
}

#suspend system, give user some time to abort "poweroff" operation
function Poweroff() {
    echo
    echo "about to poweroff ......"
    local count=200
    while [ $count -ge 0 ]; do
        echo
        echo "poweroff count down : $count"
        sleep 3s
        let count--
    done
    sudo poweroff
}

#$1 shoud be full path of a project
function ExecuteAutoCompile() {
    if [ ! -f $PROJECT_PATH/$AUTO_COMPILE ]; then
        echo "* cannot find autocompile.sh in $PROJECT_PATH"
        return 1
    fi
    
    cd $1
    ./$AUTO_COMPILE -sd
}

#======================================

#if no param is presented, use current as src file
if [ $# -eq 0 ]; then         #determine project according to current dir
    tmp_str=`echo $CURRENT_PATH | awk -F "/$CODE_D/" '{print $1}'`
    DEBUG echo "DEBUG, CURRENT_PATH : $CURRENT_PATH"
    DEBUG echo "DEBUG, tmp_str: $tmp_str"
    if [ ! "$tmp_str" == "$HOME" ]; then
        echo
        echo "* currently we are not in a dir or subdir of any project."
        ShellHelp
        ERROR_NUM=1
        exit $ERROR_NUM
    fi
    PROJECT_NAME=`echo $CURRENT_PATH | awk -F "/$CODE_D/" '{print $2}' | awk -F "/" '{print $1}'`
    PROJECT_PATH=$CODE_DIR/$PROJECT_NAME
    ExecuteAutoCompile $PROJECT_PATH
    exit $ERROR_NUM
fi

for param in $@; do
    #param should be project name
    #if one or more params are presented, 
    PROJECT_NAME=$param
    PROJECT_PATH=$CODE_DIR/$PROJECT_NAME
    ExecuteAutoCompile $PROJECT_PATH
done

#Poweroff
