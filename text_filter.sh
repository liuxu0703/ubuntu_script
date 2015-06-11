#!/bin/bash

#       AUTHOR : liuxu
#       THIS SHELL IS ENVIRONMENT INDEPENDENT

#v1.0   filter text files according to specified keyword (params)
#v2.0   add -e option before keyword to exclude lines with keywords, change behavior when sh has no param (apart from options)
#v2.1   change behavior when there is no keyword specified
#v2.2   put filtered log in /tmp
#v3.0   use keyword_manager.py to select keywords
#v3.1   2012-10-31
#       add -g option: open the filtered text with gedit


DEBUG="false"
B_INCLUDE="true"
SH_DOC=$(dirname $0)"/sh_document"
SH_DOCUMENT=$SH_DOC"/document"$(date +%m%d)
FILE_PATH=                          #path of text file
TMP_LOG=                            #tmp log, this is to let the filtered log go through "uniq" command
FILTER_LOG=                         #full path of filtered log file
COMMAND=                            #sed command line
SED_MARK=p                          #default select lines with keywords, default: sed -n "/keywords/p", -r: sed "/keywords/d"
SED_OPTION=-n                       #default select lines with keywords, default: sed -n "/keywords/p", -r: sed "/keywords/d"
B_GEDIT="false"

declare -a A_KEYWORDSETS                        #array of keyword set names
declare -a A_KEYWORDS                           #array of keywords in the selected keyword set

KEYWORD_MANAGER_PY=/home/liuxu/my_shellscript/keyword_manager.py
KEYWORDSET_INI=/home/liuxu/my_shellscript/keywordset.ini
KEYWORD_MANAGER="python $KEYWORD_MANAGER_PY"    #keyword_manager.py

#====================================

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

CLEAR_WORK() {
    if [ -e $TMP_LOG ]; then
        sudo rm -rf $TMP_LOG
    fi
}
trap "CLEAR_WORK" EXIT

function ShellHelp() {
    local shell_name=`basename $0`
    echo
    echo "NAME:"
    echo "$shell_name: "
    echo
    echo "USAGE:"
    echo "$shell_name [option] filename [keyword1 keyword2 ...]"
    echo
    echo "OPTIONS:"
    echo "-i    : $shell_name will select lines with keywords"
    echo "-e    : $shell_name will select lines without keywords"
    echo "-g    : open the filtered text with gedit"
    echo "-h    : print help of $shell_name"
    echo
    echo "DESCRIPTION:"
    echo "filter text with keywords"
    echo "without option $shell_name will select lines which include keywords"
    echo "without keywords $shell_name will let the user select an exits keyword set"
    echo

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
    echo "  [E]. Edit Keywordset.ini"
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
        gedit $KEYWORDSET_INI
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

function PrintCommandInfo() {
    local current_time="`date +%x`  `date +%T`"
    echo                                                        | tee -a  $FILTER_LOG
    echo "*************************************************"    | tee -a  $FILTER_LOG
    echo                                                        | tee -a  $FILTER_LOG
    echo "time:                 $current_time"                  | tee -a  $FILTER_LOG
    echo "target text:          $FILE_PATH"                     | tee -a  $FILTER_LOG
    if [ "$B_INCLUDE" == "false" ]; then
        echo "filter type:          excluded, select lines without keywords"    | tee -a  $FILTER_LOG
    else
        echo "filter type:          included, select lines with keywords"       | tee -a  $FILTER_LOG
    fi
    echo                                                        | tee -a  $FILTER_LOG
    echo "keywords:             ${A_KEYWORDS[0]}"               | tee -a  $FILTER_LOG

    for k in ${A_KEYWORDS[*]}; do
        [ "$k" == "${A_KEYWORDS[0]}" ] && continue
        echo "                      $k"                         | tee -a  $FILTER_LOG
    done

    echo                                                        | tee -a  $FILTER_LOG
    echo "*************************************************"    | tee -a  $FILTER_LOG
    echo                                                        | tee -a  $FILTER_LOG
}

#param should be $@
function ProcessParam() {
    if [ "$1" == "-i" ]; then   #include keywords
        B_INCLUDE="true"
        shift
    elif [ "$1" == "-e" ]; then     #exclude keywords
        B_INCLUDE="false"
        SED_MARK=d
        SED_OPTION=        
        shift
    elif [ "$1" == "-h" ]; then
        ShellHelp
        exit
    elif [ "$1" == "-g" ]; then
        B_GEDIT="true"
        shift
    fi
    
    if [ -f $1 ]; then
        FILE_PATH=$1
        shift
    else
        echo "require a text file path for param !"
        ShellHelp
        exit
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

function GenerateCommand() {
    local ignore
    COMMAND="/${A_KEYWORDS[0]}/$SED_MARK; "
    if [ "$B_INCLUDE" == "true" ]; then
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

#====================================

ProcessParam $*
GenerateCommand
DEBUG echo "FILTER: $FILTER"
PrintCommandInfo

TMP_LOG=/tmp/tmp_text_filter_$(date +%m%d%H%M%S)
FILTER_LOG=$SH_DOCUMENT/$(basename $FILE_PATH)"_filtered_"$(date +%m%d%H%M%S)

if [ ! -d $SH_DOC ]; then
    mkdir $SH_DOC
fi
if [ ! -d $SH_DOCUMENT ]; then
    mkdir $SH_DOCUMENT
fi

sed $SED_OPTION "$COMMAND" $FILE_PATH >> $TMP_LOG
cat $TMP_LOG | uniq >> $FILTER_LOG

if [ -f $FILTER_LOG ]; then
    echo "Filtered text has been created:"
    echo $FILTER_LOG
    [ "$B_GEDIT" == "true" ] && gedit $FILTER_LOG &
else
    echo "Fail to create FILTER_LOG"
fi
echo

