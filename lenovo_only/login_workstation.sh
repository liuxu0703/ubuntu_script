#!/bin/bash

SERVER_IP=10.110.7.133
USER_NAME=liuxu7
PASSWORD=mingming
RESOLUTION="workarea"
FULL_SCREEN="false"

#parameter g means graphic matrix,like -g1280x720, use workarea means fix current area
#parameter f means full screen mode, because we use -gworkarea so we also use -f,this make better eperience
#use & charactor means run in background

if [ "$1" == "-f" ]; then
    FULL_SCREEN="true"
elif [ "$1" == "-g" ]; then
    [ ! "$2" == "" ] && RESOLUTION=$2
fi

if [ "$FULL_SCREEN" == "true" ]; then
    rdesktop $SERVER_IP -gworkarea -u$USER_NAME -p$PASSWORD -f &
else
    rdesktop $SERVER_IP -g$RESOLUTION -u$USER_NAME -p$PASSWORD &
fi
