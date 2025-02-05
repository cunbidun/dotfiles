local M = {}

function M.setup()
  local _vscode = require("vscode")
  _vscode.setup({})
  _vscode.load()
end

return M
