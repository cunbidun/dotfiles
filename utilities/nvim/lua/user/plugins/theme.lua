return {
  {
    "vim-plugins/auto-dark-mode.nvim",
    opts = {},
  },
  {
    "vim-plugins/vscode.nvim",
    config = function()
      require("vscode").setup({})
      require("vscode").load()
    end,
  },
}
