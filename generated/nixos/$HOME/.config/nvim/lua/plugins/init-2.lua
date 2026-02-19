return {
  {
  "akinsho/toggleterm.nvim",
  event = "BufEnter",
  config = function()
    require("toggleterm").setup({
      direction = "float",
      float_opts = { border = "single" },
      insert_mappings = true,
      open_mapping = [[<C-\>]],
      shell = "zsh",
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.min(120, math.max(vim.o.columns - 130, 35))
        else
          return 20
        end
      end,
      terminal_mappings = true,
    })
  end,
}
,
  {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {},
    -- stylua: ignore
    keys = {{
        "s",
        mode = {"n"},
        function()
            require("flash").jump()
        end,
        desc = "Flash"
    }, {
        "S",
        mode = {"n"},
        function()
            require("flash").treesitter()
        end,
        desc = "Flash Treesitter"
    }, {
        "r",
        mode = "o",
        function()
            require("flash").remote()
        end,
        desc = "Remote Flash"
    }, {
        "R",
        mode = {"o", "x"},
        function()
            require("flash").treesitter_search()
        end,
        desc = "Treesitter Search"
    }, {
        "<c-s>",
        mode = {"c"},
        function()
            require("flash").toggle()
        end,
        desc = "Toggle Flash Search"
    }},
}
,
  {
  "niklaswimmer/aw-watcher.nvim",
  opts = { -- required, but can be empty table: {}
    -- add any options here
    -- for example:
    aw_server = {
      host = "127.0.0.1",
      port = 5600,
    },
  },
}
,
  {
  "kylechui/nvim-surround",
  event = "VeryLazy",
  config = function()
    require("nvim-surround").setup({})
  end,
}
,
  {
  "famiu/bufdelete.nvim",
  cmd = { "Bdelete", "Bwipeout" },
}
,
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
,
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
,
}
