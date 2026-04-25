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

  screenshot-copy-upload = pkgs.writeShellApplication {
    name = "screenshot-copy-upload";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.grim
      pkgs.openssh
      pkgs.slurp
      pkgs.wl-clipboard
    ];
    text = ''
      set -euo pipefail

      remote_target="home-server"
      remote_dir="/home/cunbidun/Pictures/Screenshots/llm-shots"
      local_dir="$HOME/Pictures/Screenshots"
      mkdir -p "$local_dir"

      file_name="llm-shot_$(date +%Y-%m-%d_%H-%M-%S).png"
      local_path="$local_dir/$file_name"
      remote_path="$remote_dir/$file_name"
      region="$(slurp)"

      grim -g "$region" - | tee "$local_path" | wl-copy -t image/png
      ssh "$remote_target" mkdir -p -- "$remote_dir"
      scp -q "$local_path" "$remote_target:$remote_path"
      printf "%s" "$remote_target:$remote_path" | wl-copy
    '';
  };

  wsctl =
    pkgs.writers.writePython3Bin "wsctl" {
      flakeIgnore = ["E501"];
    } ''
      import json
      import os
      from pathlib import Path
      import re
      import subprocess
      import sys

      ACTIVE_RE = re.compile(r"^(?P<proj>\d+)(?:\[(?P<sub>[^\]]+)\])?$")
      STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "wsctl"
      STATE_FILE = STATE_DIR / "last-sub.json"


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


      def parse_workspace_name(name):
          workspace_name = str(name).strip()
          m = ACTIVE_RE.match(workspace_name)
          if not m:
              raise RuntimeError(f"bad ws name: {workspace_name!r}")
          return {
              "project": m.group("proj"),
              "sub": m.group("sub"),
              "name": workspace_name,
          }


      def current_workspace():
          name = str(hyprj(["activeworkspace", "-j"]).get("name", "")).strip()
          return parse_workspace_name(name)


      def current_project():
          return current_workspace()["project"]


      def ensure_state_dir():
          STATE_DIR.mkdir(parents=True, exist_ok=True)


      def load_state():
          if not STATE_FILE.exists():
              return {}

          try:
              data = json.loads(STATE_FILE.read_text())
          except Exception:
              return {}

          if not isinstance(data, dict):
              return {}

          return {
              str(project): str(workspace_name)
              for project, workspace_name in data.items()
              if isinstance(project, str) and isinstance(workspace_name, str)
          }


      def save_state(state):
          ensure_state_dir()
          STATE_FILE.write_text(json.dumps(state))


      def clear_project_memory(project):
          state = load_state()
          state.pop(str(project), None)
          save_state(state)


      def remember_workspace(workspace):
          state = load_state()

          if workspace["sub"] is None:
              state.pop(workspace["project"], None)
              save_state(state)
              return

          state[workspace["project"]] = workspace["name"]
          save_state(state)


      def remember_current_workspace():
          remember_workspace(current_workspace())


      def resolve_project_target(project):
          project_name = str(project)
          state = load_state()
          remembered_name = state.get(project_name)

          if remembered_name:
              remembered_workspace = parse_workspace_name(remembered_name)
              if remembered_workspace["project"] == project_name:
                  return f"name:{remembered_name}"

          return project_name


      def dispatch_workspace(project):
          remember_current_workspace()
          current = current_workspace()
          target = (
              project
              if str(current["project"]) == str(project)
              else resolve_project_target(project)
          )
          run(["hyprctl", "dispatch", "workspace", target])


      def dispatch_move(project):
          remember_current_workspace()
          run(["hyprctl", "dispatch", "movetoworkspacesilent", resolve_project_target(project)])


      def main():
          if len(sys.argv) < 2:
              print(
                  "usage: wsctl goto N | move N | main | main-move | project N | project-move N | resolve N | remember",
                  file=sys.stderr,
              )
              return 1

          cmd = sys.argv[1]
          proj = current_project()

          if cmd == "goto":
              sub = sys.argv[2]
              remember_current_workspace()
              target = f"{proj}[{sub}]"
              run(["hyprctl", "dispatch", "workspace", f"name:{target}"])
              return 0

          if cmd == "move":
              sub = sys.argv[2]
              remember_current_workspace()
              target = f"{proj}[{sub}]"
              run(["hyprctl", "dispatch", "movetoworkspacesilent", f"name:{target}"])
              return 0

          if cmd == "main":
              clear_project_memory(proj)
              target = f"{proj}"
              run(["hyprctl", "dispatch", "workspace", f"name:{target}"])
              return 0

          if cmd == "main-move":
              remember_current_workspace()
              target = f"{proj}"
              run(["hyprctl", "dispatch", "movetoworkspacesilent", f"name:{target}"])
              return 0

          if cmd == "project":
              dispatch_workspace(sys.argv[2])
              return 0

          if cmd == "project-move":
              dispatch_move(sys.argv[2])
              return 0

          if cmd == "resolve":
              print(resolve_project_target(sys.argv[2]))
              return 0

          if cmd == "remember":
              remember_current_workspace()
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
