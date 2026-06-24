#!/usr/bin/env bash
# theme-switch: toggle Home‑Manager light/dark specialisations with theme support
set -euo pipefail

usage() {
  echo "Usage: $0 [-p polarity] [-t theme]" >&2
  echo "  -p polarity   Polarity: dark or light (default: detected by darkman or 'dark')" >&2
  echo "  -t theme      Theme name (default: output of 'themectl get-theme' or 'default')" >&2
  exit 1
}

# Default values
polarity=""
theme=""

# Parse options
while getopts ":p:t:" opt; do
  case $opt in
  p) polarity="$OPTARG" ;;
  t) theme="$OPTARG" ;;
  *) usage ;;
  esac
done

# Get defaults if not set
if [[ -z "$polarity" ]]; then
  polarity="$(darkman get 2>/dev/null || echo dark)"
fi
if [[ "$polarity" != "dark" && "$polarity" != "light" ]]; then
  echo "Invalid polarity: $polarity" >&2
  usage
fi
if [[ -z "$theme" ]]; then
  theme="$(themectl get-theme 2>/dev/null || echo default)"
fi

# Find home-manager activation dir for standalone Home Manager.
home_manager_profile="$HOME/.local/state/nix/profiles/home-manager"
home_manager_dir="$(readlink -f "$home_manager_profile")"
if [[ -z "$home_manager_dir" || ! -x "$home_manager_dir/activate" ]]; then
  echo "Could not find home-manager activation directory" >&2
  exit 1
fi

# Compose activation command path
if [[ "$theme" == "default" && "$polarity" == "dark" ]]; then
  activate_cmd="$home_manager_dir/activate"
else
  activate_cmd="$home_manager_dir/specialisation/${theme}-${polarity}/activate"
fi

# Perform switch
if [[ -x "$activate_cmd" ]]; then
  echo "Switching to theme '$theme' with polarity '$polarity'..."
  "$activate_cmd"
else
  echo "Activation script not found or not executable: $activate_cmd. Falling back to '$home_manager_dir/activate'" >&2
  "$home_manager_dir"/activate
fi
