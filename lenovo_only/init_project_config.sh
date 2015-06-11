#!/bin/bash

#       AUTHOR : liuxu

#I've exported this var through .bashrc. so just commit the code here. 
#DEFAULT_CONFIG_TAG="Config"
AUTO_COMPILE=autocompile.sh

PROJ_NAME=
PROJ_ROOT=
LUNCH_NUM=

BRANCH=
REPO_INIT_CMD=
B_REPO_INIT="false"
B_COMPILE="false"
DEBUG="true"

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
init_project_config.sh [-l Lunch_num] [-i [-b Branch]] [-c]

OPTIONS:
-l: specify a lunch number
-i: run "repo init" after config files created
-b: specify a project branch
-c: compile project after config files created

DESCRIPTION:
init project config files

--------------------------------------------------------------------------------

EOF
}

#====================================

function CreateProjectConfig() {
    echo "PROJECT_NAME=$PROJ_NAME"          >> $PROJ_ROOT/$PROJ_NAME.$DEFAULT_CONFIG_TAG
    echo "PROJECT_DIR=$PROJ_ROOT"           >> $PROJ_ROOT/$PROJ_NAME.$DEFAULT_CONFIG_TAG
    echo "DEFAULT_LUNCH_NUM=$LUNCH_NUM"     >> $PROJ_ROOT/$PROJ_NAME.$DEFAULT_CONFIG_TAG
    echo "DEFAULT_COMBO="                   >> $PROJ_ROOT/$PROJ_NAME.$DEFAULT_CONFIG_TAG
    echo "IS_ACTIVE_PROJECT=true"           >> $PROJ_ROOT/$PROJ_NAME.$DEFAULT_CONFIG_TAG
}

#write words to a file
#$1 should be full path of the file
#$2, $3, ... should be words
function WriteToFile() {
    if [ ! -e $1 ]; then
        echo "ERROR: WriteToFile: $1 should be full path of a file"
        echo
        return 1
    fi
    local file_path=$(readlink -f $1)
    shift
    echo $@ >> $file_path
    return 0
}

function CreateAutoCompile() {
    local auto_compile=$PROJ_ROOT/$AUTO_COMPILE

cat >> $auto_compile <<"EOF"
#!/bin/bash
#options     :  -s: repo sync
#               -r: rm -rf /out
#               -d: du -sh /out
#               -p: poweroff

EOF

WriteToFile $auto_compile "PROJECT_NAME=$PROJ_NAME"

cat >> $auto_compile <<"EOF"
PROJECT_PATH=$CODE_DIR/$PROJECT_NAME
B_REPO_SYNC="false"
B_REMOVE_OUT="false"
B_POWEROFF="false"
B_DU_SH="false"
OUT_DIR_SIZE=
ERROR_STR="Nothing is wrong"
DEBUG="false"
INFO_FILE="$HOME/desktop/"$PROJECT_NAME"_compile_info_"$(date +%m%d%H%M%S)

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

#==============================
#add LUNCH_NUM here !!!
LUNCH_NUM=
COMBO=
B_USE_INTEGRATE="false"
INTEFRATE_PROJECT_NAME=$PROJECT_NAME
#==============================

if [ "$LUNCH_NUM" == "" -a "$COMBO" == "" ]; then
    if [ -f $PROJECT_PATH/$PROJECT_NAME.$DEFAULT_CONFIG_TAG ]; then
        LUNCH_NUM=$(sed -n '/^DEFAULT_LUNCH_NUM/'p $PROJECT_PATH/$PROJECT_NAME.$DEFAULT_CONFIG_TAG | awk -F "=" '{print $2}')
        COMBO=$(sed -n '/^DEFAULT_COMBO/'p $PROJECT_PATH/$PROJECT_NAME.$DEFAULT_CONFIG_TAG | awk -F "=" '{print $2}')
    fi
fi

DEBUG echo "LUNCH_NUM=$LUNCH_NUM"
DEBUG echo "COMBO=$COMBO"

ERRORTRAP() {
    local shell_name=`basename $0`
    ERROR_NUM=$?
    echo "====================" | tee -a $INFO_FILE
    echo "MY SHELL ERROR: "     | tee -a $INFO_FILE
    echo "NAME: $shell_name"    | tee -a $INFO_FILE
    echo "ERRNO: $ERROR_NUM"    | tee -a $INFO_FILE
    echo "====================" | tee -a $INFO_FILE
    ERROR_STR="MY SHELL ERROR, ERRNO: $ERROR_NUM"
}
trap "ERRORTRAP" ERR

function ShellHelp() {
    local shell_name=`basename $0`
    echo "USAGE:"
    echo "$shell_name [OPTION]"
    echo
    echo "DESCRIPTION:"
    echo "compile android project. several steps can be executed in sequence due to the specified options."
    echo
    echo "OPTIONS:"
    echo "  -r: rm -rf /out"
    echo "  -s: repo sync"
    echo "  -d: du -sh"
    echo "  -p: poweroff"
    echo "  -h: shell help"
    echo
}

#suspend system, give user some time to abort "poweroff" operation
function Poweroff() {
    echo
    echo "about to poweroff ......"
    local count=200
    while [ $count -ge 0 ]; do
        echo
        echo "poweroff count down : $count"
        sleep 3s
        let count--
    done
    sudo poweroff
}

#param should be $@
function ProcessParam() {
    local errno=0
    while getopts "rspdh" opt; do
        case "$opt" in
            "s")
                B_REPO_SYNC="true"
                ;;
            "r")
                B_REMOVE_OUT="true"
                ;;
            "p")
                B_POWEROFF="true"
                ;;
            "d")
                B_DU_SH="true"
                ;;
            "h")
                ShellHelp
                exit 0
                ;;
            "?")
                #Unknown option
                echo "unknown option: $opt"
                errno=1
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "option $OPTARG needs a value, but it is not presented"
                errno=1
                ;;
            *)
                #unknown error, should not occur
                echo "unknown error while processing options and params"
                errno=2
                ;;
        esac
    done
    return $errno
}

