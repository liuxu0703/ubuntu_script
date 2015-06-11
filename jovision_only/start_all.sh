#!/bin/bash

#       AUTHOR : liuxu

WORK_DIRS=(\
    "$HOME/workspace/IvBabyProject"\
    "$HOME/workspace/IvBabyProject/ivbaby/src/main"\
    "$HOME/workspace/IvBabyProject/ivteacher/src/main"\
    "$HOME/workspace/IvBabyProject/ivbabylib/src/main"\
    )

# start terminal tab by work dir
for ddd in ${WORK_DIRS[*]}; do
    #gnome-terminal --tab --working-directory="$ddd"
    
    WID=$(xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)"| awk '{print $5}')
    xdotool windowfocus $WID
    xdotool key ctrl+shift+t
    xdotool type --delay 1 --clearmodifiers "cd $ddd"; xdotool key Return;
    #xdotool key ctrl+super+up
done


start_vbox_xp.sh
chromium-browser &
gedit &

sleep 3s
start_android_studio.sh

fi

sleep 3s


