return {
  {
    "vim-plugins/auto-dark-mode.nvim",
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
  },
  {
    "vim-plugins/vscode.nvim",
    config = function()
      require("vscode").setup({})
      require("vscode").load()
    end,
  },
}
