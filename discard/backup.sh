#!/bin/bash
#v1.1

#v1.0   bakup file according to current system time
#v1.1   use "./" to run sh from now on.
#v2.0   2012-08-13
#       re-write
#       add return value:
#       1: param number not right (not 1 or 2)
#       2: param1 not a path
#       3: param2 not valid

DEBUG="false"
SRC_FILE=
DST_FILE=

#====================================

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp()
{
    local shell_name=`basename $0`
    echo
    echo "NAME:"
    echo "$shell_name: "
    echo
    echo "USAGE:"
    echo "backup path1 [path2]"
    echo
    echo "OPTIONS:"
    echo "NONE"
    echo
    echo "DESCRIPTION:"
    echo "backup file or dir. if path2 is not given, the backup file will store in the same dir of path1"
    echo
}

function CreateNewFolder() {
	echo "$2 dir does not exist!"
	dst_file_dir=`dirname $1`/$2
	read -t 10 -p "do you want to create a new folder: ${dst_file_dir}?(y/n)" yn
	if [ "$yn" == "y" ]; then
		mkdir $dst_file_dir
	else
		ShellHelp
		exit
	fi
}

#param should be $@
function ProcessParam() {
    if [ $# -ne 1 -a $# -ne 2 ]; then
	    echo "* Too many or to few params!"
	    ShellHelp
	    exit 1
    fi
    
    if [ ! -e $1 ]; then
	    echo "* $1 does not exist!"
	    exit 2
	else
	    SRC_FILE=$(readlink -f $1)
	    DST_FILE=$SRC_FILE"."$(date +%m%d%H%M%S)".bkup"
    fi
    
    if [ ! "$2" == "" ]; then
        tmp_dir=$(readlink -f $2)
        tmp_upper_dir=$(dirname $tmp_dir)
        DEBUG echo "tmp_dir:        $tmp_dir"
        DEBUG echo "tmp_upper_dir:  $tmp_upper_dir"
        if [ -d $tmp_dir ]; then
            DST_FILE=$tmp_dir/$(basename $SRC_FILE)"."$(date +%m%d%H%M%S)".bkup"
        elif [ -d $tmp_upper_dir ]; then
            echo "$2 dir does not exist!"
		    read -t 10 -p "do you want to create a new folder: $tmp_dir? (y/n)" yn
		    if [ "$yn" == "y" ]; then
			    mkdir $tmp_dir
                DST_FILE=$tmp_dir/$(basename $SRC_FILE)"."$(date +%m%d%H%M%S)".bkup"
		    else
			    ShellHelp
			    exit 0
		    fi
		else
		    echo "* param 2 is not valid: $2"
		    ShellHelp
		    exit 3
        fi
    fi
}

ProcessParam $@
cp -r $SRC_FILE $DST_FILE

if [ -e $DST_FILE ]; then
    echo "* backup file has been created: "
    echo $DST_FILE
else
    echo "* fail to create backup file."
fi

