return {
  "vim-plugins/bufferline.nvim",
  config = function()
    require("bufferline").setup({
      options = {
        indicator = {
          style = "underline", -- adds an underline indicator
        },
      },
    })
  end,
}
