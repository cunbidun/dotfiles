local function set_custom_highlights()
  local highlights = {
    SignColumn = { bg = "NONE" },
    NvimTreeNormal = { bg = "NONE" },
    LineNr = { bg = "NONE" },
    BufferLineFill = { bg = "NONE" },
    ToggleTerm1SignColumn = { bg = "NONE" },
    Normal = { bg = "NONE" },
  }

  for group, colors in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, colors)
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = set_custom_highlights,
})
