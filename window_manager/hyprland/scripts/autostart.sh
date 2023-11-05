#!/usr/bin/env bash

killall hyprpaper
hyprpaper &

[[ $(pgrep dunst) ]] || dunst &
ibus-daemon -drx &

[[ $(pgrep aw-qt) ]] || aw-qt &
[[ $(pgrep xremap) ]] || xremap ~/.config/xremap/config.yml &

killall .waybar-wrapped
killall waybarwrapped
~/dotfiles/window_manager/hyprland/scripts/waybarwrapped &

[[ $(pgrep gammastep) ]] || gammastep -l 41.85003:-87.65005 &
[[ $(pgrep pypr) ]] || pypr &
[[ $(pgrep 1password) ]] || 1password --silent &
