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
cd ~/competitive_programming/cc && npm start &
# picom --experimental-backends &