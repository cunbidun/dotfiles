#!/usr/bin/env bash
set -euo pipefail

commit_changes=true
commit_message="Auto commit: $(date +'%Y-%m-%d %H:%M:%S')"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
  --no-commit)
    commit_changes=false
    shift
    ;;
  --commit-message)
    if [[ -n "${2:-}" && ! "$2" =~ ^-- ]]; then
      commit_message="$2"
      shift 2
    else
      echo "Error: --commit-message requires a non-empty argument."
      exit 1
    fi
    ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done

# Detect OS and switch accordingly
os=$(uname)

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

if [ "$os" != "Darwin" ]; then
  # check if nix/hosts/nixos/hardware-configuration.nix content is similar to /etc/nixos/hardware-configuration.nix
  # if not, copy the content from /etc/nixos/hardware-configuration.nix to nix/hosts/nixos/hardware-configuration.nix
  # this assume that /etc/nixos/hardware-configuration.nix is the source of truth for hardware configuration

  # check if the file /etc/nixos/hardware-configuration.nix exists, if not print an error message and exit
  if [ ! -f /etc/nixos/hardware-configuration.nix ]; then
    echo "Error: /etc/nixos/hardware-configuration.nix does not exist."
    exit 1
  fi

  # Compare the content of the two files
  if ! cmp -s /etc/nixos/hardware-configuration.nix "$git_root/nix/hosts/nixos/hardware-configuration.nix"; then
    echo "Updating nix/hosts/nixos/hardware-configuration.nix from /etc/nixos/hardware-configuration.nix"
    # Copy the content from /etc/nixos/hardware-configuration.nix to nix/hosts/nixos/hardware-configuration.nix
    cp /etc/nixos/hardware-configuration.nix "$git_root/nix/hosts/nixos/hardware-configuration.nix"
  else
    echo "No changes detected in hardware-configuration.nix."
  fi
fi

# Change to the git repository root directory
cd "$git_root"

# Check if git root is "/home/$USER/dotfiles" or not. If not print an error message and exit
# This is to ensure that the script is being run from the correct directory
if [ "$os" = "Darwin" ]; then
  if [ "$git_root" != "/Users/$USER/dotfiles" ]; then
    echo "Error: dotfiles repository is not in the expected location. It is expected to be at /Users/$USER/dotfiles but found at $git_root."
    exit 1
  fi
else
  if [ "$git_root" != "/home/$USER/dotfiles" ]; then
    echo "Error: dotfiles repository is not in the expected location. It is expected to be at /home/$USER/dotfiles but found at $git_root."
    exit 1
  fi
fi

echo "Switching NixOS configuration from the git repository at: $git_root"

# Always add changes to staging
git add -A

if [ "$os" = "Darwin" ]; then
  echo "Detected macOS; running darwin-rebuild switch..."
  if sudo darwin-rebuild switch --flake ~/dotfiles'#macbook-m1' --cores 0; then
    switch_success=true
  else
    switch_success=false
  fi
else
  echo "Detected non-macOS; running nix switch..."
  sudo -v # Ensure sudo is available and prompt for password if needed
  if sudo nixos-rebuild switch --flake ~/dotfiles'#nixos' --cores 0; then
    switch_success=true
  else
    switch_success=false
  fi
fi

# Get the current NixOS system profile version (e.g., system-1526-link)
nixos_version=""
if [ "$os" != "Darwin" ]; then
  nixos_version=$(basename "$(readlink /nix/var/nix/profiles/system)" | sed 's/-link$//')
fi

if [ "$switch_success" = true ]; then
  echo "NixOS switch successful."
  if [ "$commit_changes" = true ]; then
    if ! git diff-index --quiet HEAD --; then
      # Append NixOS version to the commit message if available
      if [ -n "$nixos_version" ]; then
        git commit -m "$commit_message (nixos version: $nixos_version)"
        echo "Committed changes with message: $commit_message (nixos version: $nixos_version)"
      else
        git commit -m "$commit_message"
        echo "Committed changes with message: $commit_message"
      fi
    else
      echo "No changes to commit after successful switch."
    fi
  else
    echo "--no-commit flag set; skipping commit."
  fi
else
  echo "NixOS switch failed; skipping commit."
fi

if [ "$switch_success" = false ]; then
  echo "Error: NixOS switch failed."
  exit 1
fi
echo "NixOS configuration switch completed successfully."

