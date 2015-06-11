#!/bin/bash
#v1.0   2012-02-29, use meld to compare code between existing project
#       if no param is given, generate a menu to compare current dir to all the same dir of other project
#       if 1 param is given, generate a menu to compare current dir (or file) to all other project of the same dir (or file)
#v1.1   2012-04-14, change selection apperance
#v1.2   2012-04-27, add -p option
#       -p: just print respective file in the two project, do not meld them

#these variables are written into .bashrc, thus are environment variables now
#CODE_DIR=$HOME/workspace/code
declare -a PJ_ARR
COMPONENT_NAME=
SOURCE_PJ_NAME=
TARGET_PJ_NAME=
B_MELD=true
DEBUG=false

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp() {
    local shell_name=`basename $0`
    echo
    echo "NAME:"
    echo "$shell_name: "
    echo
    echo "DESCRIPTION:"
    echo "Compare file or dir between different project"
    echo
    echo "OPTIONS:"
    echo "None"
    echo
    echo "USAGE:"
    echo "If no param is given, generate a menu to compare current dir to all the same dir of other project"
    echo "If 1 param is given, generate a menu to compare current dir (or file) to all other project of the same dir (or file)"
    echo
}

#see if $1 is interger or not
#if $2, $3 is presented, see if $1 is inside [$2, $3]
#return true or false
function IsInterger() {
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

#$1 is the source project to be compared
#$1 should be the name of a project (not a path)
function GenerateProjectMenu() {
    local index=1
    declare -a pj_arr=($(find $CODE_DIR -maxdepth 1 -type d | sort -n))    #list of all dir in CODE_DIR

    local i=0; local j=0
    while [ $i -lt ${#pj_arr[*]} ]; do  #delete $1 from pj_arr
        pj_arr[$i]=$(basename ${pj_arr[$i]})
        if [ "${pj_arr[$i]}" != "$1" -a "${pj_arr[$i]}" != "code" ]; then
            PJ_ARR[$j]=${pj_arr[$i]}
            let j++
        fi
        let i++
    done

    i=0
    while [ $i -lt ${#PJ_ARR[*]} ]; do
        index=$(expr $i + 1)
        local is_single_digit=$(IsInterger $index 0 9)
        if [ "$is_single_digit" == "true" ]; then
            echo "  [ $index]. $1  <-[ $index]->  ${PJ_ARR[$i]}"
        else
            echo "  [$index]. $1  <-[$index]->  ${PJ_ARR[$i]}"
        fi
        let i++
    done

    unset pj_arr
}

#====================================
#determine project according to the current dir or param $1

if [ "$1" == "-h" ]; then
    ShellHelp
    exit 0
elif [ "$1" == "-p" ]; then
    B_MELD=false
    shift
fi

code_dir=`echo $CODE_DIR | awk -F "$HOME/" '{print $2}'`
current_path=`pwd`
tmp_str=

if [ $# -eq 0 ]; then         #determine project according to current dir
    tmp_str=`echo $current_path | awk -F "/$code_dir/" '{print $1}'`
    if [ ! "$tmp_str" == "$HOME" ]; then
        echo
        echo "currently we are not in a dir or subdir of any project."
        ShellHelp
        exit 1
    fi
    SOURCE_PJ_NAME=`echo $current_path | awk -F "/$code_dir/" '{print $2}' | awk -F "/" '{print $1}'`
    COMPONENT_NAME=`echo $current_path | awk -F "$CODE_DIR/$SOURCE_PJ_NAME/" '{print $2}'`

elif [ -d $1 ]; then        #determine project according to the given dir
    tmp_str=`readlink -f $1 | awk -F "/$code_dir/" '{print $1}'`
    if [ ! "$tmp_str" == "$HOME" ]; then
        echo
        echo "target dir is not in any project!"
        ShellHelp
        exit 1
    fi
    SOURCE_PJ_NAME=`readlink -f $1 | awk -F "/$code_dir/" '{print $2}' | awk -F "/" '{print $1}'`
    COMPONENT_NAME=`readlink -f $1 | awk -F "$CODE_DIR/$SOURCE_PJ_NAME/" '{print $2}'`

elif [ -f $1 ]; then        #determine project according to the given file
    tmp_dir=$(dirname $1)
    tmp_str=`readlink -f $tmp_dir | awk -F "/$code_dir/" '{print $1}'`
    if [ ! "$tmp_str" == "$HOME" ]; then
        echo
        echo "target dir is not in any project!"
        ShellHelp
        exit 1
    fi
    SOURCE_PJ_NAME=`readlink -f $1 | awk -F "/$code_dir/" '{print $2}' | awk -F "/" '{print $1}'`
    COMPONENT_NAME=`readlink -f $1 | awk -F "$CODE_DIR/$SOURCE_PJ_NAME/" '{print $2}'`

else
    ShellHelp
    exit 1
fi

if [ "$DEBUG" == "true" ]; then
    echo
    echo "code_dir: $code_dir"
    echo "current_path: $current_path"
    echo "tmp_str: $tmp_str"
    echo
    echo "CODE_DIR: $CODE_DIR"
    echo "SOURCE_PJ_NAME: $SOURCE_PJ_NAME"
    echo "COMPONENT_NAME: $COMPONENT_NAME"
    echo
fi

#====================================
#menu

echo "==================================="
echo
echo "Component: "
echo $COMPONENT_NAME
GenerateProjectMenu $SOURCE_PJ_NAME
echo "  [X]. Do Nothing and Exit"
read -p "choose two projects to compare: "

if [[ ( "$REPLY" == "x" ) || ( "$REPLY" == "X" ) ]]; then
    #echo "do nothing and exit."
    echo
    exit 0
elif [ $(IsInterger $REPLY 1 ${#PJ_ARR[*]}) == "true" ]; then
    n=$(expr $REPLY - 1)
else
    echo "Invalidate Selection !!!"
    echo
    exit
fi

TARGET_PJ_NAME=${PJ_ARR[$n]}

if [ "$DEBUG" == "true" ]; then
    echo
    echo "PJ_ARR[ ]: ${PJ_ARR[*]}"
    echo "PJ_ARR[$n]: ${PJ_ARR[$n]}"
    echo "SOURCE_PJ_NAME: $SOURCE_PJ_NAME"
    echo "TARGET_PJ_NAME: $TARGET_PJ_NAME"
    echo "COMPONENT_NAME: $COMPONENT_NAME"
    echo
fi

#====================================
#error shooting

if [ ! -e $CODE_DIR/$SOURCE_PJ_NAME/$COMPONENT_NAME ]; then
    echo
    echo "Component does not exit in source project"
    echo
    exit 2
fi

if [ ! -e $CODE_DIR/$TARGET_PJ_NAME/$COMPONENT_NAME ]; then
    echo
    echo "The same component does not exist in target project"
    echo
    exit 2
fi

#====================================

echo
echo $CODE_DIR/$SOURCE_PJ_NAME/$COMPONENT_NAME
echo $CODE_DIR/$TARGET_PJ_NAME/$COMPONENT_NAME
echo

if [ "$B_MELD" == "false" ]; then
    exit 0
fi

meld $CODE_DIR/$SOURCE_PJ_NAME/$COMPONENT_NAME $CODE_DIR/$TARGET_PJ_NAME/$COMPONENT_NAME & > /dev/null

