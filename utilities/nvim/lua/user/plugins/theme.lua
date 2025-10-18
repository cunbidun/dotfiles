return {
  { 
    "vim-plugins/auto-dark-mode.nvim", 
    opts = {
      fallback = "dark"
    }
  },
  { "vim-plugins/vscode.nvim",         lazy = true },
  { "vim-plugins/nord.nvim",           lazy = true },
  { "vim-plugins/catppuccin-nvim",     lazy = true },
  { 
    "vim-plugins/everforest",          
    lazy = true,
    config = function()
      vim.g.everforest_background = 'hard'
    end
  },
  {
    "vim-plugins/onedarkpro.nvim",
    lazy = true,
    config = function()
      require("onedarkpro").setup({
        -- Available themes: onedark, onelight, onedark_vivid, onedark_dark
        theme = "onedark", -- default theme, will be overridden by theme manager
        styles = {
          types = "NONE",
          methods = "NONE",
          numbers = "NONE",
          strings = "NONE",
          comments = "italic",
          keywords = "bold,italic",
          constants = "NONE",
          functions = "italic",
          operators = "NONE",
          variables = "NONE",
          parameters = "NONE",
          conditionals = "italic",
          virtual_text = "NONE",
        },
      })
    end
  },
}
