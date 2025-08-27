return {
  "vim-plugins/bufferline.nvim",
  config = function()
    require("bufferline").setup({
      options = {
        indicator = {
          style = "underline", -- adds an underline indicator
        },
      },
      highlights = {
        fill = {
          bg = { attribute = 'bg', highlight = 'TabLine' },
        },
        background = {
          fg = { attribute = 'fg', highlight = 'TabLine' },
          sp = { attribute = 'sp', highlight = 'BufferlineFill' },
        },
      },
    })
  end,
}
