#!/usr/bin/env bash

killall hyprpaper
hyprpaper &
[[ $(pgrep gammastep) ]] || gammastep -l 41.85003:-87.65005 &

[[ $(pgrep dunst) ]] || dunst &
ibus-daemon -drx &

[[ $(pgrep aw-qt) ]] || aw-qt &
[[ $(pgrep xremap) ]] || xremap ~/.config/xremap/config.yml &
[[ $(pgrep 1password) ]] || 1password --silent &
