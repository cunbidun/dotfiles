#!/usr/bin/env bash
# collect-vscode-config.sh
#
# This script collects your VSCode user configuration files (settings.json and keybindings.json)
# into a destination directory relative to the script location.
#
# On Linux, it uses: $HOME/.config/Code/User
# On macOS, it uses: $HOME/Library/Application Support/Code/User
#
# The destination is:
#   (directory containing this script)/../generated/vscode
#
# It uses cp with -L (dereference symlinks) and -p (preserve mode, ownership, and timestamps).
#
# Usage: ./collect-vscode-config.sh

set -euo pipefail

# Determine OS and set the VSCode User configuration source directory.
OS=$(uname)
if [ "$OS" = "Linux" ]; then
  VSCODE_SRC="$HOME/.config/Code/User"
elif [ "$OS" = "Darwin" ]; then
  VSCODE_SRC="$HOME/Library/Application Support/Code/User"
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Compute the destination directory relative to this script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VSCODE_DEST="${SCRIPT_DIR}/../generated/vscode"
mkdir -p "$VSCODE_DEST"

# List of files to copy.
files=( "settings.json" "keybindings.json" )

for file in "${files[@]}"; do
  SRC_FILE="$VSCODE_SRC/$file"
  if [ -f "$SRC_FILE" ]; then
    echo "Copying $SRC_FILE to $VSCODE_DEST/"
    # -L: Follow symlinks, -p: Preserve file attributes.
    cp -Lp "$SRC_FILE" "$VSCODE_DEST/"
  else
    echo "Warning: $SRC_FILE not found; skipping."
  fi
done

echo "VSCode configuration files (settings.json and keybindings.json) successfully collected to:"
echo "  $VSCODE_DEST"
