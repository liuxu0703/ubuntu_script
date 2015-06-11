#!/bin/bash

#       AUTHOR : liuxu-0703@163.com

#v1.0   2013-03-05
#       first version
#v1.1   2013-03-12
#       add -p option:
#       select lines with specified PID
#v1.2   2013-09-08
#       save result in the same dir as the logs
#v1.3   2013-09-09
#       add exit code

DEFAULT_XML_EDITOR=gedit            #default editor to view keywords.xml file. you may want to change it to vim etc..

DEBUG=false
B_INCLUDE=true
B_EDITOR=false
EDITOR=
FIND_PATH=$(pwd)
FIND_TAG=logcat*
TMP_LOG=                            #tmp log, this is to let the filtered log go through "uniq" command
FILTER_LOG=                         #full path of filtered log file
COMMAND=                            #sed command line
SED_MARK=p                          #default select lines with keywords, default: sed -n "/keywords/p", -r: sed "/keywords/d"
SED_OPTION=-n                       #default select lines with keywords, default: sed -n "/keywords/p", -r: sed "/keywords/d"
PID=

declare -a A_FILES                  #array of original files
declare -a A_KEYWORDSETS            #array of keyword set names
declare -a A_KEYWORDS               #array of keywords in the selected keyword set

SCRIPT_PATH="$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)"
KEYWORD_MANAGER_PY=$SCRIPT_PATH/keyword_manager.py
KEYWORDSET_XML=$SCRIPT_PATH/keywordset.xml
KEYWORD_MANAGER="python $KEYWORD_MANAGER_PY"    #keyword_manager.py

if $DEBUG; then
    echo "KEYWORD_MANAGER_PY: $KEYWORD_MANAGER_PY"
    echo "KEYWORDSET_XML: $KEYWORDSET_XML"
    echo "KEYWORD_MANAGER: $KEYWORD_MANAGER"
fi

#====================================

DEBUG() {
    if $DEBUG; then
        $@
    fi
}

CLEAR_WORK() {
    if [ -e $TMP_LOG ]; then
        rm -rf $TMP_LOG
    fi
}
trap "CLEAR_WORK" EXIT

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------

USAGE:
aplog_helper.sh [-f LogFileName] [-P LogFilePath] [-E EditorProgram] [-i|-e keywords...]
aplog_helper.sh [-f LogFileName] [-P LogFilePath] [-E EditorProgram] [-p pid]

OPTIONS:
-h: print help.
-f: file name to filter.
    use wildcard to select a set of files: "aplog*" ("" is required if you want to use wildcard).
    a filename is also accepted here. if so, only a single file will be filtered.
    default set to "logcat*".
-P: specify a path.
    default set to current path.
-E: specify an editor to view the filtered log, like "-E vim" or "-E gedit", etc.
    default will not use any editor to open the log.
-i: select lines include keywords.
    default set to include keywords.
-e: select lines exclude keywords.
    default set to include keywords.
-p: select lines with the specified PID.

DESCRIPTION:
filter multiple logs with specified keywords. the generated log-after-filter will be put into one file.
if the keywords are not given, then sets of keywords (stored in keywordset.xml) will be shown for user to select.

--------------------------------------------------------------------------------

EOF
}

#====================================

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

