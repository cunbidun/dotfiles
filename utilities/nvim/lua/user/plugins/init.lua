local plugin_dir = vim.fn.expand("~/.local/share/vim-plugins")

local function get_plugin_path(name)
  local path = plugin_dir .. "/" .. name
  if vim.loop.fs_stat(path) then
    return path
  else
    vim.notify("Plugin path not found: " .. path, vim.log.levels.WARN)
    return nil
  end
end

vim.opt.rtp:prepend(get_plugin_path("lazy.nvim"))

require("lazy").setup({
  { 
    dir = get_plugin_path("vscode.nvim"), 
    lazy = false,
    config= require("user.plugins.vscode").setup() 
  },
  { dir = get_plugin_path("bufdelete.nvim") },
  { dir = get_plugin_path("nvim-autopairs"), config = require("nvim-autopairs").setup({}) },
  { dir = get_plugin_path("nvim-surround"), config = require("nvim-surround").setup({}) },
  {
    dir = get_plugin_path("gitsigns.nvim"),
    event = "BufEnter",
    config = require("user.plugins.gitsigns").setup(),
  },
  {
    dir = get_plugin_path("indent-blankline.nvim"),
    event = "BufEnter",
    config = require("user.plugins.ibl").setup(),
  },
  {
    dir = get_plugin_path("neo-tree.nvim"),
    dependencies = {
      "plenary.nvim",
      "nvim-web-devicons", -- not strictly required, but recommended
      "nui.nvim",
    },
    lazy = false,
    config = require("user.plugins.neo-tree").setup(),
  },
  {
    dir = get_plugin_path("bufferline.nvim"),
    event = "BufEnter",
    config = require("user.plugins.bufferline").setup(),
  },
  {
    dir = get_plugin_path("conform.nvim"),
    event = "BufEnter",
    config = require("user.plugins.conform").setup(),
  },

  {
    dir = get_plugin_path("which-key.nvim"),
    event = "BufEnter",
    config = require("user.plugins.which-key").setup(),
  },
  {
    dir = get_plugin_path("comment.nvim"),
    config = require("user.plugins.comment").setup(),
  },
  {
    dir = get_plugin_path("toggleterm.nvim"),
    event = "BufEnter",
    config = require("user.plugins.comment").setup(),
  },
  {
    dir = get_plugin_path("telescope.nvim"),
    event = "BufEnter",
    config = require("user.plugins.telescope").setup(),
  },
  {
    dir = get_plugin_path("nvim-cmp"),
    event = "BufEnter",
    config = require("user.plugins.cmp").setup(),
  },
  {
    dir = get_plugin_path("nvim-treesitter"),
    event = "BufEnter",
    config = require("user.plugins.treesitter").setup(),
  },
  { dir = get_plugin_path("lualine.nvim"), config = require("user.plugins.lualine").setup() },
})

require("user.plugins.lsp")

