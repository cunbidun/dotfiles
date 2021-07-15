#!/bin/bash

xset r rate 200 30 &
feh --bg-fill --randomize ~/.wallpapers/favorite/* &
killall skippy-xd; skippy-xd --start-daemon &
# nm-applet &
ibus-daemon -drx &
killall dwmblocks; dwmblocks &
killall dunst; dunst &
cd ~/competitive_programming/cc/ && npm start &
# picom --experimental-backends &
