return {
  "vim-plugins/which-key.nvim",
  config = function()
    require("which-key").setup()
  end,
  enabled = not vim.g.vscode
}
