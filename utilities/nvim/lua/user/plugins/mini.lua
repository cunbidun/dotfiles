return {
  "vim-plugins/mini.icons",
  event = "VeryLazy",
  config = function()
    require("mini.icons").setup()
  end,
  enabled = not vim.g.vscode
}
