#!/bin/bash

xset r rate 200 50 &
feh --bg-fill ~/.wallpapers/others/ign-colorful.png &
# killall skippy-xd
# skippy-xd --start-daemon &
# nm-applet &

ibus-daemon -drx &
killall dwmblocks
dwmblocks &
killall dunst
dunst &
[[ $(pgrep 1password) ]] || 1password --silent &
# cd ~/competitive_programming/cpcli/cc && npm start -- config=$HOME/competitive_programming/project_config.json &
killall picom; sleep 0.1; picom &
