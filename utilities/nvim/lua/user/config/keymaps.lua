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

  -- terminal navigation
  { action = "<C-\\><C-N><C-w>h", key = "<C-h>", mode = "t" },
  { action = "<C-\\><C-N><C-w>j", key = "<C-j>", mode = "t" },
  { action = "<C-\\><C-N><C-w>l", key = "<C-l>", mode = "t" },
  { action = "<C-\\><C-N><C-w>k", key = "<C-k>", mode = "t" },

  -- LSP
  { action = "<cmd>lua vim.lsp.buf.declaration()<CR>", key = "gD", mode = "n" }, -- Go to definition
  { action = "<cmd>lua vim.lsp.buf.definition()<CR>", key = "gd", mode = "n" }, -- Hover documentation
  { action = "<cmd>lua vim.lsp.buf.hover()<CR>", key = "K", mode = "n" }, -- Go to implementation
  { action = "<cmd>lua vim.lsp.buf.implementation()<CR>", key = "gi", mode = "n" }, -- Signature help
  { action = "<cmd>lua vim.lsp.buf.signature_help()<CR>", key = "<C-k>", mode = "n" }, -- Rename symbol
  { action = "<cmd>lua vim.lsp.buf.rename()<CR>", key = "<leader>rn", mode = "n" }, -- Code actions
  { action = "<cmd>lua vim.lsp.buf.code_action()<CR>", key = "<leader>ca", mode = "n" }, -- List references
  { action = "<cmd>lua vim.lsp.buf.references()<CR>", key = "gr", mode = "n" }, -- Open diagnostic float window
  { action = "<cmd>lua vim.diagnostic.open_float()<CR>", key = "gl", mode = "n" }, -- Go to previous diagnostic
  { action = "<cmd>lua vim.diagnostic.goto_prev()<CR>", key = "[d", mode = "n" }, -- Go to next diagnostic
  { action = "<cmd>lua vim.diagnostic.goto_next()<CR>", key = "]d", mode = "n" },
}

for _, map in ipairs(binds) do
  vim.keymap.set(map.mode, map.key, map.action, map.options)
end
