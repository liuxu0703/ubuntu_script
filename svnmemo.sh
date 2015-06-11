#!/bin/bash

cat <<EOF
--------------------------------------------------------------------------------

提交
svn commit -m “commit msg“ <filename>

添加文件
svn add <filename>

更新
svn update
svn update <filename>

比较
svn diff <filename>

状态
svn st
svn status
    A  Added
    D  Deleted
    U  Updated
    C  Conflict
    G  Merged
    E  Existed

检出
svn checkout https://192.168.8.100/svn/ibaby/trunk/project/userClient/android/IvBabyProject --username liux --password mingming

处理冲突
svn resolve --accept working <filename>

帮助
svn help
svn help commit

恢复本地修改
svn revert [--recursive] <filename>

--------------------------------------------------------------------------------
EOF
