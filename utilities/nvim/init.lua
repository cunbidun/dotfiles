require("user.config")
local plugin_dir = vim.fn.expand("~/.local/share/vim-plugins")
vim.opt.rtp:prepend(plugin_dir .. "/" .. "lazy.nvim")

require("lazy").setup("user.plugins", {
  dev = {
    path = plugin_dir,
    patterns = { "vim-plugins" },
  },
})

if vim.env.CP_ENV then
  require("user.config.cp")
end
