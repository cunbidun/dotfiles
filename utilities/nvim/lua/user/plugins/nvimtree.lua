-- Override nvim-tree keymap to use Toggle instead of Focus
{
  "nvim-tree/nvim-tree.lua",
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
