{
  "folke/sidekick.nvim",
  event = "VeryLazy",
  dependencies = {
    "folke/snacks.nvim",
  },
  opts = {
    cli = {
      watch = true,
    },
  },
  keys = {
    {
      "<leader>aa",
      function() require("sidekick.cli").toggle({ focus = true }) end,
      desc = "Sidekick: Toggle CLI",
      mode = { "n", "t", "x" },
    },
    {
      "<leader>as",
      function() require("sidekick.cli").select() end,
      desc = "Sidekick: Select CLI",
    },
    {
      "<leader>ap",
      function() require("sidekick.cli").prompt() end,
      desc = "Sidekick: Prompt",
      mode = { "n", "x" },
    },
    {
      "<leader>an",
      function()
        local jumped = require("sidekick").nes_jump_or_apply()
        if not jumped then
          vim.notify("Sidekick: no next edit suggestion", vim.log.levels.INFO, { title = "sidekick.nvim" })
        end
      end,
      desc = "Sidekick: Next Edit Suggestion",
      mode = "n",
    },
  },
  config = function(_, opts)
    require("sidekick").setup(opts)
  end,
}
