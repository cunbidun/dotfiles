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

specialisation_name="${theme}-${polarity}"
flake_ref="$HOME/dotfiles#${USER}@${HOSTNAME}"

# Perform switch
echo "Switching to theme '$theme' with polarity '$polarity'..."
home-manager switch --flake "$flake_ref" --specialisation "$specialisation_name"
