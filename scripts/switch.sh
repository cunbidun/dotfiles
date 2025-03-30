#!/usr/bin/env bash
set -euo pipefail

# get the directory of the script
script_dir=$(dirname "$(readlink -f "$0")")

# get the git repository root directory
get_git_root() {
  local dir="$1"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then
      echo "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
  echo ""
}

# Find the git repository root
git_root=$(get_git_root "$script_dir")
if [ -z "$git_root" ]; then
  echo "Error: Not inside a git repository."
  exit 1
fi

# Change to the git repository root directory
cd "$git_root"

echo "Switching NixOS configuration from the git repository at: $git_root"

# Auto-add all changes and commit if there are any
git add -A
if ! git diff-index --quiet HEAD --; then
  commit_message="Auto commit: $(date +'%Y-%m-%d %H:%M:%S')"
  git commit -m "$commit_message"
  echo "Committed changes with message: $commit_message"
else
  echo "No changes to commit."
fi

# Detect OS and switch accordingly
os=$(uname)
if [ "$os" = "Darwin" ]; then
  echo "Detected macOS; running darwin-rebuild switch..."
  darwin-rebuild switch --flake ~/dotfiles#macbook-m1
else
  echo "Detected non-macOS; running nix switch..."
  sudo nixos-rebuild switch --cores 0 --flake ~/dotfiles#nixos
fi

