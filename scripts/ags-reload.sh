#!/usr/bin/env bash

# Hot reload AGS configuration
# Since AGS config is symlinked when hermeticAgsConfig = false,
# we just need to restart AGS to pick up changes

set -euo pipefail

echo "🔄 Reloading AGS..."

# Restart AGS
if pgrep -x ags > /dev/null; then
    echo "🔄 Restarting AGS..."
    pkill ags
    sleep 0.5
fi

echo "🚀 Starting AGS..."
ags &

echo "✨ AGS reloaded!"
echo ""
echo "💡 Edit files in ~/dotfiles/nix/home-manager/configs/hyprland/ags/ and run this script to see changes!"