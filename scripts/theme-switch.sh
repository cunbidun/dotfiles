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
if [[ -z "$theme" ]]; then
  theme="$(themectl get-theme 2>/dev/null || echo default)"
fi

# Find home-manager activation dir
home_manager_dir="$(systemctl cat home-manager-"$USER".service | grep 'ExecStart' | awk '{print $2}')"
if [[ -z "$home_manager_dir" ]]; then
  echo "Could not find home-manager directory" >&2
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
