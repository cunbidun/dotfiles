#!/usr/bin/env bash
set -euo pipefail

# Detect intermittent "global Snacks is nil" startup/config races.
#
# Usage:
#   scripts/test_nvim_snacks_nil.sh            # default 25 runs
#   scripts/test_nvim_snacks_nil.sh 100        # custom run count
#
# Exit codes:
#   0 = no issue detected in any run
#   1 = issue detected (details printed)

RUNS="${1:-25}"
if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [[ "$RUNS" -lt 1 ]]; then
  echo "Expected a positive integer run count, got: $RUNS" >&2
  exit 2
fi

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

LUA_FILE="$TMP_DIR/snacks_nil_probe.lua"
cat >"$LUA_FILE" <<'LUA'
local failures = {}
local function add_failure(msg)
  failures[#failures + 1] = msg
end

local function check_snacks(stage)
  if type(_G.Snacks) ~= "table" then
    add_failure(stage .. ": global Snacks type is " .. type(_G.Snacks))
  end
end

-- Force deferred startup paths that a plain "+qa" can skip.
local ok_event, err_event = pcall(function()
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
  vim.wait(50)
end)
if not ok_event then
  add_failure("VeryLazy autocmd failed: " .. tostring(err_event))
end

check_snacks("after VeryLazy")

local ok_lazy, lazy = pcall(require, "lazy")
if not ok_lazy then
  add_failure("require('lazy') failed: " .. tostring(lazy))
else
  local targets = { "mini.pairs", "lualine.nvim", "gitsigns.nvim" }
  for _, name in ipairs(targets) do
    local ok_load, err_load = pcall(function()
      lazy.load({ plugins = { name } })
      vim.wait(20)
    end)
    if not ok_load then
      add_failure("lazy.load(" .. name .. ") failed: " .. tostring(err_load))
    end
    check_snacks("after lazy.load(" .. name .. ")")
  end
end

local msgs = vim.api.nvim_exec2("messages", { output = true }).output or ""
if msgs:find("attempt to index global 'Snacks'", 1, true) then
  add_failure("messages include: attempt to index global 'Snacks'")
end
if msgs:find("Failed to run `config`", 1, true) then
  add_failure("messages include: Failed to run `config`")
end

if #failures > 0 then
  io.stderr:write("SNACKS_NIL_DETECTED\n")
  for _, f in ipairs(failures) do
    io.stderr:write("- " .. f .. "\n")
  end
  vim.cmd("cquit 1")
else
  io.stdout:write("SNACKS_NIL_NOT_DETECTED\n")
  vim.cmd("qa!")
end
LUA

FAIL=0
FIRST_FAIL_LOG=""

echo "Running Snacks nil detector for $RUNS cold starts..."
for i in $(seq 1 "$RUNS"); do
  ITER_LOG="$TMP_DIR/run-$i.log"

  # Use repo config directly via XDG_CONFIG_HOME so this test is independent
  # from whatever is currently symlinked at ~/.config/nvim.
  if ! XDG_CONFIG_HOME="$REPO_ROOT/utilities" nvim --headless \
      "+silent! luafile $LUA_FILE" \
      "+qa" >"$ITER_LOG" 2>&1; then
    FAIL=1
    FIRST_FAIL_LOG="$ITER_LOG"
    echo "FAIL on run $i/$RUNS"
    break
  fi

  # Sanity guard in case nvim exits 0 but emitted known failure text.
  if rg -q "attempt to index global 'Snacks'|Failed to run .config.|SNACKS_NIL_DETECTED|Plugin .* is not installed" "$ITER_LOG"; then
    FAIL=1
    FIRST_FAIL_LOG="$ITER_LOG"
    echo "FAIL on run $i/$RUNS (error text detected)"
    break
  fi

done

if [[ "$FAIL" -eq 1 ]]; then
  echo
  echo "Detector caught the issue. First failing log:"
  cat "$FIRST_FAIL_LOG"
  exit 1
fi

echo "PASS: no Snacks-nil/lazy-config issue detected in $RUNS/$RUNS runs."
