-- themc.lua  (Neovim ≥0.10)
local uv = vim.loop
local DEFAULT_THEME = "vscode"
local M = {}

-- --- helpers ---------------------------------------------------------------
local function trim(s)
  return (s or ""):gsub("^%s*(.-)%s*$", "%1")
end

-- --- async theme refresh ---------------------------------------------------
local last_theme
local function refresh()
  vim.system({ "themectl", "get-theme" }, { text = true }, function(obj)
    local theme
    if obj.code == 0 then -- success; use real output
      theme = trim(obj.stdout)
    else -- failure; use the fallback
      theme = DEFAULT_THEME
      vim.notify(
        ("themectl failed (exit %d); falling back to %s"):format(obj.code or -1, DEFAULT_THEME),
        vim.log.levels.WARN
      )
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
    local lower = name:lower()
    if lower:find("nord") then
      local highlights = require("nord").bufferline.highlights({
        italic = true,
        bold = true,
      })
      require("bufferline").setup({
        options = {
          indicator = {
            style = "underline", -- adds an underline indicator
          },
        },
        highlights = highlights,
      })
      vim.cmd.colorscheme("nord")
    else
      require("bufferline").setup({

        options = {
          indicator = {
            style = "underline", -- adds an underline indicator
          },
        },
        highlights = {
          fill = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "StatusLineNC" },
          },
          background = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "StatusLine" },
          },
          buffer_visible = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "Normal" },
          },
          buffer_selected = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "Normal" },
          },
          separator = {
            fg = { attribute = "bg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "StatusLine" },
          },
          separator_selected = {
            fg = { attribute = "fg", highlight = "Special" },
            bg = { attribute = "bg", highlight = "Normal" },
          },
          separator_visible = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "StatusLineNC" },
          },
          close_button = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "StatusLine" },
          },
          close_button_selected = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "Normal" },
          },
          close_button_visible = {
            fg = { attribute = "fg", highlight = "Normal" },
            bg = { attribute = "bg", highlight = "Normal" },
          },
        },
      })
      vim.cmd.colorscheme("vscode")
    end
    vim.g.colors_name = lower:gsub("%s+", "_")
  end)
  if not ok then
    vim.notify("Failed to load " .. tostring(name), vim.log.levels.WARN)
  end
end

local t = uv.new_timer()
t:start(0, 2000, vim.schedule_wrap(refresh))

-- --- initial kick ----------------------------------------------------------
refresh()

return M
