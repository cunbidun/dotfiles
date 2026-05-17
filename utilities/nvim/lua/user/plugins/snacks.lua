return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    image = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    picker = { enabled = true, ui_select = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
  end,
}
