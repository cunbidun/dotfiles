local M = {}

local aliases = {
  vscode_dark = "vscode",
  vscode_light = "vscode",
}

function M.current()
  local handle = io.popen("themectl get-nvim-theme 2>/dev/null")
  if handle then
    local value = handle:read("*l")
    handle:close()
    if value and value ~= "" then
      return aliases[value] or value
    end
  end

  return "vscode"
end

function M.apply()
  local theme = M.current()
  pcall(vim.cmd.colorscheme, theme)
end

return M
