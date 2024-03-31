#!/usr/bin/env bash

echo "PATH is set to $PATH"

[[ $(pgrep dunst) ]] || dunst &
# ibus-daemon -drx &
fcitx5 -dr &

[[ $(pgrep 1password) ]] || 1password --silent &
[[ $(pgrep swayidle) ]] || swayidle -w timeout 300 'swaylock -f' timeout 1200 'systemctl suspend -i'
