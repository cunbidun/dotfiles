local M = {}

local aliases = {
  vscode_dark = "vscode",
  vscode_light = "vscode",
}

local function apply_highlight_fallbacks()
  local links = {
    ["@comment"] = "Comment",
    ["@keyword"] = "Keyword",
    ["@keyword.function"] = "Keyword",
    ["@keyword.return"] = "Keyword",
    ["@string"] = "String",
    ["@number"] = "Number",
    ["@boolean"] = "Boolean",
    ["@function"] = "Function",
    ["@function.call"] = "Function",
    ["@method"] = "Function",
    ["@type"] = "Type",
    ["@type.builtin"] = "Type",
    ["@variable"] = "Identifier",
    ["@parameter"] = "Identifier",
    ["@constant"] = "Constant",
    ["@operator"] = "Operator",
    ["@punctuation.delimiter"] = "Delimiter",
    ["@punctuation.bracket"] = "Delimiter",
  }

  for from, to in pairs(links) do
    vim.api.nvim_set_hl(0, from, { link = to })
  end
end

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
  apply_highlight_fallbacks()
end

return M
