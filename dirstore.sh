#!/bin/bash
#v1.0   2011-12-30  store directorys
#v1.1   2012-02-08  add -l option, use the latest dir_store as current
#v1.2   2012-03-01  add -d option, delete a given dir
#v1.3   2012-03-19  add -c option, store compiled libs into compiled_store
#v1.4   2012-10-24  change -x option.
#                   Now, by default, dirstore.sh will NOT store file dir with a file
#                   add -s option, store file dir with file
#v1.5   2013-01-29  add -g option, goto dir

SH_DOC="$HOME/my_bash/sh_document"
SH_DOCUMENT=$SH_DOC/document$(date +%m%d)
TMP=/tmp/dirstore_tmp_$(date +%m%d%H%M%S)
DIR_STORE=$SH_DOCUMENT/dir_store
COM_LIBS_STORE=$SH_DOCUMENT/compiled_store
B_USE_COM_STORE="false"
B_STORE_FILE_DIR="false"
FILE_LINE=
DIR_LINE=
DEBUG="false"

trap "CLEAR_WORK" EXIT

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

CLEAR_WORK() {
    if [ -f $TMP ]; then
        rm -f $TMP
    fi
}

function ShellHelp() {
cat <<EOF

--------------------------------------------------------------------------------
USAGE:
dirstore.sh file
dirstore.sh [-n|-l|-s|-c|-g]
dirstore.sh -d file

OPTIONS:
-h    : print this help.
-n    : create a new index.
-l    : pick up the latest dir_store as current.
-s    : if a file path is given, store its parent dir with it. no use when param is a dir.
-d    : delete a given dir, this option should followed by a path.
-c    : show or store compiled libs (into compiled_store).

DESCRIPTION:
without param this sh will show the stored dirs.
with a path as param, the path is then stored.

--------------------------------------------------------------------------------

EOF
}

#locate newest file in $SH_DOCUMENT
#return full path of newest package
function LocateNewestFile()
{
	local filename_array=($(find $SH_DOC -name "dir_store" -type f))
	local filetime_array=($(stat -c %Y ${filename_array[@]}))

	local compare_tmp=0
	local n=0
	for i in $(seq ${#filetime_array[@]}); do
		j=$(expr $i - 1)
		if [ ${filetime_array[$j]} -ge $compare_tmp ]; then
			compare_tmp=${filetime_array[$j]}
			n=$j
			DEBUG echo " n: $n"
			DEBUG echo "compare_tmp: $compare_tmp"
		fi
	done

	echo ${filename_array[$n]}
}

if [ ! -d $SH_DOC ]; then
    mkdir $SH_DOC
fi

if [ ! -d $SH_DOCUMENT ]; then
    mkdir $SH_DOCUMENT
fi

if [ "$1" == "-h" ]; then
    ShellHelp
    exit 0
elif [ "$1" == "-n" ]; then
    [ -f $DIR_STORE ] && rm $DIR_STORE
    shift
elif [ "$1" == "-s" ]; then
    B_STORE_FILE_DIR="true"
    shift
elif [ "$1" == "-l" ]; then
    [ -f $DIR_STORE ] || cp $(LocateNewestFile) $SH_DOCUMENT/
    shift
elif [ "$1" == "-d" ]; then
    line_num=
    shift

    if [ -f $1 ]; then
        FILE_LINE=$(readlink -f $1)
        line_num=$(grep -n "$FILE_LINE" $DIR_STORE | sed -n '1,1p' | awk -F ":" '{print $1}')
        sed "${line_num},${line_num}d" $DIR_STORE > $TMP
    elif [ -d $1 ]; then
        DIR_LINE=$(readlink -f $1)"/"
        line_num=$(grep -n "$DIR_LINE" $DIR_STORE | sed -n '1,1p' | awk -F ":" '{print $1}')
        sed "${line_num},${line_num}d" $DIR_STORE > $TMP
    else
        DIR_LINE=$1
        tmp_grep=$(grep -n "$DIR_LINE" $DIR_STORE)
        if [ "$tmp_grep" == "" ]; then
            echo
            echo "no line matches the given param, cannot delete"
            echo
            exit 2
        fi
        line_num=$(echo $tmp_grep | sed -n '1,1p' | awk -F ":" '{print $1}')
        sed "${line_num},${line_num}d" $DIR_STORE > $TMP
    fi
    DEBUG echo "line_num: $line_num"
    DEBUG cat $TMP
    cp $TMP $DIR_STORE
    exit 0
elif [ "$1" == "-c" ]; then
    DIR_STORE=$COM_LIBS_STORE
    B_USE_COM_STORE="true"
    shift
fi

DEBUG echo "DEBUG: -c option enabled: $B_USE_COM_STORE ; display file: $DIR_STORE"

if [ $# -eq 0 ]; then
    if [ -f $DIR_STORE ]; then
        if [ "$B_USE_COM_STORE" == "true" ]; then
            [ -f $DIR_STORE ] && cp $DIR_STORE $TMP
            sort -n $TMP | uniq > $DIR_STORE
        fi
        echo
        cat $DIR_STORE
        echo
        exit 0
    else
        echo
        exit 0
    fi
fi

if [ $# -eq 1 ]; then
    DEBUG echo "DEBUG: param1 : $1"
    [ -f $DIR_STORE ] && cp $DIR_STORE $TMP
    if [ -f $1 ]; then
        FILE_LINE=$(readlink -f $1)
        echo $FILE_LINE >> $TMP
        if [ "$B_USE_COM_STORE" == "false" -a "$B_STORE_FILE_DIR" == "true" ]; then
            DIR_LINE=$(dirname $FILE_LINE)"/"
            echo $DIR_LINE >> $TMP
        fi
        sort -n $TMP | uniq > $DIR_STORE
    elif [ -d $1 ]; then
        if [ "$B_USE_COM_STORE" == "true" ]; then
            echo
            echo "param should be a full path of a file."
            exit 1
        fi
        DIR_LINE=$(readlink -f $1)"/"
        echo $DIR_LINE >> $TMP
        sort -n $TMP | uniq > $DIR_STORE
    else
        echo
        echo "param should be a dir or file path!"
        echo
        exit 1
    fi
fi
DEBUG more $DIR_STORE

exit 0

