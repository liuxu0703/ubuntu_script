#!/bin/bash
#v1.0   find text in current dir
#v1.1   add feature "more"
#v1.2   find with mutiple options, like -c -cpp (for now it did not work as expected)
#       can indicate a folder now, before this version it only looking up in the current dir

find_dir="./"               #default search for current dir
declare -a find_name         #array for printing output info
declare -a find_option       #find option array

function ShellHelp() {
    local shell_name=`basename $0`
    echo
    echo "Help of ## $0 ## : "
    echo
    echo "           $shell_name [option1] [option2] ... dir keyword1 keyword2 keyword3 ... "
    echo "           ** keyword ** indicate keywords you want to look up"
    echo "           ** dir **     indicate the dir to be looking up"
    echo "           ** option -h    : look up in .h head files"
    echo "           ** option -java : look up in java source files"
    echo "           ** option -c    : look up in c source files"
    echo "           ** option -cpp  : look up in cpp source files"
    echo "           ** option -xml  : look up in xml source files"
    echo
    echo "           without ** option **   $shell_name will look up in all files in the dir"
    echo "           without ** keyword **  $shell_name will print error info and help"
    echo "           without ** dir **      $shell_name will look up in current dir"
    echo
}

#====================================
#process options

if [ $# -eq 0 ]; then
    echo
    echo "no keywords and options are specified to be looked up!"
    ShellHelp
    exit
fi

i=0
while true; do
    if [ "$1" == "-java" ]; then
        find_name[$i]="\".java\""
        find_option[$i]="-name \"*.java\""
        shift
    elif [ "$1" == "-c" ]; then
        find_name[$i]="\".c\""
        find_option[$i]="-name \"*.c\""
        shift
    elif [ "$1" == "-cpp" ]; then
        find_name[$i]="\".cpp\""
        find_option[$i]="-name \"*.cpp\""
        shift
    elif [ "$1" == "-xml" ]; then
        find_name[$i]="\".xml\""
        find_option[$i]="-name \"*.xml\""
        shift
    elif [ "$1" == "-h" ]; then
        find_name[$i]="\".h\""
        find_option[$i]="-name \"*.h\""
        shift
    elif [ "$1" == "-mk" ]; then
        find_name[$i]="\".mk\""
        find_option[$i]="-name \"*.mk\""
        shift
    elif [ "$1" == "-py" ]; then
        find_name[$i]="\".py\""
        find_option[$i]="-name \"*.py\""
        shift
    elif [ "$1" == "-rc" ]; then
        find_name[$i]="\".rc\""
        find_option[$i]="-name \"*.rc\""
        shift
    else
        break
    fi
    let i++
done

if [ 0 -eq ${#find_option[*]} ]; then    #with no option this shell will look for all files
    find_option[0]="-type f"
    find_name[0]="all type"
fi

#echo "find option : ${find_option[*]}"

#====================================
#generate keyword

if [ -d "$1" ]; then
    find_dir=$1
    shift
fi

if [ $# -eq 0 ]; then
    echo
    echo "no keyword is specified to be looked up!"
    ShellHelp
    exit
fi

declare -a keyword
i=0
while true; do
    [ $# -eq 0 ] && break
    keyword[$i]="$1"
    shift
    let i++
done

#====================================
#looking up keyword

#the purpose of writing this function is to use pipe command "| more"
function FindText() {
    #echo "searching in ${find_name[*]} files."
    local i=0
    while [ $i -lt ${#keyword[*]} ]; do
        echo
        echo "********************** looking up for : ${keyword[$i]} **********************"
        local j=0
        while [ $j -lt ${#find_option[*]} ]; do
            #echo "find $find_dir ${find_option[$j]} -print | xargs grep -s ${keyword[$i]}"
            eval find $find_dir ${find_option[$j]} -print | xargs grep -s -H "${keyword[$i]}"
            let j++
        done
        let i++
    done
    echo
}

FindText | more

