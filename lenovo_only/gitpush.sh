#!/bin/bash

#       AUTHOR : liuxu
#v1.0   first version
#       I can't remember "git push" command with reviewers, that's why this sh is written.

CMD=
BRANCH=
declare -a REVIEWERS
declare -a COM_REVIEWERS

#commonly used reviewers
COM_REVIEWERS=(\
    hongnb@lenovo.com\
    zhongwei1@lenovo.com\
    wangbin@lenovomobile.com\
    tianyn@lenovo.com\
    yuxlg@lenovo.com\
    lincq1@lenovo.com\
    dingyqa@lenovo.com\
    yangweia@lenovo.com\
    zhengrl@lenovo.com\
)

#====================================

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:
gitpush Branch [Reviewers ...]

DESCRIPTION:
without reviewers, this sh will show a list of commonly used reviewers to select.
--------------------------------------------------------------------------------

EOF
}

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

function SelectReviewer() {
    local idx=1
    
    echo
    echo "Already Picked Reviewers: ${REVIEWERS[@]}"
    echo
    echo "Available Commconly Used Reviewers:"
    
    for reviewer in ${COM_REVIEWERS[@]}; do
        echo "  [$idx]. $reviewer"
        let idx++
    done
    
    echo "  [X]. Done Picking"
    read -p "Pick a Reviewer ['Enter' to finish pick]: "
    
    if [ $(IsInteger $REPLY 1 ${#COM_REVIEWERS[*]}) == "true" ]; then
        local n=$(expr $REPLY - 1)
        local length=${#REVIEWERS[@]}
        REVIEWERS[$length]=${COM_REVIEWERS[$n]}
        SelectReviewer
    elif [[ ( "$REPLY" == "" ) || ( "$REPLY" == "x" ) || ( "$REPLY" == "X" ) ]]; then
        return
    else
        echo
        echo "Invalidate Selection !!!"
        echo
        exit
    fi
    
}

#====================================

BRANCH=$1
if [ "$BRANCH" == "" ]; then
    echo
    echo "* A branch must be specified."
    ShellHelp
    exit
fi
shift

if [ $# -eq 0 ]; then
    SelectReviewer
else
    for arg in $@; do
        length=${#REVIEWERS[@]}
        REVIEWERS[$length]=$arg
    done
fi

CMD="git push --receive-pack='git receive-pack "
for reviewer in ${REVIEWERS[@]}; do
    CMD="$CMD --reviewer $reviewer"
done
CMD="$CMD' nov HEAD:refs/for/$BRANCH"

echo
echo "git command generated: "
echo $CMD
echo
read -p "Is it right? ['Enter' to confirm]: "
echo
if [ "$REPLY" == "" ]; then
    eval "$CMD"     #use eval to prevent ' from being ignored
else
    exit
fi
