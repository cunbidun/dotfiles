#!/usr/bin/env bash
set -euo pipefail

# Download n8n workflows from the server and save them locally
# Usage: ./scripts/download-n8n-workflows.sh [workflow_id] [workflow_id] ...
#        ./scripts/download-n8n-workflows.sh                              (downloads all workflows)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
WORKFLOWS_DIR="$REPO_ROOT/workflows"

# Get n8n server details
N8N_HOST="${N8N_HOST:-rpi5.tail9b4f4d.ts.net}"
N8N_PORT="${N8N_PORT:-5678}"
N8N_URL="https://$N8N_HOST:$N8N_PORT"

# Get API key from 1Password
API_KEY_REF="op://Private/n8n/Saved on rpi5.tail9b4f4d.ts.net/API Key"
API_KEY=$(op read "$API_KEY_REF" 2>/dev/null || { echo "Error: Failed to retrieve API key from 1Password" >&2; exit 1; })

if [ -z "$API_KEY" ]; then
  echo "Error: API_KEY is empty" >&2
  exit 1
fi

# Function to download a single workflow
download_workflow() {
  local workflow_id="$1"
  
  echo "Downloading workflow: $workflow_id"
  
  # Fetch workflow data
  local response
  response=$(curl -s -k \
    -H "X-N8N-API-KEY: $API_KEY" \
    "$N8N_URL/api/v1/workflows/$workflow_id")
  
  # Check if response is valid JSON and has an id field
  if ! echo "$response" | jq -e '.id' >/dev/null 2>&1; then
    echo "Error: Failed to download workflow $workflow_id" >&2
    echo "Response: $response" >&2
    return 1
  fi
  
  # Extract workflow name and convert to snake_case filename
  local workflow_name
  workflow_name=$(echo "$response" | jq -r '.name // "workflow"')
  
  # Convert name to snake_case for filename
  local filename
  filename=$(echo "$workflow_name" | \
    sed -E 's/[[:space:]]+/-/g' | \
    sed -E 's/[^a-zA-Z0-9-]//g' | \
    tr '[:upper:]' '[:lower:]')
  
  local output_file="$WORKFLOWS_DIR/${filename}.json"
  
  # Save the workflow (formatted)
  echo "$response" | jq . > "$output_file"
  echo "✓ Saved to: $output_file"
}

# Function to list all workflows
list_workflows() {
  echo "Fetching workflow list..."
  
  local response
  response=$(curl -s -k \
    -H "X-N8N-API-KEY: $API_KEY" \
    "$N8N_URL/api/v1/workflows?limit=100")
  
  if ! echo "$response" | jq -e '.data' >/dev/null 2>&1; then
    echo "Error: Failed to fetch workflow list" >&2
    echo "Response: $response" >&2
    return 1
  fi
  
  echo "$response" | jq -r '.data[] | "\(.id): \(.name)"'
}

# Main logic
if [ $# -eq 0 ]; then
  # No arguments provided - list available workflows
  echo "No workflow IDs provided."
  echo ""
  echo "Available workflows on $N8N_HOST:"
  list_workflows
  echo ""
  echo "Usage: $0 <workflow_id> [workflow_id] ..."
  exit 0
else
  # Download specified workflows
  mkdir -p "$WORKFLOWS_DIR"
  
  for workflow_id in "$@"; do
    download_workflow "$workflow_id" || true
  done
  
  echo ""
  echo "Done! Workflows saved to: $WORKFLOWS_DIR"
fi
