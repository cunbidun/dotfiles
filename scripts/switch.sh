#!/usr/bin/env bash
set -euo pipefail

commit_changes=true
commit_message="Auto commit: $(date +'%Y-%m-%d %H:%M:%S')"
profile_name=""
build_only=false
copy_back=false

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
  --build|--build-only)
    build_only=true
    shift
    ;;
  --copy-back)
    copy_back=true
    shift
    ;;
  *)
    if [[ -z "$profile_name" ]]; then
      profile_name="$1"
      shift
    else
      echo "Unknown option or too many arguments: $1"
      exit 1
    fi
    ;;
  esac
done

# Check if profile_name is provided
if [[ -z "$profile_name" ]]; then
  echo "Usage: $0 [--no-commit] [--commit-message <message>] [--build-only] [--copy-back] <profile_name>"
  echo "  <profile_name> can be 'macbook-m1' or 'nixos'"
  echo "  --build-only: Build configuration without switching"
  echo "  --copy-back: Copy generated configuration files back to repository (default: false)"
  exit 1
fi

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
sudo -v # Ensure sudo is available and prompt for password if needed

switch_success=false
operation="switch"
operation_desc="switch"
if [ "$build_only" = true ]; then
  operation="build"
  operation_desc="build (no switch)"
fi

if [ "$os" = "Darwin" ]; then
  echo "Detected macOS; running darwin-rebuild $operation_desc..."
  if sudo darwin-rebuild "$operation" --flake ~/dotfiles"#$profile_name"; then
    switch_success=true
  fi
else
  echo "Detected non-macOS; running nixos-rebuild $operation_desc..."
  if sudo nixos-rebuild --log-format internal-json "$operation" --flake ~/dotfiles"#$profile_name" --cores 0 |& nom --json; then
    switch_success=true
  fi
fi

if [ "$switch_success" = false ]; then
  if [ "$build_only" = true ]; then
    echo "Error: Build failed."
  else
    echo "Error: Switch failed."
  fi
  exit 1
fi

if [ "$build_only" = true ]; then
  echo "Build completed successfully. Run this script again without --build-only to switch using the cached result."
  exit 0
fi

copy_files_to_git_root() {
  local src abs_src dest dest_dir
  for src in "$@"; do
    # 2. Skip if the source file doesn’t exist
    if [[ ! -e "$src" ]]; then
      echo "Warning: source not found: $src" >&2
      exist 1
    fi

    # 3. Resolve absolute path; skip on failure
    abs_src=$(readlink -f "$src") || {
      echo "Error: cannot resolve path: $src" >&2
      exist 1
    }

    # 4. Build the destination path and create its directory
    dest="$git_root/generated/$profile_name/${src/#$HOME\//}"
    dest_dir=${dest%/*}
    mkdir -p "$dest_dir"

    if [ $os != "Darwin" ]; then
      # 5. Copy safely: update only newer files and handle symlinks
      cp -r --remove-destination "$abs_src" "$dest" || {
        echo "Error: failed to copy $abs_src to $dest" >&2
        exist 1
      }
    else
      cp -R "$abs_src" "$dest" || {
        echo "Error: failed to copy $abs_src to $dest" >&2
        exit 1
      }
    fi
  done
}

# Get the current NixOS system profile version (e.g., system-1526-link)
nixos_version=""
if [ "$os" != "Darwin" ]; then
  nixos_version=$(basename "$(readlink /nix/var/nix/profiles/system)" | sed 's/-link$//')
fi

# Only copy files back if the --copy-back option is enabled
if [ "$copy_back" = true ]; then
  rm -rf "$git_root/generated/$profile_name" || true
  echo "Removed old generated configuration files for $profile_name."

  if [ "$os" != "Darwin" ]; then
    echo "Detected NixOS; copying configuration files for NixOS..."
    config_files=(
      "$HOME/.config/Code/User/keybindings.json"
      "$HOME/.config/Code/User/settings.json"
      "$HOME/.config/tmux/tmux.conf"
      "$HOME/.config/nvim"
    )
    copy_files_to_git_root "${config_files[@]}"

    extensions_dir="$HOME/.vscode/extensions"
    if [ -d "$extensions_dir" ]; then
      extensions_output="$git_root/generated/$profile_name/vscode/extensions.txt"
      mkdir -p "$(dirname "$extensions_output")"
      command ls -1 "$extensions_dir" >"$extensions_output"
    else
      echo "Warning: VSCode extensions directory not found: $extensions_dir" >&2
    fi
  fi

  if [ "$os" = "Darwin" ]; then
    echo "Detected macOS; copying configuration files for macOS..."
    config_files=(
      "$HOME/Library/Application Support/Code/User/keybindings.json"
      "$HOME/Library/Application Support/Code/User/settings.json"
    )
    copy_files_to_git_root "${config_files[@]}"
  fi
else
  echo "Skipping file copy-back (use --copy-back to enable)."
fi

echo "NixOS switch successful."
git add -A
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

echo "Configuration switch completed successfully."
