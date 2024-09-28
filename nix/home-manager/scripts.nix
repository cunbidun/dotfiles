{pkgs, ...}: {
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
    notify-send --hint=string:x-dunst-stack-tag:volume "volume: $vol" -t 1000 -a "System"
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
}
