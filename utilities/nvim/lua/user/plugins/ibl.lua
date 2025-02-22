return {
  "vim-plugins/indent-blankline.nvim",
  event = "BufEnter",

  config = function()
    require("ibl").setup({
      exclude = {
        buftypes = { "terminal", "nofile" },
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
      indent = { char = "│" },
      scope = { show_end = false, show_exact_scope = true, show_start = false },
    })
  end,
  enabled = not vim.g.vscode
}
