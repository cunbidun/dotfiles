return {
  {
    "vim-plugins/auto-dark-mode.nvim",
    opts = {},
    enabled = not vim.g.vscode,
  },
  {
    "vim-plugins/vscode.nvim",
    config = function()
      require("vscode").setup({})
      require("vscode").load()
    end,
    enabled = not vim.g.vscode,
  },
}