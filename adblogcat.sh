#!/bin/bash

#       AUTHOR : liuxu-0703@163.com

#v1.0   use "adb logcat" command to show log instantaneously
#       params are keywords to be picked
#       option -r indicates keywords for lines to be excluded
#       option -o indicates the output info is stored in ~/issue_logs/
#v1.1   default behavior: (without option) set to exclude keyword
#       option -n indicates keywords for lines to be included
#v1.2   remove the -o option, user can easily redirect output, so there is no use to add this feature
#       with -n option, there are several keyword sets to be selected
#v2.0   do not use sed to filter log, instead, we use original 'adb logcat' functions to filter log
#       the current adblogcat has two options:
#       -i: for include
#       -e: for exclude
#v2.1   2013-01-24
#       add -p option
#       -p: print log from specified pid


#01-09 14:49:22.806  1139  1510 I ActivityManager: Start proc com.jovision.ivbaby for activity com.jovision.ivbaby/.ui.MainActivity: pid=21859 uid=10117 gids={500117, 3003, 1028, 1015}


DEBUG="false"
B_INCLUDE="true"
B_PID="false"
PID=
FILTER=                                         #filter string

declare -a A_KEYWORDSETS                        #array of keyword set names
declare -a A_KEYWORDS                           #array of keywords in the selected keyword set

SCRIPT_PATH="$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)"
KEYWORD_MANAGER_PY=$SCRIPT_PATH/keyword_manager.py
KEYWORDSET_XML=$SCRIPT_PATH/keywordset.xml
KEYWORD_MANAGER="python $KEYWORD_MANAGER_PY"    #keyword_manager.py

#[ "$UID" = "0" ] && SUDO= || SUDO=sudo
#ADB="$SUDO /usr/local/bin/adb"
ADB="adb"                        #TODO: specify your adb here

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
NAME:
adblogcat.sh

USAGE:
adblogcat.sh [-i keywords... | -e keywords... | -p pid] [keywords]

OPTIONS:
-i: include keywords (default)
-e: exclude keywords
-p: print logs from specified pid

DESCRIPTION:
generate filter for 'adb logcat' command, the filter is generated according to OPTION and KEYWORDS.
without KEYWORDS $shell_name will bring up a keyword set menu for the user to choose.
--------------------------------------------------------------------------------

EOF
}

#see if $1 is interger or not
#if $2, $3 is presented, see if $1 is inside [$2, $3]
#yield true or false
#if present, $2 and $3 should be interger
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

