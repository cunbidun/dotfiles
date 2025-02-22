return {
  "vim-plugins/nvim-tree.lua",
  dependencies = {
    "vim-plugins/nvim-web-devicons", -- not strictly required, but recommended
    "vim-plugins/vscode.nvim",
  },
  config = function()
    require("nvim-tree").setup({
      view = { adaptive_size = true },
      update_focused_file = {
        enable = true,
        update_cwd = true,
        ignore_list = {},
      },
    })
  end,
  enabled = not vim.g.vscode
}
