local plugin_root = vim.fn.expand("~/.local/share/vim-plugins")
vim.opt.runtimepath:prepend(plugin_root .. "/lazy.nvim")

-- Nix installs plugins as symlinks in plugin_root. lazy.nvim's state scan only
-- counts real directories under root, so coerce links to directories here.
local util = require("lazy.core.util")
local original_ls = util.ls
util.ls = function(path, fn)
  return original_ls(path, function(fname, name, t)
    if path == plugin_root and t == "link" then
      t = "directory"
    end
    return fn(fname, name, t)
  end)
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.cmd.syntax("enable")

require("lazy").setup({
  { "LazyVim/LazyVim", dir = plugin_root .. "/LazyVim", lazy = false, priority = 10000 },
  { import = "lazyvim.plugins" },
  { import = "lazyvim.plugins.extras.coding.blink" },
  { import = "lazyvim.plugins.extras.ai.sidekick" },
  { import = "plugins" },
}, {
  root = plugin_root,
  defaults = {
    lazy = false,
    version = false,
  },
  install = { missing = false },
  checker = { enabled = false },
  change_detection = { enabled = false, notify = false },
  rocks = { enabled = false },
  pkg = { enabled = false },
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
})

-- LazyVim checks rely on lazy's installed flag. Mark Nix-provided plugin dirs as installed.
local ok, cfg = pcall(require, "lazy.core.config")
if ok then
  for _, plugin in pairs(cfg.plugins) do
    if type(plugin.dir) == "string" and vim.fn.isdirectory(plugin.dir) == 1 then
      plugin._ = plugin._ or {}
      plugin._.installed = true
    end
  end
end

for _, path in ipairs(vim.fn.glob(plugin_root .. "/nvim-treesitter-grammar-*", false, true)) do
  vim.opt.runtimepath:append(path)
end

require("user.config.keymaps")
require("user.config.reload").setup()

if vim.env.CP_ENV then
  require("user.config.cp")
end
