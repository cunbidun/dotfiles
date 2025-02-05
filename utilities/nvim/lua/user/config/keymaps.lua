local binds = {
  { action = "<cmd>Telescope find_files<cr>", key = "<leader>f", mode = "n" },
  { action = "<cmd>Telescope live_grep<cr>", key = "<leader>t", mode = "n" },
  { action = ":BufferLineCycleNext<CR>", key = "<TAB>", mode = "n" },
  { action = ":BufferLineCyclePrev<CR>", key = "<S-TAB>", mode = "n" },
  { action = ":Bdelete<CR>", key = "<S-x>", mode = "n" },
  { action = "<C-w>h", key = "<C-h>", mode = "n" },
  { action = "<C-w>j", key = "<C-j>", mode = "n" },
  { action = "<C-w>l", key = "<C-l>", mode = "n" },
  { action = "<C-w>k", key = "<C-k>", mode = "n" },
  { action = "<Cmd>Neotree toggle<CR>", key = "<leader>e", mode = "n" },
}

for i, map in ipairs(binds) do
  vim.keymap.set(map.mode, map.key, map.action, map.options)
end
