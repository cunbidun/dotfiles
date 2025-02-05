local M = {}

M.setup = function()
  require("toggleterm").setup({
    direction = "float",
    float_opts = { border = "single" },
    insert_mappings = true,
    open_mapping = [[<C-\>]],
    shell = "zsh",
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return math.min(120, math.max(vim.o.columns - 130, 35))
      else
        return 20
      end
    end,
    terminal_mappings = true,
  })
end

return M
