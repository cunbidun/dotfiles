#!/usr/bin/env bash

echo "PATH is set to $PATH"

fcitx5 -dr &

[[ $(pgrep 1password) ]] || 1password --silent
