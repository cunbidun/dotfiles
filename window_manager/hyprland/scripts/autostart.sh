#!/usr/bin/env bash

echo "PATH is set to $PATH"

[[ $(pgrep dunst) ]] || dunst &

[[ $(pgrep 1password) ]] || 1password --silent
