local M = {}

M.setup = function()
  require("telescope").setup({
    defaults = {
      file_ignore_patterns = { "^.git/", "^.mypy_cache/", "^__pycache__/", "^output/", "^data/", "%.ipynb" },
      mappings = {
        i = {
          ["<C-j>"] = require("telescope.actions").move_selection_next,
          ["<C-k>"] = require("telescope.actions").move_selection_previous,
        },
      },
      set_env = { COLORTERM = "truecolor" },
    },
    pickers = { find_files = { hidden = true } },
  })
end

return M
