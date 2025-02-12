return {
  "vim-plugins/vscode.nvim",
  config = function()
    require("vscode").setup({})
    require("vscode").load()
    vim.opt.background = "dark"
    -- vim.opt.background = "light"
  end,
}
