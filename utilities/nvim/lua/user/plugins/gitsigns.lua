return {
  "vim-plugins/gitsigns.nvim",
  event = "BufEnter",
  config = function()
    require("gitsigns").setup({
      current_line_blame = true,
      current_line_blame_formatter = " <author>, <author_time:%R> – <summary>",
      current_line_blame_formatter_nc = " Uncommitted",
      current_line_blame_opts = { ignore_whitespace = true },
    })
  end,
}
