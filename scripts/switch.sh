#!/usr/bin/env bash
set -euo pipefail

# Change to your dotfiles repository
cd ~/dotfiles

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
  sudo nixos-rebuild switch --cores 12 --flake ~/dotfiles#nixos
fi