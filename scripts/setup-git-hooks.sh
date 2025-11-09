#!/usr/bin/env bash
# Setup git hooks for the repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"
HOOKS_SOURCE_DIR="$REPO_ROOT/.git-hooks"

echo "Setting up git hooks..."
mkdir -p "$GIT_HOOKS_DIR"

if [ -f "$HOOKS_SOURCE_DIR/pre-commit-secrets" ]; then
  cp "$HOOKS_SOURCE_DIR/pre-commit-secrets" "$GIT_HOOKS_DIR/pre-commit"
  chmod +x "$GIT_HOOKS_DIR/pre-commit"
  echo "✓ Installed pre-commit hook for secrets detection"
else
  echo "✗ pre-commit-secrets hook not found"
  exit 1
fi

echo ""
echo "Git hooks installed! To bypass: SKIP_PRECOMMIT=1 git commit"
