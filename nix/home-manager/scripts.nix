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
    pamixer -t
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
              run(["hyprctl", "dispatch", "movetoworkspacesilent", f"name:{target}"])
              return 0

          if cmd == "main":
              target = f"{proj}"
              run(["hyprctl", "dispatch", "workspace", f"name:{target}"])
              return 0

          if cmd == "main-move":
              target = f"{proj}"
              run(["hyprctl", "dispatch", "movetoworkspacesilent", f"name:{target}"])
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
