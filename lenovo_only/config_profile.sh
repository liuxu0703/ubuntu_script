#!/bin/bash
#v1.0   show, edit, new profile
#v2.0   use each project dir to store project profiles, and do not consider issue profiles any more
#       show, edit, new project profile

#these variables are written into .bashrc, thus are environment variables now
#CODE_DIR=$HOME/workspace/code
#DEFAULT_PROJECT_FILE=CODE_DIR/.default_project
#DEFAULT_CONFIG_TAG="Config"                 #suffix of profile
AUTO_COMPILE=autocompile.sh
DEBUG="false"

declare -a project_array            #projects with profiles
declare -a project_n_array          #projects without a profile in it

DEBUG() {
    if [ "$DEBUG" == "true" ]; then
        $@
    fi
}

function ShellHelp() {
    echo
    echo "shell help"
    echo
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

#get project arrays from CODE_DIR, sort project_array by atime
#path of projects with a profile in their dir are stored in profile_array
#path of projects without a profile are stored in project_n_array
function GetProfileArray() {
    local pj_arr=($(find $CODE_DIR -maxdepth 1 -type d))    #list of all dir in CODE_DIR
    #echo "pj_arr : ${pj_arr[*]}"

    local i=0
    local j=0
    local k=0
    while [ $i -lt ${#pj_arr[*]} ]; do      #get project array
        if [ "${pj_arr[$i]}" == "$CODE_DIR" ]; then      #ignore $CODE_DIR
            let i++
            continue
        fi

        local pj_name=$(basename ${pj_arr[$i]})
        if [ -f "${pj_arr[$i]}/$pj_name.$DEFAULT_CONFIG_TAG" ]; then
            project_array[$j]=$pj_name
            let j++
        else
            project_n_array[$k]=$pj_name
            let k++
        fi
        let i++
    done

    i=0 ; k=0 ; j=0
    local tmp; local compare_tmp; local pj_time
    while [ $i -lt ${#project_array[*]} ]; do     #sort project_array
        j=$i
        compare_tmp=0
	    while [ $j -lt ${#project_array[*]} ]; do
	        pj_time=$(stat -c %X $CODE_DIR/${project_array[$j]}/${project_array[$j]}.$DEFAULT_CONFIG_TAG)
	        #echo "pj_time = $pj_time , $j , for ${project_array[$j]}"
		    if [ $pj_time -ge $compare_tmp ]; then
			    compare_tmp=$pj_time
			    k=$j
		    fi

		    let j++
	    done
        tmp=${project_array[$i]}
        project_array[$i]=${project_array[$k]}
        project_array[$k]=$tmp
	    let i++
    done
}

#$1 should be a project array (either project_array or project_n_array)
function GenerateProjectMenu() {
    local n; local index
    declare -a pj_arr
    eval "n=\${#$1[*]}"
    local i=0
    while [ $i -lt $n ]; do     #store $1 into $pj_arr
        eval "pj_arr[$i]=\${$1[$i]}"
        let i++
    done

    local is_length_single_digit=$(IsInterger $n 0 9)
    i=0
    while [ $i -lt $n ]; do
        index=$(expr $i + 1)
        if [ "$is_length_single_digit" == "true" ]; then
            echo "  [$index]. ${pj_arr[$i]}"
        else
            local is_index_single_digit=$(IsInterger $index 0 9)
            if [ "$is_index_single_digit" == "true" ]; then
                echo "  [ $index]. ${pj_arr[$i]}"
            else
                echo "  [$index]. ${pj_arr[$i]}"
            fi
        fi
        let i++
    done

    unset pj_arr
}

function CreateNewProfile() {
    local pj_name

    echo
    echo "==================================="
    echo
    echo "Create New Project Profile Menu: "
    GenerateProjectMenu project_n_array
    read -p "choose a project to add a *.Config file to its dir: "

    if [ $(IsInterger $REPLY 1 ${#project_n_array[*]}) == "true" ]; then     #make sure input is interger
        n=$(expr $REPLY - 1)
    else
        echo "invalidate selection"
        exit
    fi

    pj_name=${project_n_array[$n]}

    echo "PROJECT_NAME=$pj_name"                        >> $CODE_DIR/$pj_name/$pj_name.$DEFAULT_CONFIG_TAG
    echo "PROJECT_DIR=$CODE_DIR/$pj_name"               >> $CODE_DIR/$pj_name/$pj_name.$DEFAULT_CONFIG_TAG
    echo "PROJECT_VERSION_DIR=$HOME/project_versions/"  >> $CODE_DIR/$pj_name/$pj_name.$DEFAULT_CONFIG_TAG
    echo "DEFAULT_LUNCH_NUM="                           >> $CODE_DIR/$pj_name/$pj_name.$DEFAULT_CONFIG_TAG
    echo "DEFAULT_COMBO="                               >> $CODE_DIR/$pj_name/$pj_name.$DEFAULT_CONFIG_TAG
    echo "IS_ACTIVE_PROJECT=true"                       >> $CODE_DIR/$pj_name/$pj_name.$DEFAULT_CONFIG_TAG

    gedit $CODE_DIR/$pj_name/$pj_name.$DEFAULT_CONFIG_TAG & > /dev/null
    echo
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

#create AutoCompile.sh in target project dir
#$1 should be a project name
function CreateAutoCompile() {
    local pj_name=$1
    local pj_path=$CODE_DIR/$pj_name
    local auto_compile=$pj_path/$AUTO_COMPILE

cat >> $auto_compile <<"EOF"
#!/bin/bash
#options     :  -s: repo sync
#               -r: rm -rf /out
#               -d: du -sh /out
#               -p: poweroff

EOF

WriteToFile $auto_compile "PROJECT_NAME=$pj_name"

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
    echo
    echo "NAME:"
    echo "$shell_name: "
    echo
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

#$1 should be a project name
function ProjectMenu() {
    local n
    echo
    echo "==================================="
    echo
    echo "Project ** $1 ** Menu: "
    echo "  [1]. Set As Default Project"
    echo "  [2]. Create or Edit AutoCompile.sh"
    echo "  [3]. Edit Project Profile"
    echo "  [4]. Show Project Profile"
    echo "  [5]. Delete Project Profile"
    echo "  [X]. Do Nothing and Exit"
    read -p "choose an option: "

    case $REPLY in
        x | X)
            #echo "do nothing and exit"
            echo
            exit
            ;;
        1)
            if [ ! -f $DEFAULT_PROJECT_FILE ]; then
                echo "DEFAULT_PROJECT=apollo_td"                        >> $DEFAULT_PROJECT_FILE
                echo "DEFAULT_LUNCH_NUM=3"                              >> $DEFAULT_PROJECT_FILE
                echo "DEFAULT_COMBO="                                   >> $DEFAULT_PROJECT_FILE
                echo "DEFAULT_VERSION_DIR=$HOME/project_versions/"      >> $DEFAULT_PROJECT_FILE
            fi

            local pj_name=`sed -n '/^PROJECT_NAME/'p $CODE_DIR/$1/$1.$DEFAULT_CONFIG_TAG | awk -F "=" '{print $2}'`
            sed -i "/^DEFAULT_PROJECT/c DEFAULT_PROJECT=$1" $DEFAULT_PROJECT_FILE
            local lunch_num=`sed -n '/^DEFAULT_LUNCH_NUM/'p $CODE_DIR/$1/$1.$DEFAULT_CONFIG_TAG | awk -F "=" '{print $2}'`
            sed -i "/^DEFAULT_LUNCH_NUM/c DEFAULT_LUNCH_NUM=$lunch_num" $DEFAULT_PROJECT_FILE
            local pj_ver_dir=`sed -n '/^PROJECT_VERSION_DIR/'p $CODE_DIR/$1/$1.$DEFAULT_CONFIG_TAG | awk -F "=" '{print $2}'`
            sed -i "/^DEFAULT_VERSION_DIR/c DEFAULT_VERSION_DIR=$pj_ver_dir" $DEFAULT_PROJECT_FILE

            touch $CODE_DIR/$1/$1.$DEFAULT_CONFIG_TAG       #if we set a project to default, mark its profile as the newest

            echo
            echo "==================================="
            echo
            echo "settings of default project:"
            echo
            cat $DEFAULT_PROJECT_FILE
            echo
            ;;
        2)
            if [ -f $CODE_DIR/$1/$AUTO_COMPILE ]; then
                gedit $CODE_DIR/$1/$AUTO_COMPILE & > /dev/null
                echo
            else
                CreateAutoCompile $1
                gedit $CODE_DIR/$1/$AUTO_COMPILE & > /dev/null
                echo
            fi
            ;;
        3)
            gedit $CODE_DIR/$1/$1.$DEFAULT_CONFIG_TAG & > /dev/null
            echo
            ;;
        4)
            echo
            echo "==================================="
            echo
            cat $CODE_DIR/$1/$1.$DEFAULT_CONFIG_TAG
            echo
            ;;
        5)
            rm -f $CODE_DIR/$1/$1.$DEFAULT_CONFIG_TAG
            echo
            echo "$CODE_DIR/$1/$1.$DEFAULT_CONFIG_TAG is removed."
            echo
            ;;
        *)
            echo
            echo "Invalidate Selection !!!"
            echo
            ;;
    esac
}

#[n]. new
#[1]. project1
#[2]. project2
#......
#return selection (use 'echo')
function MainMenu() {
    local n; local pj_name

    echo
    if [ -f $DEFAULT_PROJECT_FILE ]; then
        local df_pj=$(sed -n '/^DEFAULT_PROJECT/'p $DEFAULT_PROJECT_FILE | awk -F "=" '{print $2}')
        echo "Current Default Project : $df_pj"
    else
        echo "No Default Project For Now!"
    fi

    echo "==================================="
    echo
    echo "Main Menu: "
    GenerateProjectMenu project_array
    echo "  [C]. Create New Profile"
    echo "  [S]. Show Default Settings"
    echo "  [X]. Do Nothing and Exit"
    read -p "choose an option or a profile: "

    if [[ ( "$REPLY" == "c" ) || ( "$REPLY" == "C" ) ]]; then
        CreateNewProfile
        exit
    elif [[ ( "$REPLY" == "s" ) || ( "$REPLY" == "S" ) ]]; then
        echo
        echo "==================================="
        echo
        cat $DEFAULT_PROJECT_FILE
        echo
        exit
    elif [[ ( "$REPLY" == "x" ) || ( "$REPLY" == "X" ) ]]; then
        #echo "do nothing and exit."
        echo
        exit
    elif [ $(IsInterger $REPLY 1 ${#project_array[*]}) == "true" ]; then
        n=$(expr $REPLY - 1)
    else
        echo "Invalidate Selection !!!"
        echo
        exit
    fi

    pj_name=${project_array[$n]}
    ProjectMenu $pj_name
}

GetProfileArray
#echo "project_array : ${project_array[*]}"
#echo "project_n_array : ${project_n_array[*]}"
MainMenu

