#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
EXTENSIONS_FILE="$SCRIPT_DIR/vscode-extensions.txt"

usage() {
  echo "Usage: $0 {save|load}" >&2
  echo "  save  - Save current VS Code extensions to $EXTENSIONS_FILE" >&2
  echo "  load  - Load extensions from $EXTENSIONS_FILE and remove others" >&2
  exit 1
}

save_extensions() {
  echo "Saving current VS Code extensions to $EXTENSIONS_FILE..."
  
  if ! command -v code &> /dev/null; then
    echo "Error: VS Code command 'code' not found in PATH" >&2
    exit 1
  fi
  
  code --list-extensions > "$EXTENSIONS_FILE"
  echo "Saved $(wc -l < "$EXTENSIONS_FILE") extensions to $EXTENSIONS_FILE"
  echo "Extensions saved:"
  cat "$EXTENSIONS_FILE"
}

load_extensions() {
  echo "Loading extensions from $EXTENSIONS_FILE..."
  
  if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    echo "Error: Extensions file not found: $EXTENSIONS_FILE" >&2
    echo "Run '$0 save' first to create the extensions list." >&2
    exit 1
  fi
  
  if ! command -v code &> /dev/null; then
    echo "Error: VS Code command 'code' not found in PATH" >&2
    exit 1
  fi
  
  # Get current extensions
  mapfile -t current_extensions < <(code --list-extensions)
  
  # Get target extensions from file
  target_extensions=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && target_extensions+=("$line")
  done < "$EXTENSIONS_FILE"
  
  echo "Target extensions (${#target_extensions[@]}):"
  printf '%s\n' "${target_extensions[@]}"
  echo
  
  # Find extensions to install
  extensions_to_install=()
  for target_ext in "${target_extensions[@]}"; do
    local found=false
    for current_ext in "${current_extensions[@]}"; do
      if [[ "$current_ext" == "$target_ext" ]]; then
        found=true
        break
      fi
    done
    if [[ "$found" == false ]]; then
      extensions_to_install+=("$target_ext")
    fi
  done
  
  # Find extensions to remove
  extensions_to_remove=()
  for current_ext in "${current_extensions[@]}"; do
    local found=false
    for target_ext in "${target_extensions[@]}"; do
      if [[ "$target_ext" == "$current_ext" ]]; then
        found=true
        break
      fi
    done
    if [[ "$found" == false ]]; then
      extensions_to_remove+=("$current_ext")
    fi
  done
  
  # Show what will be done
  if [[ ${#extensions_to_install[@]} -gt 0 ]]; then
    echo "Extensions to install (${#extensions_to_install[@]}):"
    printf '%s\n' "${extensions_to_install[@]}"
    echo
  else
    echo "No extensions need to be installed."
    echo
  fi
  
  if [[ ${#extensions_to_remove[@]} -gt 0 ]]; then
    echo "Extensions to remove (${#extensions_to_remove[@]}):"
    printf '%s\n' "${extensions_to_remove[@]}"
    echo
  else
    echo "No extensions need to be removed."
    echo
  fi
  
  # Confirm before proceeding
  if [[ ${#extensions_to_install[@]} -gt 0 || ${#extensions_to_remove[@]} -gt 0 ]]; then
    read -p "Do you want to proceed? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
      echo "Operation cancelled."
      exit 0
    fi
  else
    echo "Extensions are already in sync. Nothing to do."
    exit 0
  fi
  
  # Install missing extensions
  for ext in "${extensions_to_install[@]}"; do
    echo "Installing: $ext"
    if code --install-extension "$ext"; then
      echo "✔ Installed: $ext"
    else
      echo "✘ Failed to install: $ext" >&2
    fi
  done
  
  # Remove extra extensions
  for ext in "${extensions_to_remove[@]}"; do
    echo "Removing: $ext"
    if code --uninstall-extension "$ext"; then
      echo "✔ Removed: $ext"
    else
      echo "✘ Failed to remove: $ext" >&2
    fi
  done
  
  echo "Extension synchronization completed."
}

# Check arguments
if [[ $# -ne 1 ]]; then
  usage
fi

case "$1" in
  save)
    save_extensions
    ;;
  load)
    load_extensions
    ;;
  *)
    usage
    ;;
esac
