#!/usr/bin/env bash

hyprpaper &
dunst &
ibus-daemon -drx &
xremap ~/.config/xremap/config.yml &
~/dotfiles/window_manager/hyprland/scripts/launch-waybar &
gammastep -l 41.85003:-87.65005 &
pypr &
