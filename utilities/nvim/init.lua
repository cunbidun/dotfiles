if vim.g.vscode then
  require("user.config.settings")
  local binds = {
    { action = "<Cmd>lua require('vscode').action('workbench.action.nextEditorInGroup')<CR>", key = "<TAB>", mode = "n" },
    { action = "<Cmd>lua require('vscode').action('workbench.action.previousEditorInGroup')<CR>", key = "<S-TAB>", mode = "n" },
    { action = "<Cmd>lua require('vscode').action('workbench.action.closeActiveEditor')<CR>", key = "<S-x>", mode = "n" },
    { action = "<Cmd>lua require('vscode').action('workbench.action.toggleSidebarVisibility')<CR>", key = "<leader>b", mode = "n" },
    { action = "<Cmd>lua require('vscode').action('workbench.files.action.showActiveFileInExplorer')<CR>", key = "<leader>e", mode = "n" },
  }
  
  for _, map in ipairs(binds) do
    vim.keymap.set(map.mode, map.key, map.action, map.options)
  end
else
  require("user.config")
end

local plugin_dir = vim.fn.expand("~/.local/share/vim-plugins")
vim.opt.rtp:prepend(plugin_dir .. "/" .. "lazy.nvim")

require("lazy").setup("user.plugins", {
  dev = {
    path = plugin_dir,
    patterns = { "vim-plugins" },
  },
})

-- load extra config if not in vscode
if not vim.g.vscode then
  if vim.env.CP_ENV then
    require("user.config.cp")
  end
end