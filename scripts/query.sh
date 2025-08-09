#!/usr/bin/env bash
set -Eeuo pipefail

DRV="${1:-}"
[[ -n "$DRV" && -e "$DRV" ]] || { echo "Usage: $0 /nix/store/<...>.drv" >&2; exit 2; }

# Pick the right command: new CLI vs old
if nix derivation show --help >/dev/null 2>&1; then
  DERIV_CMD=(nix derivation show)
else
  DERIV_CMD=(nix show-derivation)
fi

# Get output store paths from the derivation JSON
OUT_PATHS="$("${DERIV_CMD[@]}" "$DRV" | jq -r '.[].outputs | to_entries[] | .value.path')"
[[ -n "$OUT_PATHS" ]] || { echo "No outputs found in: $DRV" >&2; exit 3; }

# Get HTTP(S) substituters from your config
SUB_LINE="$(nix show-config | sed -n 's/^substituters = //p')"
HTTP_SUBS=()
for s in $SUB_LINE; do
  [[ "$s" =~ ^https?:// ]] && HTTP_SUBS+=("${s%/}")
done
((${#HTTP_SUBS[@]})) || { echo "No HTTP(S) substituters configured."; exit 4; }

rc=0
for out in $OUT_PATHS; do
  h="${out##*/}"; h="${h%%-*}"   # the hash portion of /nix/store/<hash>-name
  echo "Output: $out"
  for sub in "${HTTP_SUBS[@]}"; do
    url="$sub/$h.narinfo"
    if curl -sIf "$url" >/dev/null; then
      echo "  ✔ CACHED at $sub"
    else
      echo "  ✘ MISSING at $sub"
      rc=1
    fi
  done
done
exit "$rc"
