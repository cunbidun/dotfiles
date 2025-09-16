-- themc.lua 
local uv = vim.loop
local DEFAULT_THEME = "vscode"
local M = {}

-- Find the full path to themectl
local themectl_path = nil
local function find_themectl()
  if themectl_path then
    return themectl_path
  end
  local result = vim.system({ "which", "themectl" }, { text = true }):wait()
  if result.code == 0 and result.stdout then
    themectl_path = vim.trim(result.stdout)
    return themectl_path
  end
  return nil
end

-- --- helpers ---------------------------------------------------------------
local function trim(s)
  return (s or ""):gsub("^%s*(.-)%s*$", "%1")
end

-- --- async theme refresh ---------------------------------------------------
local last_theme
local last_failure_notified = false
local function refresh()
  local cmd_path = find_themectl()
  if not cmd_path then
    -- themectl not found, use fallback theme
    if not last_failure_notified then
      vim.notify(
        ("Theme manager (themectl) not found; falling back to '%s' colorscheme"):format(DEFAULT_THEME),
        vim.log.levels.WARN
      )
      last_failure_notified = true
    end
    local theme = DEFAULT_THEME
    if theme ~= last_theme then
      last_theme = theme
      vim.schedule(function()
        M.apply_scheme(theme)
      end)
    end
    return
  end

  vim.system({ cmd_path, "get-nvim-theme" }, { text = true }, function(obj)
    local theme
    if obj.code == 0 then -- success; use real output
      theme = trim(obj.stdout)
      -- If we previously failed and now succeeded, notify about recovery
      if last_failure_notified then
        vim.notify(
          ("Theme manager recovered: using Neovim theme '%s'"):format(theme),
          vim.log.levels.INFO
        )
        last_failure_notified = false
      end
    else -- failure; use the fallback
      theme = DEFAULT_THEME
      -- Only notify about failure once
      if not last_failure_notified then
        local error_details = ""
        if obj.stderr and obj.stderr ~= "" then
          error_details = ": " .. trim(obj.stderr)
        elseif obj.code == 1 then
          error_details = " (theme mapping not found)"
        end
        vim.notify(
          ("Theme manager failed (exit %d)%s; falling back to '%s'"):format(obj.code or -1, error_details, DEFAULT_THEME),
          vim.log.levels.WARN
        )
        last_failure_notified = true
      end
    end
    if theme ~= last_theme then
      last_theme = theme
      vim.schedule(function()
        M.apply_scheme(theme)
      end)
    end
  end)
end

-- --- public API ------------------------------------------------------------
function M.apply_scheme(name)
  if not name then
    return
  end
  local ok = pcall(function()
    vim.cmd.colorscheme(name)
  end)
  if not ok then
    vim.notify("Failed to load Neovim colorscheme '" .. tostring(name) .. "' - colorscheme may not be installed", vim.log.levels.WARN)
  end
end

local t = uv.new_timer()
t:start(0, 2000, vim.schedule_wrap(refresh))

-- --- initial kick ----------------------------------------------------------
refresh()

return M
