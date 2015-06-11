#!/bin/bash

#       AUTHOR : liuxu
#       THIS SHELL IS ENVIRONMENT INDEPENDENT

if [ "$1" == "-s" ]; then
    pid=$(ps | sed -n '/synergys/p' | awk '{print $1}')
    kill $pid
else
    synergys -f --config synergy_private.conf & > /dev/null
    synergyc 10.110.53.54
fi

