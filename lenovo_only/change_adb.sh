#!/bin/bash
#v1.0   2011-12-27

BKUP_ADB_HEAD="adb"
BKUP_ADB_TAIL="bkup"
ADB=/usr/local/bin/adb
declare -a PJ_WITH_ADB_ARR           #array of all project name in $CODE_DIR
declare -a ADB_ARR          #array of all available adbs
DEBUG="false"

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp() {
    local shell_name=`basename $0`
    echo
    echo "Help of ## $0 ## : "
    echo "    give the user a list of adbs to choose."
    echo
}

function CheckBackupADBs() {
    declare -a pj_arr=($(find $CODE_DIR -maxdepth 1 -type d | sort -n))    #list of all dir in CODE_DIR

    local bkup_adb
    local compile_adb
    local pj_name
    local i=0; local j=0
    while [ $i -lt ${#pj_arr[*]} ]; do  #delete $1 from pj_arr
        pj_arr[$i]=$(basename ${pj_arr[$i]})
        if [ "${pj_arr[$i]}" != "code" ]; then
            pj_name=${pj_arr[$i]}
            bkup_adb=$CODE_DIR/$pj_name/$BKUP_ADB_HEAD.$pj_name.$BKUP_ADB_TAIL
            compile_adb=$CODE_DIR/$pj_name/out/host/linux-x86/bin/adb
            if [ -f $compile_adb ]; then
                if [ -f $bkup_adb ]; then
                    [ $bkup_adb -ot $compile_adb ] && cp $compile_adb $bkup_adb
                else
                    cp $compile_adb $bkup_adb
                fi
            fi

            if [ -f $bkup_adb ]; then
                PJ_WITH_ADB_ARR[$j]=$pj_name
                let j++
            fi
        fi
        let i++
    done

    unset pj_arr
}

function ListProjectWithADBs() {
    local i=0
    local index=0
    while [ $i -lt ${#PJ_WITH_ADB_ARR[*]} ]; do
        index=$(expr $i + 1)
        echo "  [$index]. ${PJ_WITH_ADB_ARR[$i]}"
        let i++
    done
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

if [ "$1" == "-h" ]; then
    ShellHelp
    exit 0
fi

CheckBackupADBs
echo
echo "Choose An adb to set as default: "
ListProjectWithADBs
echo "  [X]. Do Nothing and Exit"
read -p "choose an adb or exit: "

if [[ ( "$REPLY" == "x" ) || ( "$REPLY" == "X" ) ]]; then
    #echo "do nothing and exit."
    echo
    exit 0
elif [ $(IsInterger $REPLY 1 ${#PJ_WITH_ADB_ARR[*]}) == "true" ]; then
    n=$(expr $REPLY - 1)
else
    echo "Invalidate Selection !!!"
    echo
    exit 1
fi

sudo adb kill-server
sudo cp $CODE_DIR/${PJ_WITH_ADB_ARR[$N]}/$BKUP_ADB_HEAD.${PJ_WITH_ADB_ARR[$N]}.$BKUP_ADB_TAIL $ADB
sudo chmod a+s $ADB
exit 0

