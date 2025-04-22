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
home_manager_dir="$(systemctl cat home-manager-"$USER".service | grep 'ExecStart' | awk '{print $2}')"
if [[ -z "$home_manager_dir" ]]; then
  echo "Could not find home-manager directory" >&2
  exit 1
fi

# map modes to target dconf values and activation scripts
case "$MODE" in
dark)
  activate_cmd="$home_manager_dir/activate"
  ;;
light)
  activate_cmd="$home_manager_dir/specialisation/light-theme/activate"
  ;;
*)
  usage
  ;;
esac

# perform switch
if [[ -x "$activate_cmd" ]]; then
  echo "Switching to the $MODE theme..."
  "$activate_cmd"
else
  echo "Activation script not found or not executable: $activate_cmd" >&2
  exit 1
fi

