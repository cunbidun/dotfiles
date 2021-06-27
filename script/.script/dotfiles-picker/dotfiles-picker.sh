#!/bin/bash


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
dotfiles="$DIR/dotfiles.txt"

path=$(cat "$dotfiles" | rofi -dmenu -i -p "select dotfiles: ")

if [ -n "$path" ]; then
	if [[ -d "$path" ]]; then
    cd "$path"
		$EDITOR  
	else
		$EDITOR "$path"
	fi
fi
