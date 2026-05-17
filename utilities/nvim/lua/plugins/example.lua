return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "vscode",
    },
  },

  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 10000,
  },

  {
    "nvim-mini/mini.pairs",
    dependencies = { "folke/snacks.nvim" },
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "folke/snacks.nvim" },
  },

  {
    "gitsigns.nvim",
    dependencies = { "folke/snacks.nvim" },
  },

  -- Extra plugins not in LazyVim defaults.
  { "Mofiqul/vscode.nvim", lazy = false, priority = 1000 },
  require("user.plugins.aw-awatcher"),
  require("user.plugins.multiple-cursors"),

  -- Offline-first: never auto-install language servers at runtime.
  {
    "mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      opts.automatic_installation = false
    end,
  },

  -- Offline-first: never auto-install parsers at runtime.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      opts.auto_install = false
      opts.sync_install = false
    end,
  },
}
