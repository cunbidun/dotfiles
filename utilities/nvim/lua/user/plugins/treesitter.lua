return {
  "vim-plugins/nvim-treesitter",
  event = "BufEnter",
  config = function()
    require("nvim-treesitter.configs").setup({
      indent = { enable = true },
      -- parser_install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
    })
  end,
  enabled = not vim.g.vscode
}
