local M = {}

M.setup = function()
  require("lualine").setup({ options = { globalstatus = true } })
end
return M
