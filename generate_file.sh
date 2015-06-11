#!/bin/bash
#v1.0   generate a size-specified file according to param
#v2.0   improve algorithm, make it faster to generate bigger file

KB_THRESHOLD=1024
MB_THRESHOLD=50
PARAM_KB=
PARAM_MB=
declare -a KB_NUM_ARR
declare -a MB_NUM_ARR

FILENAME="/tmp/f_"$(date +%H%M%S)
DEBUG="false"

#=======================================

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp() {
    local shell_name=`basename $0`
    echo
    echo "Help of ## $0 ## : "
    echo "  generate a file with specified size"
    echo "  params should be like this:"
    echo "      *mb *kb"
    echo "  for example, generate a file with size of 20mb+50kb would be:"
    echo "      20mb 50kb"
    echo "  this sh needs at least one of the 2 params to run"
    echo "  kb should not exceed $KB_THRESHOLD"
    echo "  mb should not exceed $MB_THRESHOLD"
    echo
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

function PrintDebugInfo() {
    if [ "$DEBUG" == "true" ]; then
        echo "=========DEBUG=========="
        echo
        echo "KB_NUM_ARR:"
        for aaa in ${KB_NUM_ARR[*]}; do
            echo $aaa
        done
        echo
        echo "MB_NUM_ARR:"
        for aaa in ${MB_NUM_ARR[*]}; do
            echo $aaa
        done
        echo
        echo "=========DEBUG=========="
    fi
}

#=======================================

#generate a str of 1kb
#yield a str of 1kb
function GenerateKb() {
    local byte2="1 "
    local byte4="$byte2$byte2"
    local byte8="$byte4$byte4"
    local byte16="$byte8$byte8"
    local byte32="$byte16$byte16"
    local byte64="$byte32$byte32"
    local byte128="$byte64$byte64"
    local byte256="$byte128$byte128"
    local byte512="$byte256$byte256"
    local byte1024="$byte512$byte512"
    echo $byte1024
}

#generate a str of 1mb
#yield a str of 1mb
function GenerateMb() {
    local kb=$(GenerateKb)" "
    local kb2="$kb$kb"
    local kb4="$kb2$kb2"
    local kb8="$kb4$kb4"
    local kb16="$kb8$kb8"
    local kb32="$kb16$kb16"
    local kb64="$kb32$kb32"
    local kb128="$kb64$kb64"
    local kb256="$kb128$kb128"
    local kb512="$kb256$kb256"
    local kb1024="$kb512$kb512"
    echo $kb1024
}

#$1 shoud be a str
#yield a str ten time length of $1
function TimeTen() {
    local str_one="$1 "
    local str_ten=""
    for (( i=0 ; i<10 ; i++)); do
        str_ten="$str_ten""$str_one"
    done
    echo $str_ten
}

#$1 shoud be a str
#yield a str a hundred time length of $1
function TimeHundred() {
    local str_ten=$(TimeTen "$1")" "
    local str_hun=""
    for (( i=0 ; i<10 ; i++)); do
        str_hun="$str_hun""$str_ten"
    done
    echo $str_hun
}

#$1 shoud be a str
#yield a str a thousand time length of $1
function TimeThousand() {
    local str_hun=$(TimeHundred "$1")" "
    local str_thou=""
    for (( i=0 ; i<10 ; i++)); do
        str_thou="$str_thou""$str_hun"
    done
    echo $str_thou
}

#$1 should be a str
#$2 should be an interger
#yield a str $2 time length of $1
function TimeAny() {
    local ret=""
    local interger=$(IsInterger $2)

    if [ "$interger" == "false" ]; then
        echo $ret
        return
    fi

    local n=$(expr $2)
    for (( i=0 ; i<n ; i++ )); do
        ret="$ret$1"
    done

    echo $ret
}

#=======================================

#param should be $@
function ProcessParam() {
    if [ $# -gt 2 ]; then
        echo
        echo "* too many params !!!"
        ShellHelp
        exit
    fi

    local tmpstr; local tmpkb; local tmpmb
    local param_kb; local param_mb
    local n; local n_zero

    for param in $@; do
        param_kb=$(echo $param | awk -F "k" '{print $1}')
        tmpkb=$(echo $param | awk -F "k" '{print $2}')
        param_mb=$(echo $param | awk -F "m" '{print $1}')
        tmpmb=$(echo $param | awk -F "m" '{print $2}')
        DEBUG echo "DEBUG, tmpkb    : $tmpkb"
        DEBUG echo "DEBUG, tmpmb    : $tmpmb"

        if [ "$tmpkb" == "b" ]; then
            DEBUG echo "DEBUG, param_kb : $param_kb"
            tmpstr=$(IsInterger $param_kb 1 $KB_THRESHOLD)

            if [ "$tmpstr" == "true" ]; then
                PARAM_KB=$param
                n_zero=$(echo $param_kb | wc -m)
                DEBUG echo "n_zero : $n_zero"
                while [ $n_zero -lt 5 ];do
                    param_kb="0"$param_kb
                    let n_zero++
                done
                DEBUG echo "DEBUG, param_kb : $param_kb"

                for i in 1 2 3 4; do
                    n=$(expr $i - 1)
                    local tmpnum=$(echo $param_kb | cut -c $i)
                    KB_NUM_ARR[$n]=$(expr $tmpnum)
                done
            else
                echo
                echo "* wrong param or param too big !!!"
                ShellHelp
                exit
            fi
        elif [ "$tmpmb" == "b" ]; then
            DEBUG echo "DEBUG, param_mb : $param_mb"
            tmpstr=$(IsInterger $param_mb 1 $MB_THRESHOLD)

            if [ "$tmpstr" == "true" ]; then
                PARAM_MB=$param
                n_zero=$(echo $param_mb | wc -m)
                DEBUG echo "n_zero : $n_zero"
                while [ $n_zero -lt 5 ];do
                    param_mb="0"$param_mb
                    let n_zero++
                done
                DEBUG echo "DEBUG, param_mb : $param_mb"
                for i in 1 2 3 4; do
                    n=$(expr $i - 1)
                    local tmpnum=$(echo $param_mb | cut -c $i)
                    MB_NUM_ARR[$n]=$(expr $tmpnum)
                done
            else
                echo
                echo "* wrong param or param too big !!!"
                ShellHelp
                exit
            fi
        else
            echo
            echo "* wrong param !!!"
            ShellHelp
            exit
        fi
    done
}

function GenerateFile() {
    FILENAME=$FILENAME"_"$PARAM_MB$PARAM_KB
    DEBUG echo "DEBUG, GenerateFile, PARAM_KB=$PARAM_KB"
    DEBUG echo "DEBUG, GenerateFile, PARAM_MB=$PARAM_MB"

    #generate kb
    if [ ! "$PARAM_KB" == "" ]; then
        local i=0
        local charkb=$(GenerateKb)

        if [ ${KB_NUM_ARR[3]} -gt 0 ]; then
            i=0
            while [ $i -lt ${KB_NUM_ARR[3]} ]; do
                echo $charkb >> $FILENAME
                let i++
            done
        fi

        if [ ${KB_NUM_ARR[2]} -gt 0 ]; then
            local charkb10=$(TimeTen "$charkb")
            i=0
            while [ $i -lt ${KB_NUM_ARR[2]} ]; do
                echo $charkb10 >> $FILENAME
                let i++
            done
        fi

        if [ ${KB_NUM_ARR[1]} -gt 0 ]; then
            if [ -n "$charkb10" ]; then
                local charkb100=$(TimeTen "$charkb10")
            else
                local charkb100=$(TimeHundred "$charkb")
            fi

            i=0
            while [ $i -lt ${KB_NUM_ARR[1]} ]; do
                echo $charkb100 >> $FILENAME
                let i++
            done
        fi

        if [ ${KB_NUM_ARR[0]} -gt 0 ]; then
            if [ -n "$charkb100" ]; then
                echo $(TimeTen "$charkb100") >> $FILENAME
            elif [ -n "$charkb10" ]; then
                echo $(TimeHundred "$charkb10") >> $FILENAME
            else
                echo $(TimeThousand "$charkb") >> $FILENAME
            fi
        fi

    fi  #end of [ -n $STR_KB ]

    #generate mb
    if [ ! "$PARAM_MB" == "" ]; then
        local i=0
        local charmb=$(GenerateMb)

        if [ ${MB_NUM_ARR[3]} -gt 0 ]; then
            i=0
            while [ $i -lt ${MB_NUM_ARR[3]} ]; do
                echo $charmb >> $FILENAME
                let i++
            done
        fi

        if [ ${MB_NUM_ARR[2]} -gt 0 ]; then
            local charmb10=$(TimeTen "$charmb")
            i=0
            while [ $i -lt ${MB_NUM_ARR[2]} ]; do
                #echo "......"
                echo $charmb10 >> $FILENAME
                let i++
            done
        fi

        if [ ${MB_NUM_ARR[1]} -gt 0 ]; then
            if [ -n "$charmb10" ]; then
                local charmb100=$(TimeTen "$charmb10")
            else
                local charmb100=$(TimeHundred "$charmb")
            fi

            i=0
            while [ $i -lt ${MB_NUM_ARR[1]} ]; do
                #echo "......"
                echo $charmb100 >> $FILENAME
                let i++
            done
        fi

        if [ ${MB_NUM_ARR[0]} -gt 0 ]; then
            if [ -n "$charmb100" ]; then
                echo $(TimeTen "$charmb100") >> $FILENAME
            elif [ -n "$charmb10" ]; then
                echo $(TimeHundred "$charmb10") >> $FILENAME
            else
                echo $(TimeThousand "$charmb") >> $FILENAME
            fi
        fi

    fi  #end of [ -n $STR_MB ]
}

#=======================================

ProcessParam $@
DEBUG PrintDebugInfo
GenerateFile

echo
echo "File Name     : $FILENAME"
echo "Elapsed Time  : $SECONDS"
echo

