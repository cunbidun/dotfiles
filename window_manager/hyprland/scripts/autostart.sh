#!/usr/bin/env bash

echo "PATH is set to $PATH"

[[ $(pgrep dunst) ]] || dunst &
fcitx5 -dr &

[[ $(pgrep 1password) ]] || 1password --silent
