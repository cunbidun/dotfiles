#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <workflow.json> [workflow-id]" >&2
  exit 1
fi

workflow_file=$1
[[ -f "$workflow_file" ]] || { echo "File not found: $workflow_file" >&2; exit 1; }

workflow_id="${2:-${WORKFLOW_ID:-}}"
base_url="${N8N_BASE_URL:-https://rpi5.tail9b4f4d.ts.net:5678}"

auth_args=()
if [[ -n "${N8N_API_KEY:-}" ]]; then
  auth_args+=(-H "X-N8N-API-KEY: ${N8N_API_KEY}")
elif [[ -n "${N8N_BASIC_AUTH:-}" ]]; then
  auth_args+=(-u "${N8N_BASIC_AUTH}")
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
  url="${base_url}/rest/workflows/${workflow_id}"
else
  method="POST"
  url="${base_url}/rest/workflows"
fi

curl -fsSL \
  -X "${method}" \
  "${auth_args[@]}" \
  -H "Content-Type: application/json" \
  --data-binary "@${workflow_file}" \
  "${url}"

echo "Workflow ${workflow_id:-<new>} synced to ${base_url}"
