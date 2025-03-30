return {
  "vim-plugins/nvim-autopairs",
  event = "VeryLazy",
  config = function()
    require("nvim-autopairs").setup({})
  end,
}
