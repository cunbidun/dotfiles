{pkgs, ...}: {
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

    choice=$(printf "%s\n" "''${modes[@]}" | vicinae dmenu --placeholder "Select a mode" --section-title "Modes ({count})")

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

    # Always use Vicinae's dmenu for confirmations
    if [ "$(printf \"No\nYes\" | vicinae dmenu --placeholder \"$1\" --section-title \"Confirm\")" = "Yes" ]; then
      bash -c "$2"
    fi
  '';

  brightness-control = pkgs.writeShellScriptBin "brightness-control" ''
    get_bus_num() {
        if [ -f /tmp/dwm-i2c-bus ]; then
            bus_num=$(cat /tmp/dwm-i2c-bus)
            if [ -n "$bus_num" ]; then
                echo "$bus_num"
                return
            fi
        fi

        bus_num=$(ddcutil detect --sleep-multiplier 0.01 2>/dev/null | grep "/dev/i2c-" | awk -F- '{print $NF}' | head -n1)
        echo "$bus_num" > /tmp/dwm-i2c-bus
        echo "$bus_num"
    }

    # Function to display usage instructions
    usage() {
        echo "Usage: $0 [increase|decrease|get] [optional amount] [json]"
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
            bus_num=$(get_bus_num)
            percent=$(
                ddcutil getvcp 10 --sleep-multiplier .01 --bus "$bus_num" 2>/dev/null |
                    awk '/current value/ {gsub(",", "", $9); print $9}'
            )
        fi
        # Normalize to an integer; fallback to 0 if parsing fails
        if ! printf '%s' "$percent" | grep -Eq '^[0-9]+$'; then
            percent=0
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
            bus_num=$(get_bus_num)
            ddcutil setvcp 10 "$new_b" --bus "$bus_num" --sleep-multiplier 0.01
            pkill -SIGRTMIN+16 waybar
            # notify hyprpanel custom module listener
            signal_file=/tmp/hyprpanel/brightness.signal
            mkdir -p "$(dirname "$signal_file")"
            echo "$new_b" >"$signal_file"
            touch "$signal_file"
        else
            echo "Brightness is already at the desired level ($current_b), no change needed."
        fi
    }

    # Main script logic
    case "$1" in
        get)
            value="$(get_brightness)"
            if [ "''${2:-}" = "json" ]; then
                printf '{"percentage":%s}\n' "$value"
            else
                echo "$value"
            fi
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

  wsctl =
    pkgs.writers.writePython3Bin "wsctl" {
      flakeIgnore = ["E501"];
    } ''
      import json
      import re
      import subprocess
      import sys

      ACTIVE_RE = re.compile(r"^(?P<proj>\d+)(?:\[(?P<sub>[^\]]+)\])?$")


      def run(cmd, inp=None):
          p = subprocess.run(
              cmd,
              input=(inp.encode() if inp else None),
              stdout=subprocess.PIPE,
              stderr=subprocess.PIPE,
          )
          if p.returncode != 0:
              raise RuntimeError(
                  p.stderr.decode(errors="ignore").strip() or "command failed"
              )
          return p.stdout.decode(errors="ignore")


      def hyprj(args):
          return json.loads(run(["hyprctl"] + args))


      def current_project():
          name = str(hyprj(["activeworkspace", "-j"]).get("name", "")).strip()
          m = ACTIVE_RE.match(name)
          if not m:
              raise RuntimeError(f"bad ws name: {name!r}")
          return m.group("proj")


      def main():
          if len(sys.argv) < 2:
              print(
                  "usage: wsctl goto N | move N | main | main-move",
                  file=sys.stderr,
              )
              return 1

          cmd = sys.argv[1]
          proj = current_project()

          if cmd == "goto":
              sub = sys.argv[2]
              target = f"{proj}[{sub}]"
              run(["hyprctl", "dispatch", "workspace", f"name:{target}"])
              return 0

          if cmd == "move":
              sub = sys.argv[2]
              target = f"{proj}[{sub}]"
              run(["hyprctl", "dispatch", "movetoworkspace", f"name:{target}"])
              return 0

          if cmd == "main":
              target = f"{proj}[main]"
              run(["hyprctl", "dispatch", "workspace", f"name:{target}"])
              return 0

          if cmd == "main-move":
              target = f"{proj}[main]"
              run(["hyprctl", "dispatch", "movetoworkspace", f"name:{target}"])
              return 0

          raise RuntimeError(f"unknown command: {cmd}")


      if __name__ == "__main__":
          try:
              raise SystemExit(main())
          except Exception as e:
              print(f"[wsctl] {e}", file=sys.stderr)
              raise SystemExit(1)
    '';
}
