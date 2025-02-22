return {
  "vim-plugins/lspsaga.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter", -- optional
    "nvim-tree/nvim-web-devicons", -- optional
  },
  config = function()
    require("lspsaga").setup({
      ui = {
        code_action = "💡",
      },
    })
  end,
  enabled = not vim.g.vscode
}
