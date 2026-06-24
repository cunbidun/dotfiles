#!/usr/bin/env bash
# theme-switch: toggle Home‑Manager light/dark specialisations with theme support
set -euo pipefail

usage() {
  echo "Usage: $0 [-p polarity] [-t theme]" >&2
  echo "  -p polarity   Polarity: dark or light (default: persisted state)" >&2
  echo "  -t theme      Theme name (default: persisted state)" >&2
  exit 1
}

# Default values
polarity=""
theme=""
theme_state_file="$HOME/.local/state/stylix/current-theme-name.txt"

# Parse options
while getopts ":p:t:" opt; do
  case $opt in
  p) polarity="$OPTARG" ;;
  t) theme="$OPTARG" ;;
  *) usage ;;
  esac
done

# Get defaults from persisted state if not set
if [[ -z "$polarity" || -z "$theme" ]]; then
  current_theme_name="$(<"$theme_state_file")"
  case "$current_theme_name" in
  *-dark)
    state_theme="${current_theme_name%-dark}"
    state_polarity="dark"
    ;;
  *-light)
    state_theme="${current_theme_name%-light}"
    state_polarity="light"
    ;;
  *)
    echo "Invalid theme state: $current_theme_name" >&2
    exit 1
    ;;
  esac

  [[ -n "$theme" ]] || theme="$state_theme"
  [[ -n "$polarity" ]] || polarity="$state_polarity"
fi
if [[ "$polarity" != "dark" && "$polarity" != "light" ]]; then
  echo "Invalid polarity: $polarity" >&2
  usage
fi

specialisation_name="${theme}-${polarity}"
activate_cmd="$HOME/.local/state/nix/profiles/home-manager/specialisation/$specialisation_name/activate"

# Perform switch
if [[ ! -x "$activate_cmd" ]]; then
  echo "Activation script not found or not executable: $activate_cmd" >&2
  exit 1
fi

echo "Switching to theme '$theme' with polarity '$polarity'..."
"$activate_cmd" --driver-version 1
