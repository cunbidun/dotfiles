#!/bin/bash

xset r rate 200 30 &
feh --bg-fill --randomize ~/.wallpapers/nord/* &
nm-applet &
ibus-daemon -drx &
killall slstatus; slstatus &

# picom --experimental-backends &
