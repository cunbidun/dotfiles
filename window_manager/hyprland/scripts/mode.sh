#!/usr/bin/env bash

#!/bin/bash

modes=("Competitive Programming (cp)" "Reset (normal)" "Gaming (gaming)")

# Convert the array to a newline-separated string
choice=$(printf "%s\n" "${modes[@]}" | $PICKER --prompt-text "Select a mode:")

if [ -z "$choice" ]; then
	echo "No mode was selected."
	notify-send -t 3000 "No Mode Selected" "No mode was selected."
	exit 1
fi

echo "Mode selected: $choice"
notify-send -t 3000 "Mode Selected" "$choice"

# Extract the short form of the mode
short_mode=$(echo "$choice" | cut -d '(' -f2 | cut -d ')' -f1)

echo "$short_mode" >"${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/current_mode"
pkill -SIGRTMIN+17 waybar

if [ "$short_mode" == "normal" ]; then
	systemctl --user start hypridle.service
	notify-send -t 3000 "Normal" "hypridle started"
	hyprctl reload
fi

if [ "$short_mode" == "cp" ]; then
	systemctl --user stop hypridle.service
	notify-send -t 3000 "Competitive Programming Mode" "hypridle stopped"
fi
