{pkgs, ...}: {
  weather = pkgs.writeShellScriptBin "weather" ''
    weatherreport=$HOME/.cache/weatherreport

    showweather() {
    	desc="$(awk 'NR==3' $weatherreport | sed 's/\x1b\[[0-9;]*m//g' | tr -cd '[:alnum:] ' | xargs)"
    	temp="$(awk 'NR==4' $weatherreport | awk '{ print $(NF-1) }' | sed 's/\x1b\[[0-9;]*m//g')"
    	echo "$desc $temp°C"
    }

    # The test if our forcecast is updated to the day. If it isn't download a new
    # weather report from wttr.in with the above function.
    [ "$(stat -c %y "$weatherreport" 2>/dev/null | cut -d' ' -f1)" = "$(date '+%Y-%m-%d')" ] ||
    	sc_weather_sync

    # check if the report is within 30 minutes
    [ $((($(date +%s) - $(stat -L --format %Y .cache/weatherreport)) > (30 * 60))) ] ||
    	sc_weather_sync

    showweather
  '';
  weather-sync =
    pkgs.writers.writePython3Bin "weather-sync" {
      libraries = [
        pkgs.python312Packages.requests
      ];
      flakeIgnore = [
        "E501" # Line too long
      ];
    } ''
      import os
      import subprocess
      from pathlib import Path
      import requests

      os.system('notify-send -t 3000 "Sync weather report" "Updating report..." -a "weather_sync"')

      # Define paths
      cache_dir = Path.home() / ".cache"
      weather_report_path = cache_dir / "weatherreport"
      weather_report_backup_path = cache_dir / "weatherreport.bak"

      # Backup the existing weather report (if it exists)
      if weather_report_path.exists():
          print("Backingup the old weather report")
          weather_report_path.rename(weather_report_backup_path)

      # Download the new weather report
      try:
          print("Querying https://wttr.in/?m...")
          response = requests.get("https://wttr.in/?m")
          response.raise_for_status()
          print(f"saving response to {weather_report_path}")
          weather_report_path.write_bytes(response.content)
      except requests.exceptions.RequestException:
          os.system('notify-send "Something went wrong. Check your internet connection and try again."')
          if weather_report_backup_path.exists():
              # Restore the backup if the download failed
              weather_report_backup_path.rename(weather_report_path)

      os.system('notify-send -t 3000 "Sync weather report" "Sync complete!" -a "weather_sync"')
      try:
          subprocess.run(["pkill", "-SIGRTMIN+20", "waybar"], check=True)
      except subprocess.CalledProcessError:
          pass
    '';

  hyprland-autostart = pkgs.writers.writeBashBin "hyprland-autostart" ''
    echo "PATH is set to $PATH"
    [[ $(pgrep 1password) ]] || 1password --silent
  '';
  increase-volume = pkgs.writeShellScriptBin "increase_volume" ''
    # Get the list of sinks and filter only the running ones
    running_sinks=$(pamixer --list-sinks | awk -F '"' '/Running/ {print $2}')

    # Loop through each running sink and increase the volume by 5%
    for sink in $running_sinks; do
      pamixer --sink $sink -i 5 --allow-boost
    done
  '';
  decrease-volume = pkgs.writeShellScriptBin "increase_volume" ''
    # Get the list of sinks and filter only the running ones
    running_sinks=$(pamixer --list-sinks | awk -F '"' '/Running/ {print $2}')

    # Loop through each running sink and increase the volume by 5%
    for sink in $running_sinks; do
      pamixer --sink $sink -d 5 --allow-boost
    done
  '';
  toggle-volume = pkgs.writeShellScriptBin "toggle_volume" ''
    pamixer -t;
    if [ "$(pamixer --get-mute)" = true ]; then
    	icon="[Muted] "
    fi
    vol="$icon$(pamixer --get-volume)"
    notify-send --hint=string:x-stack-tag:volume "volume: $vol" -t 1000 -a "System"
  '';

  hyprland-mode = pkgs.writeShellScriptBin "hyprland-mode" ''
    modes=("Competitive Programming (cp)" "Reset (normal)" "Gaming (gaming)")

    # Convert the array to a newline-separated string
    choice=$(printf "%s\n" "''${modes[@]}" | $PICKER --prompt-text "Select a mode:")

    if [ -z "$choice" ]; then
      echo "No mode was selected."
      notify-send -t 3000 "No Mode Selected" "No mode was selected."
      exit 1
    fi

    echo "Mode selected: $choice"
    notify-send -t 3000 "Mode Selected" "$choice"

    # Extract the short form of the mode
    short_mode=$(echo "$choice" | cut -d '(' -f2 | cut -d ')' -f1)

    echo "$short_mode" >"''${XDG_RUNTIME_DIR}/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/current_mode"
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
  '';
  prompt = pkgs.writeShellScriptBin "prompt" ''
    #!/usr/bin/env bash

    if [ $PICKER == "dmenu" ]; then
    	extra_flags=("-i" "-p" "$1")
    fi
    if [ $PICKER == "wofi" ]; then
    	extra_flags=("-p" "$1" "-dni" "-L" "4" "-W" "25%" "-k" "/dev/null")
    fi

    if [ $PICKER == "tofi" ]; then
    	extra_flags=(--prompt-text "$1")
    fi

    # Usage:
    # Prompt and execute command if "Yes" is selected
    if [ "$(echo -e "No\nYes" | "$PICKER" "''${extra_flags[@]}")" = "Yes" ]; then
      bash -c "$2"
    fi
  '';

  brightness-control = pkgs.writeShellScriptBin "brightness-control" ''
    # Function to display usage instructions
    usage() {
        echo "Usage: $0 [increase|decrease|get] [optional amount]"
        echo "Examples:"
        echo "  $0 get                # Get current brightness"
        echo "  $0 increase 10        # Increase brightness by 10"
        echo "  $0 decrease 5         # Decrease brightness by 5"
        exit 1
    }

    # Function to get current brightness
    get_brightness() {
        if [[ $(uname -r) == *asahi* ]]; then
            BASE_PATH="/sys/class/backlight/apple-panel-bl/"
            current_brightness=$(cat "$BASE_PATH/brightness")
            mx_brightness=$(cat "$BASE_PATH/max_brightness")
            percent=$((current_brightness * 100 / mx_brightness))
        else
            if [ -f /tmp/dwm-i2c-bus ]; then
                bus_num=$(cat /tmp/dwm-i2c-bus)
            else
                # If not, query ddcutil to get the bus number and save it to the file
                bus_num=$(ddcutil detect --sleep-multiplier 0.01 | grep "/dev/i2c-" | awk -F- '{print $NF}')
                echo "$bus_num" > /tmp/dwm-i2c-bus
            fi
            percent=$(ddcutil get 10 --sleep-multiplier .01 | awk '{ print $9 }' | cut -d ',' -f 1)
        fi
        echo "$percent"
    }

    # Function to change brightness
    change_brightness() {
        # Check if at least one argument is provided
        if [ $# -lt 1 ]; then
            usage
        fi

        # Get the current brightness value
        current_b=$(get_brightness)
        echo "Current brightness: $current_b"

        # Calculate the new brightness value based on the argument
        if [ "$1" == "increase" ]; then
            # Check if an amount argument is provided
            if [ $# -lt 2 ]; then
                usage
            fi
            amount="$2"
            new_b=$((current_b + amount))
        elif [ "$1" == "decrease" ]; then
            # Check if an amount argument is provided
            if [ $# -lt 2 ]; then
                usage
            fi
            amount="$2"
            new_b=$((current_b - amount))
        else
            usage
        fi

        # Check if the new brightness value is within bounds
        if [ "$new_b" -lt 0 ]; then
            new_b=0
        elif [ "$new_b" -gt 100 ]; then
            new_b=100
        fi

        # Check if the brightness has changed
        if [ "$new_b" -ne "$current_b" ]; then
            echo "Setting brightness to $new_b"
            if [ -f /tmp/dwm-i2c-bus ]; then
                bus_num=$(cat /tmp/dwm-i2c-bus)
                if [ -z "$bus_num" ]; then
                    echo "Bus number is empty in /tmp/dwm-i2c-bus. Querying ddcutil..."
                    # Query ddcutil to get the bus number and save it to the file
                    bus_num=$(ddcutil detect --sleep-multiplier 0.01 | grep "/dev/i2c-" | awk -F- '{print $NF}')
                    echo "$bus_num" >/tmp/dwm-i2c-bus
                fi
            else
                # If not, query ddcutil to get the bus number and save it to the file
                bus_num=$(ddcutil detect --sleep-multiplier 0.01 | grep "/dev/i2c-" | awk -F- '{print $NF}')
                echo "$bus_num" >/tmp/dwm-i2c-bus
            fi
            ddcutil setvcp 10 "$new_b" --bus "$bus_num" --sleep-multiplier 0.01
            pkill -SIGRTMIN+16 waybar
        else
            echo "Brightness is already at the desired level ($current_b), no change needed."
        fi
    }

    # Main script logic
    case "$1" in
        get)
            get_brightness
            ;;
        increase|decrease)
            change_brightness "$@"
            ;;
        *)
            usage
            ;;
    esac
  '';

  minimize-window = pkgs.writeShellScriptBin "minimize-window" ''
    current_workspace=$(hyprctl activeworkspace | grep "workspace ID" | head -n 1 | awk '{print $3}')

    # Transfers the window to/from a designated workspace based on the visibility status of that workspace.
    # Why can't we use 'hyprctl dispatch movetoworkspacesilent "special:minimized_$current_workspace"' instead?
    # Because we need to be able to move the window back from the special workspace

    pypr toggle_special "minimized_$current_workspace"'';

  toggle-minimize-window =
    pkgs.writeShellScriptBin "toggle-minimize-window" ''
      hyprctl dispatch togglespecialworkspace "minimized_$(hyprctl activeworkspace -j | jq '.id')"'';

  get-theme-polarity = pkgs.writeShellScriptBin "get-theme-polarity" ''
    current_theme=$(darkman get)
    if [[ "$current_theme" == "dark" ]]; then
      echo "Polarity " # Moon icon for dark theme
    else
      echo "Polarity " # Sun icon for light theme
    fi
  '';

  toggle-theme-debounced = pkgs.writeShellScriptBin "toggle-theme-debounced" ''
    LOCK_FILE="/tmp/waybar_theme_toggle.lock"

    if [ -f "$LOCK_FILE" ]; then
      exit 0
    fi

    touch "$LOCK_FILE"
    darkman toggle
    rm "$LOCK_FILE"
  '';
}
