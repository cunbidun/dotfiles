return {
  "vim-plugins/comment.nvim",
  event = "VeryLazy",
  config = function()
    require("Comment").setup({})
  end,
  enabled = not vim.g.vscode
}

