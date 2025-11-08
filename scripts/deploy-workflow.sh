#!/usr/bin/env bash
set -euox pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <workflow.json> [workflow-id]" >&2
  exit 1
fi

workflow_file=$1
[[ -f "$workflow_file" ]] || { echo "File not found: $workflow_file" >&2; exit 1; }

workflow_id="${2:-${WORKFLOW_ID:-}}"
base_url="${N8N_BASE_URL:-https://rpi5.tail9b4f4d.ts.net:5678}"
api_path="${N8N_API_PATH:-/api/v1}"

auth_args=()
api_key="${N8N_API_KEY:-}"
if [[ -z "$api_key" && -x "$(command -v op 2>/dev/null)" ]]; then
  api_key="$(op read 'op://Private/n8n/Saved on rpi5.tail9b4f4d.ts.net/API Key' 2>/dev/null || true)"
fi
if [[ -n "$api_key" ]]; then
  auth_args+=(-H "X-N8N-API-KEY: ${api_key}")
else
  echo "warning: no N8N_API_KEY available (set env var or ensure op signin)" >&2
fi

if [[ -z "$workflow_id" ]]; then
  if grep -q '"id"' "$workflow_file"; then
    line=$(grep -m1 '"id"' "$workflow_file" || true)
    if [[ $line =~ \"id\"[[:space:]]*:[[:space:]]*\"?([0-9a-fA-F\-]+)\"? ]]; then
      workflow_id="${BASH_REMATCH[1]}"
    fi
  fi
fi

if [[ -n "$workflow_id" ]]; then
  method="PATCH"
  url="${base_url}${api_path}/workflows/${workflow_id}"
else
  method="POST"
  url="${base_url}${api_path}/workflows"
fi

curl -fsSL \
  -X "${method}" \
  "${auth_args[@]}" \
  -H "Content-Type: application/json" \
  --data-binary "@${workflow_file}" \
  "${url}"

echo "Workflow ${workflow_id:-<new>} synced to ${base_url}"
