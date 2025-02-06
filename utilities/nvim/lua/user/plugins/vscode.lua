return {
  "vim-plugins/vscode.nvim",
  config = function()
    require("vscode").setup({})
    require("vscode").load()
  end,
}
