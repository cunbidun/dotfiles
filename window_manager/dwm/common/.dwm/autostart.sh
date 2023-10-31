#!/bin/bash

feh --bg-fill ~/.wallpapers/others/Astronaut.png &
[[ $(pgrep redshift) ]] || redshift -l 41.85003:-87.65005 &

ibus-daemon -drx &
killall dwmblocks
dwmblocks &
killall dunst
dunst &
[[ $(pgrep 1password) ]] || 1password --silent &
[[ $(pgrep aw-qt) ]] || aw-qt &
[[ $(pgrep picom) ]] || picom &
[[ $(pgrep conky) ]] || conky &

# Keyboard
xset r rate 200 50
[[ $(pgrep xremap) ]] || {
	xremap ~/.config/xremap/config.yml >/tmp/dwm-xremap &
	sleep 5
}
xset r rate 200 50

# Wacom
xsetwacom set 9 MapToOutput 2560x2160+1280+0
