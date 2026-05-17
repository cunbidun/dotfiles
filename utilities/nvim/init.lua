local plugin_root = vim.fn.expand("~/.local/share/vim-plugins")
vim.opt.runtimepath:prepend(plugin_root .. "/lazy.nvim")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.updatetime = 250
vim.opt.laststatus = 3
vim.opt.clipboard = "unnamedplus"
vim.cmd.syntax("enable")

local function with_dir(spec, dir)
  spec.dir = spec.dir or (plugin_root .. "/" .. dir)
  return spec
end

require("lazy").setup({
  with_dir({ "nvim-tree/nvim-web-devicons", lazy = true }, "nvim-web-devicons"),
  with_dir({ "echasnovski/mini.icons", lazy = true, opts = {} }, "mini.icons"),
  with_dir(require("user.plugins.lualine"), "lualine.nvim"),
  with_dir({ "lewis6991/gitsigns.nvim", event = "BufReadPre", opts = {} }, "gitsigns.nvim"),
  with_dir({ "windwp/nvim-autopairs", event = "InsertEnter", opts = {} }, "nvim-autopairs"),
  with_dir({ "numToStr/Comment.nvim", keys = { "gc", "gb" }, opts = {} }, "Comment.nvim"),
  with_dir({ "folke/which-key.nvim", event = "VeryLazy", opts = {} }, "which-key.nvim"),
  with_dir({
    "saghen/blink.cmp",
    event = "InsertEnter",
    opts = {
      keymap = { preset = "super-tab" },
    },
  }, "blink.cmp"),
  with_dir(require("user.plugins.treesitter"), "nvim-treesitter"),
  with_dir({ "stevearc/conform.nvim", event = "BufWritePre" }, "conform.nvim"),
  with_dir({ "Mofiqul/vscode.nvim", lazy = false, priority = 1000 }, "vscode.nvim"),
  with_dir({ "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 }, "catppuccin-nvim"),
  with_dir(require("user.plugins.flash"), "flash.nvim"),

  with_dir(require("user.plugins.aw-awatcher"), "aw-watcher.nvim"),
  with_dir(require("user.plugins.nvim-surround"), "nvim-surround"),
  with_dir(require("user.plugins.snacks"), "snacks.nvim"),
  with_dir(require("user.plugins.sidekick"), "sidekick.nvim"),
  require("user.plugins.multiple-cursors"),
}, {
  install = { missing = false },
  checker = { enabled = false },
  change_detection = { enabled = false, notify = false },
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
})

for _, path in ipairs(vim.fn.glob(plugin_root .. "/nvim-treesitter-grammar-*", false, true)) do
  vim.opt.runtimepath:append(path)
end

require("user.config.lsp")
require("user.config.keymaps")
require("user.config.conform")
require("user.config.reload").setup()

if vim.env.CP_ENV then
  require("user.config.cp")
end

require("user.theme").apply()
require("user.tabufline").setup()
