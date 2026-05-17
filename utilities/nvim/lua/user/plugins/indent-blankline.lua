return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "VeryLazy",
  config = function()
    local hooks = require "ibl.hooks"
    hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, "IblIndent", { link = "NonText" })
      vim.api.nvim_set_hl(0, "IblScope", { link = "Function", nocombine = true })
    end)
    hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
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
      indent = { char = "│", highlight = "IblIndent" },
      scope = {
        enabled = true,
        char = "┃",
        highlight = "IblScope",
        show_end = false,
        show_exact_scope = true,
        show_start = true,
      },
    })
  end,
}
