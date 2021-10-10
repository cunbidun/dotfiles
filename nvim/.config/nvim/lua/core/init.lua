local M = {}

function M:init()
  local settings = require "core.settings"
  settings.load_options()
  vim.cmd [[source $HOME/.config/nvim/lua/core/cp.vim]]
end

return M
