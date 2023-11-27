#!/usr/bin/env bash

# Define an array of game processes
games=("dota2" "cs2" "steam")

while true; do
	picom_pid=$(pgrep picom)

	# Check if any game process is running
	game_running=false
	for game in "${games[@]}"; do
		if pgrep "$game" >/dev/null; then
			game_running=true
			echo "$game is running"
			break
		fi
	done

	if "$game_running"; then
		# Check if picom is running and kill it
		if [ -n "$picom_pid" ]; then
			echo "Killing picom (PID: $picom_pid)"
			kill "$picom_pid"
			# Notify the user
			notify-send -t 1600 'Gaming Mode' 'Picom Disabled' --icon=video-display
		else
			echo "picom is not running"
		fi
	else
		# Check if picom is not running and enable it
		if [ -z "$picom_pid" ]; then
			echo "Enabling picom"
			picom --daemon &
			# Notify the user
			notify-send -t 1600 'Gaming Mode' 'Picom Enabled' --icon=video-display
		else
			echo "picom is already running"
		fi
	fi

	# Sleep for a short interval before checking again
	sleep 1
done
