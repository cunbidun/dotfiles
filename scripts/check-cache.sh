#!/usr/bin/env bash
set -Eeuo pipefail
sudo -v

# Determine the profile based on hostname or argument
PROFILE="${1:-}"
if [[ -z "$PROFILE" ]]; then
  case "$(uname -s)" in
    Darwin) PROFILE="macbook" ;;
    Linux)  PROFILE="nixos" ;;
    *)      echo "Unknown OS. Specify profile: $0 <nixos|macbook|rpi>" >&2; exit 1 ;;
  esac
fi

echo "Checking cache status for profile: $PROFILE"
echo "============================================"

# Get the derivations that would be built
if [[ "$PROFILE" == "macbook" ]]; then
  DRVS=$(darwin-rebuild build --flake ".#$PROFILE" --dry-run 2>&1 | grep -oP '/nix/store/[a-z0-9]+-.*\.drv' || true)
else
  DRVS=$(sudo nixos-rebuild dry-build --flake ".#$PROFILE" 2>&1 | grep -oP '/nix/store/[a-z0-9]+-.*\.drv' || true)
fi

if [[ -z "$DRVS" ]]; then
  echo "✔ All packages available in cache or already built!"
  exit 0
fi

echo -e "\nDerivations to be built:"
echo "$DRVS" | while read -r drv; do
  name=$(nix derivation show "$drv" 2>/dev/null | jq -r '.[].name' || echo "unknown")
  echo "  - $name ($drv)"
done

echo -e "\nChecking which are available in cache..."
echo "$DRVS" | while read -r drv; do
  bash "$(dirname "$0")/query.sh" "$drv" || true
done
