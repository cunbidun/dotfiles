-- Override nvim-tree keymap to use Toggle instead of Focus
return {
  "nvim-tree/nvim-tree.lua",
  opts = {
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")
      api.config.mappings.default_on_attach(bufnr)

      local opts = { buffer = bufnr, silent = true }
      vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
      vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
      vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
      vim.keymap.set("n", "<C-l>", "<C-w>l", opts)
    end,
    update_focused_file = {
      enable = true,
      update_root = true,
    },
    disable_netrw = true,
    hijack_cursor = true,
    renderer = {
      highlight_opened_files = "name",
    },
  },
  keys = function(_, keys)
    -- drop any existing <leader>e mapping
    local filtered = {}
    for _, k in ipairs(keys or {}) do
      if k[1] ~= "<leader>e" then
        table.insert(filtered, k)
      end
    end
    table.insert(filtered, { "<leader>e", "<Cmd>NvimTreeToggle<CR>", desc = "Toggle NvimTree" })
    return filtered
  end,
}
