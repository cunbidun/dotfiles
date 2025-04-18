#!/usr/bin/env bash
# theme-switch: toggle Home‑Manager light/dark specialisations
set -euo pipefail

usage() {
  echo "Usage: $0 {dark|light}" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage
MODE=$1

# locate your home-manager activation directory
home_manager_dir=$(
  systemctl cat home-manager-cunbidun.service \
    | awk -F= '/ExecStart=/{print $2; exit}'
)
if [[ -z "$home_manager_dir" ]]; then
  echo "Could not find home-manager directory" >&2
  exit 1
fi

# map modes to target dconf values and activation scripts
case "$MODE" in
  dark)
    target_scheme=prefer-dark
    activate_cmd="$home_manager_dir/activate"
    ;;
  light)
    target_scheme=prefer-light
    activate_cmd="$home_manager_dir/specialisation/light-theme/activate"
    ;;
  *)
    usage
    ;;
esac

# read current GNOME color scheme (unquoted)
current_scheme=$(dconf read /org/gnome/desktop/interface/color-scheme | tr -d "'")

if [[ "$current_scheme" == "$target_scheme" ]]; then
  echo "Already using the $MODE theme (dconf reports '$current_scheme')."
  exit 0
fi

# perform switch
if [[ -x "$activate_cmd" ]]; then
  echo "Switching to the $MODE theme…"
  "$activate_cmd"
else
  echo "Activation script not found or not executable: $activate_cmd" >&2
  exit 1
fi