#use buble sort method to sort A_FILES
function BubleSort() {
    local len=${#A_FILES[@]}
    local suffix1
    local suffix2
    local tmp
    
    for ((j=0; j<$len-1; j++)); do
        for ((i=0; i<$len-$j-1; i++)); do
            suffix1=$(readlink -f ${A_FILES[$i]} | xargs basename | awk -F "." '{print $2}')
            [ "$suffix1" == "" ] && suffix1="0"
            suffix2=$(readlink -f ${A_FILES[$i+1]} | xargs basename | awk -F "." '{print $2}')
            [ "$suffix2" == "" ] && suffix2="0"
            
            if [ "$suffix2" -gt "$suffix1" ]; then
                tmp=${A_FILES[$i]}
                A_FILES[$i]=${A_FILES[$i+1]}
                A_FILES[$i+1]=$tmp
            fi
        done
    done
    
    if [ "$DEBUG" == "true" ]; then
        echo
        echo
        for fff in ${A_FILES[@]}; do
            echo $(readlink -f $fff | xargs basename)
        done
        echo
        echo
    fi
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
    
    if $B_INCLUDE; then
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
    echo "  [E]. Edit Keywordset.xml"
    echo "  [H]. Print Help"
    echo "  [X]. Do Nothing and Exit"
    read -p "choose a keywordset: "

    if [[ ( "$REPLY" == "x" ) || ( "$REPLY" == "X" ) ]]; then
        echo
        exit 0
    elif [[ ( "$REPLY" == "h" ) || ( "$REPLY" == "H" ) ]]; then
        ShellHelp
        exit 0
    elif [[ ( "$REPLY" == "s" ) || ( "$REPLY" == "S" ) ]]; then
        echo
        echo "*****************************************************"
        echo "*. Keyword Set Detail :"
        echo
        $KEYWORD_MANAGER -d
        echo "*****************************************************"
        unset A_KEYWORDSETS
        declare -a A_KEYWORDSETS
        SelectKeywordset
    elif [[ ( "$REPLY" == "e" ) || ( "$REPLY" == "E" ) ]]; then
        eval $DEFAULT_XML_EDITOR $KEYWORDSET_XML
        echo
        exit 0
    elif [ $(IsInterger $REPLY 1 ${#A_KEYWORDSETS[*]}) == "true" ]; then
        n=$(expr $REPLY - 1)
    else
        echo
        echo "Invalidate Selection !!!"
        echo
        exit 1
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

function PrintHeader() {
    local current_time="`date +%x`  `date +%T`"
    echo
    echo "*************************************************"    | tee -a  $FILTER_LOG
    echo                                                        | tee -a  $FILTER_LOG
    echo "time:                 $current_time"                  | tee -a  $FILTER_LOG
    echo "source:               $FIND_TAG"                      | tee -a  $FILTER_LOG
    echo "source:               $FIND_PATH"                     | tee -a  $FILTER_LOG
    if [ ! "$PID" == "" ]; then
        echo "filter type:          pid, select lines of specified pid"         | tee -a  $FILTER_LOG
    elif ! $B_INCLUDE; then
        echo "filter type:          excluded, select lines without keywords"    | tee -a  $FILTER_LOG
    else
        echo "filter type:          included, select lines with keywords"       | tee -a  $FILTER_LOG
    fi
    
    echo                                                        | tee -a  $FILTER_LOG
    if [ ! "$PID" == "" ]; then
        echo "pid:                  $PID"                       | tee -a  $FILTER_LOG
    else
        echo "keywords:             ${A_KEYWORDS[0]}"           | tee -a  $FILTER_LOG
        for k in ${A_KEYWORDS[*]}; do
            [ "$k" == "${A_KEYWORDS[0]}" ] && continue
            echo "                      $k"                     | tee -a  $FILTER_LOG
        done
    fi

    echo                                                        | tee -a  $FILTER_LOG
    echo "*************************************************"    | tee -a  $FILTER_LOG
    echo                                                        | tee -a  $FILTER_LOG
}

function GenerateCommand() {
    local ignore
    COMMAND="/${A_KEYWORDS[0]}/$SED_MARK; "
    if $B_INCLUDE; then
        for k in ${A_KEYWORDS[*]}; do
            ignore=$(echo $k | grep ^#)                     #ignore keyword start with "#"
            [ -z $ignore ] && COMMAND=$COMMAND"/$k/$SED_MARK; "
        done
        FILTER="${FILTER} *:S"
    else
        for k in ${A_KEYWORDS[*]}; do
            ignore=$(echo $k | grep ^#)                     #ignore keyword start with "#"
            [ -z $ignore ] && COMMAND=$COMMAND"/$k/$SED_MARK; "
        done
    fi
}

function InitEnv() {
    TMP_LOG=/tmp/tmp_text_filter_$(date +%m%d%H%M%S)
    FILTER_LOG=$FIND_PATH/"filterlog."$(date +%m%d%H%M%S)
}

#====================================
#process args and opts

#process options
function ProcessOptions() {
    while getopts ":f:E:p:P:ieh" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "i")
                B_INCLUDE=true
                ;;
            "e")
                B_INCLUDE=false
                SED_MARK=d
                SED_OPTION=
                ;;
            "p")
                PID=$OPTARG
                ;;
            "h")
                ShellHelp
                exit 0
                ;;
            "f")
                FIND_TAG=$OPTARG
                ;;
            "P")
                FIND_PATH=$OPTARG
                if [ ! -d $FIND_PATH ]; then
                    echo "* $FIND_PATH is not a path."
                    ShellHelp
                    exit 1
                fi
                ;;
            "E")
                EDITOR=$OPTARG
                local available=$(which $EDITOR)
                if [ "$available" == "" ]; then
                    echo "* The specified editor is not available."
                else
                    B_EDITOR=true
                fi
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                ShellHelp
                exit 1
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option $opt needs a value, which is not presented"
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
    
    if [ -f "$FIND_TAG" ]; then
        FIND_TAG=$(readlink -f $FIND_TAG)
        FIND_PATH=$(dirname $FIND_TAG)
        A_FILES[0]=$FIND_TAG
    else
        local find_files=$(find $FIND_PATH -maxdepth 1 -type f -name "$FIND_TAG")
        local len
        for ff in $find_files; do
            len=${#A_FILES[*]}
            A_FILES[$len]=$ff
        done
    fi

    DEBUG echo "A_FILES: ${A_FILES[*]} | length: ${#A_FILES[*]}"
    
    if [ ${#A_FILES[*]} -eq 0 -o "${A_FILES[0]}" == "" ]; then
        echo
        echo "* No file matches the given condition."
        ShellHelp
        exit 1
    fi
    
    return $OPTIND
}

#process params
function ProcessParams() {
    DEBUG echo "params: $@"
    
    if [ ! "$PID" == "" ]; then
        # PID is specified, no need to get keywords, just return
        return
    fi
    
    if [ $# -eq 0 ]; then
        SelectKeywordset
        return
    fi

    for param in $@; do
        length=${#A_KEYWORDS[*]}
        A_KEYWORDS[$length]=$param
    done
    DEBUG echo "A_KEYWORDS : ${A_KEYWORDS[*]}"
}

#====================================

ProcessOptions "$@"
param_start=$?
ProcessParams "${@:$param_start}"

GenerateCommand
DEBUG echo "FILTER: $FILTER"

InitEnv
PrintHeader

BubleSort   #only use 'sort' command may not yield the right order, so buble sort
for file in ${A_FILES[*]}; do
    if [ -d $file ]; then
        continue
    fi
    file_name=$(basename $file)
    echo                                                                         >> $TMP_LOG
    echo "============================ $file_name ============================"  >> $TMP_LOG
    echo                                                                         >> $TMP_LOG
    if [ ! "$PID" == "" ]; then
        awk -v pid=$PID '{if ($3==pid) print $0}' $file >> $TMP_LOG
    else
        sed $SED_OPTION "$COMMAND" $file >> $TMP_LOG
    fi
done
cat $TMP_LOG | uniq >> $FILTER_LOG

if [ -f $FILTER_LOG ]; then
    echo "* Filtered text has been created:"
    echo $FILTER_LOG
    if $B_EDITOR; then
        $EDITOR $FILTER_LOG
    fi
else
    echo "Fail to create FILTER_LOG"
fi
echo

