#!/bin/bash

feh --bg-fill ~/.wallpapers/others/green_forest.jpeg &
killall sync-obsidian.sh
~/dotfiles/scripts/linux/sync-obsidian.sh >/tmp/sync-obsidian-log &
# killall skippy-xd
# skippy-xd --start-daemon &
# nm-applet &

ibus-daemon -drx &
killall dwmblocks
dwmblocks &
killall dunst
dunst &
[[ $(pgrep 1password) ]] || 1password --silent &
[[ $(pgrep aw-qt) ]] || aw-qt &
# cd ~/competitive_programming/cpcli/cc && npm start -- config=$HOME/competitive_programming/project_config.json &

# Start picom
killall picom
sleep 0.1
picom &

# Start conky
killall conky
conky

# Keyboard
xset r rate 200 50
killall xremap
xremap ~/.config/xremap/config.yml >/tmp/dwm-xremap &
sleep 5
xset r rate 200 50

# Wacom
xsetwacom set 9 MapToOutput 2560x2160+1280+0
