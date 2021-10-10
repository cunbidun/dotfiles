#!/bin/bash

xset r rate 200 40 &
feh --bg-fill --randomize ~/.wallpapers/nord/* &
killall skippy-xd; skippy-xd --start-daemon &
# nm-applet &

ibus-daemon -drx &
killall dwmblocks; dwmblocks &
killall dunst; dunst &
cd ~/competitive_programming/cc && npm start &
# picom --experimental-backends &
