return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = true },
    bufdelete = { enabled = true },
    indent = { enabled = true },
    image = { enabled = true },
    input = { enabled = true },
    notifier = { enabled = true },
    picker = { enabled = true, ui_select = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    terminal = { enabled = true },
    words = { enabled = true },
  },
  config = function(_, opts)
    local snacks = require("snacks")
    snacks.setup(opts)

    -- Ensure health checks see these UI integrations as active.
    snacks.dashboard.setup()
    snacks.picker.setup()
    snacks.input.enable()
  end,
}