function RepoSync() {
    cd $PROJECT_PATH
    repo sync
    #cd -
}

function Compile() {
    cd $PROJECT_PATH
    
    if [ "$B_USE_INTEGRATE" == "true" ]; then
        cd integrate
        ./setenv.sh proj=$INTEFRATE_PROJECT_NAME uboot=../bootable/bootloader/uboot/ kernel=../kernel app=..
        make all    | tee -a $INFO_FILE
        
        echo "integrate compile, project name passed to setenv.sh is: $INTEFRATE_PROJECT_NAME ."    | tee -a $INFO_FILE
        echo "when thing is not right, check if the project name is correct."                       | tee -a $INFO_FILE
        
        return
    fi    
    
    . build/envsetup.sh
    
    if [ ! "$COMBO" == "" ]; then
        choosecombo $COMBO
    elif [ ! "$LUNCH_NUM" == "" ]; then
        lunch $LUNCH_NUM
    else
        echo "MY SHELL ERROR: we should not get here" | tee -a $INFO_FILE
        return
    fi
    
    make update-api     | tee -a $INFO_FILE
    make                | tee -a $INFO_FILE
}

function PrintInfo() {
    echo "=========================="   | tee -a $INFO_FILE
    echo "PROJECT_NAME=$PROJECT_NAME"   | tee -a $INFO_FILE
    echo "PROJECT_PATH=$PROJECT_PATH"   | tee -a $INFO_FILE
    echo "LUNCH_NUM=$LUNCH_NUM"         | tee -a $INFO_FILE
    echo "COMBO=$COMBO"                 | tee -a $INFO_FILE
    echo "B_REPO_SYNC=$B_REPO_SYNC"     | tee -a $INFO_FILE
    echo "B_REMOVE_OUT=$B_REMOVE_OUT"   | tee -a $INFO_FILE
    echo "B_POWEROFF=$B_POWEROFF"       | tee -a $INFO_FILE
    echo "B_DU_SH=$B_DU_SH"             | tee -a $INFO_FILE
    echo "OUT_DIR_SIZE=$OUT_DIR_SIZE"   | tee -a $INFO_FILE
    echo "ERROR_STR=$ERROR_STR"         | tee -a $INFO_FILE
    echo "=========================="   | tee -a $INFO_FILE
}

ProcessParam $@

if [ $? -ne 0 ]; then
    echo "something wrong, pls check input options."
    exit 1
fi

PrintInfo

if [ "$B_REPO_SYNC" == "true" ]; then
    RepoSync
fi

if [ "$B_REMOVE_OUT" == "true" ]; then
    [ -d $PROJECT_PATH/out ] && rm -rf $PROJECT_PATH/out
fi

Compile

if [ "$B_DU_SH" == "true" ]; then
    [ -d $PROJECT_PATH/out ] && OUT_DIR_SIZE=$(du -sh $PROJECT_PATH/out)
fi

PrintInfo

if [ "$B_POWEROFF" == "true" ]; then
    Poweroff
fi
EOF

sudo chmod a+x $auto_compile
}

#====================================
#process args and opts

#process options
function ProcessOptions() {
    while getopts ":l:b:ic" opt; do
        DEBUG echo "opt: $opt"
        case "$opt" in
            "l")
                LUNCH_NUM=$OPTARG
                ;;
            "i")
                B_REPO_INIT="true"
                ;;
            "b")
                BRANCH=$OPTARG
                ;;
            "c")
                B_COMPILE="true"
                ;;
            "?")
                #Unknown option
                echo "* unknown option: $opt"
                ShellHelp
                exit
                ;;
            ":")
                #an option needs a value, which, however, is not presented
                echo "* option $OPTARG needs a value, but it is not presented"
                ShellHelp
                exit
                ;;
            *)
                #unknown error, should not occur
                echo "* unknown error while processing options and params"
                ShellHelp
                exit
                ;;
        esac
    done
    return $OPTIND
}

#process args
function ProcessArgs() {
    DEBUG echo "args: $@"
    if [ $# -eq 0 ]; then
        ShellHelp
        exit
    elif [ ! -d $1 ]; then
        echo
        echo "* A project root path must be specified."
        echo
        ShellHelp
        exit
    fi

    PROJ_ROOT=$(readlink -f $1)
    PROJ_NAME=$(basename $PROJ_ROOT)
    [ "$BRANCH" == "" ] && BRANCH=phone/$PROJ_NAME
    REPO_INIT_CMD="repo init -u rocket:platform/manifest -b $BRANCH"
}

#====================================

ProcessOptions "$@"
arg_start=$?
ProcessArgs "${@:$arg_start}"

echo
echo "Project Root Path:    $PROJ_ROOT"
echo "Project Name:         $PROJ_NAME"
echo "repo init command:    $REPO_INIT_CMD"
echo

read -p "Is everything right? ['Enter' to confirm]: "
if [ ! "$REPLY" == "" ]; then
    echo
    exit
fi

echo
echo "Project config file and autocompile.sh generated: "
echo $PROJ_ROOT/$PROJ_NAME.$DEFAULT_CONFIG_TAG
echo $PROJ_ROOT/$AUTO_COMPILE
echo

CreateProjectConfig
CreateAutoCompile

if [ "$B_REPO_INIT" == "true" ]; then
    repo init -u rocket:platform/manifest -b $BRANCH
    repo sync
fi

if [ "$B_COMPILE" == "true" ]; then
    $PROJ_ROOT/$AUTO_COMPILE -d
fi
