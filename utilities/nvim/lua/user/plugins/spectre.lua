return {
  "vim-plugins/nvim-spectre",
  dependencies = {
    "vim-plugins/plenary.nvim",
  },
  keys = {
    { "<leader>sF", "<cmd>Spectre<CR>", desc = "Project Search & Replace" },
    {
      "<leader>sf",
      "<cmd>lua require('spectre').open_file_search()<CR>",
      desc = "File Search and Replace",
      mode = "n",
    },
    {
      "<leader>sw",
      "<cmd>lua require('spectre').open_file_search({select_word=true})<CR>",
      desc = "Search and Replace with word in current file",
      mode = "n",
    },
    {
      "<leader>sW",
      "<cmd>lua require('spectre').open_visual({select_word=true})<CR>",
      desc = "Search and Replace with word in current project",
      mode = "n",
    },
    {
      "<leader>sh",
      "<esc><cmd>lua require('spectre').open_visual()<CR>",
      desc = "Search current highlight",
      mode = "v",
    },
  },
  opts = {
    open_cmd = "noswapfile vnew", -- how the search results window is opened
    live_update = true, -- live preview as you type replacement text
    color_devicons = true, -- use colored devicons if available
    -- add any other spectre options as needed; see :help spectre-setup
  },
  config = function(_, opts)
    require("spectre").setup(opts)
  end,
}