function KeywordSetMenu() {
    i=0
    while [ $i -lt ${#A_KEYWORDSETS[*]} ]; do
        index=$(expr $i + 1)
        echo "  [$index]. ${A_KEYWORDSETS[$i]}"
        let i++
    done
}

function SelectKeywordset() {
    local title
    local tmp_arr
    local length
    local keyword_set_name
    
    if [ "$B_INCLUDE" == "true" ]; then
        tmp_arr=$($KEYWORD_MANAGER -t include)
        title="Keyword Set Menu (type - include) :"
    else
        tmp_arr=$($KEYWORD_MANAGER -t exclude)
        title="Keyword Set Menu (type - exclude) :"
    fi
    
    for s in $tmp_arr; do
        length=${#A_KEYWORDSETS[*]}
        A_KEYWORDSETS[$length]=$s
    done
    
    DEBUG echo "A_KEYWORDSETS : ${A_KEYWORDSETS[*]}"
    
    echo
    echo $title
    KeywordSetMenu
    echo "  [S]. Show Keywordset Detail"
    echo "  [E]. Edit keywordset.xml"
    echo "  [X]. Do Nothing and Exit"
    read -p "choose a keywordset: "

    if [[ ( "$REPLY" == "x" ) || ( "$REPLY" == "X" ) ]]; then
        echo
        exit
    elif [[ ( "$REPLY" == "s" ) || ( "$REPLY" == "S" ) ]]; then
        echo
        echo "*****************************************************"
        echo "*. Keyword Set Detail :"
        echo 
        $KEYWORD_MANAGER -d
        echo "*****************************************************"
        SelectKeywordset
    elif [[ ( "$REPLY" == "e" ) || ( "$REPLY" == "E" ) ]]; then
        gedit $KEYWORDSET_XML
        echo
        exit
    elif [ $(IsInterger $REPLY 1 ${#A_KEYWORDSETS[*]}) == "true" ]; then
        n=$(expr $REPLY - 1)
    else
        echo
        echo "Invalidate Selection !!!"
        echo
        exit
    fi
    
    keyword_set_name=${A_KEYWORDSETS[$n]}
    DEBUG echo "keyword_set_name : $keyword_set_name"
    
    tmp_arr=$($KEYWORD_MANAGER -n $keyword_set_name)
    for s in $tmp_arr; do
        length=${#A_KEYWORDS[*]}
        A_KEYWORDS[$length]=$s
    done
    DEBUG echo "A_KEYWORDS : ${A_KEYWORDS[*]}"
}

#param should be $@
function ProcessParam() {
    if [ "$1" == "-i" ]; then   #include keywords
        B_INCLUDE="true"
        shift
    elif [ "$1" == "-e" ]; then     #exclude keywords
        B_INCLUDE="false"
        shift
    elif [ "$1" == "-p" ]; then     #pid
        B_PID="true"
        shift
    elif [ "$1" == "-h" ]; then
        ShellHelp
        exit
    fi
    
    if [ "$B_PID" == "true" ]; then
        if [ $(IsInterger $1) == "false" ]; then
            echo "Please specify a digit pid !!!"
            ShellHelp
            exit
        else
            PID=$1
            return
        fi
    fi
    
    if [ $# -eq 0 ]; then
        SelectKeywordset
        return
    fi

    for s in $*; do
        length=${#A_KEYWORDS[*]}
        A_KEYWORDS[$length]=$s
    done
    DEBUG echo "A_KEYWORDS : ${A_KEYWORDS[*]}"
}

function GenerateFilter() {
    local ignore
    if [ "$B_INCLUDE" == "true" ]; then
        for k in ${A_KEYWORDS[*]}; do
            ignore=$(echo $k | grep ^#)                     #ignore keyword start with "#"
            [ -z $ignore ] && FILTER="${FILTER} ${k}:V"
        done
        FILTER="${FILTER} *:S"
    else
        for k in ${A_KEYWORDS[*]}; do
            ignore=$(echo $k | grep ^#)                     #ignore keyword start with "#"
            [ -z $ignore ] && FILTER="${FILTER} ${k}:S"
        done
    fi
}

function PrintFilterInfo() {
    if [ "$B_PID" == "true" ]; then
        local current_time="`date +%x`  `date +%T`"
        echo
        echo "*************************************************"
        echo
        echo "time:                 $current_time"
        echo "filter type:          PID: $PID"
        echo
        echo "*************************************************" 
        echo
        return
    fi

    local current_time="`date +%x`  `date +%T`"
    echo
    echo "*************************************************"
    echo
    echo "time:                 $current_time"
    if [ "$B_INCLUDE" == "false" ]; then
        echo "filter type:          excluded, select lines without keywords"
    else
        echo "filter type:          included, select lines with keywords"
    fi
    echo
    echo "keywords:             ${A_KEYWORDS[0]}"

    for k in ${A_KEYWORDS[*]}; do
        [ "$k" == "${A_KEYWORDS[0]}" ] && continue
        echo "                      $k"
    done

    echo
    echo "*************************************************" 
    echo
}

#=============================
#main()

ProcessParam $*
[ "$B_PID" == "false" ] && GenerateFilter
PrintFilterInfo
if [ "$B_PID" == "false" ]; then
    echo "$ADB logcat -v threadtime $FILTER"
    echo
    $ADB logcat -v threadtime $FILTER
else
    echo "$ADB logcat -v threadtime | grep $PID"
    echo
    $ADB logcat -v threadtime | grep $PID
fi

