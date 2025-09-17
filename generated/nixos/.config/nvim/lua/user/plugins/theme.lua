return {
  { "vim-plugins/auto-dark-mode.nvim", opts = {} },
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
}
