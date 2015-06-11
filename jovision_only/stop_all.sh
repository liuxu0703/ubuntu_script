#!/bin/bash

#       AUTHOR : liuxu

VBoxManage controlvm my_xp acpipowerbutton
sleep 2m  # wait for vbox poweroff
sudo poweroff

